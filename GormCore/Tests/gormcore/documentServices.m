/* Regression coverage for document services and host policy isolation. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>

@interface DocumentPolicy : NSObject <GormDocumentPolicy>
{
@public
  BOOL allow;
  NSUInteger decisions;
}
@end
@implementation DocumentPolicy
- (BOOL) shouldUpgradeOlderArchive { decisions++; return allow; }
- (BOOL) shouldLoadNewerArchive { decisions++; return allow; }
- (BOOL) shouldBreakConnectionsForClassNamed: (NSString *)name
{ decisions++; return allow; }
- (BOOL) shouldRenameConnectionsForClassNamed: (NSString *)name
                                toClassName: (NSString *)newName
{ decisions++; return allow; }
- (BOOL) shouldBreakConnectionsModifyingLabel: (NSString *)name
                                    isAction: (BOOL)action prompted: (BOOL)prompted
{ decisions++; return allow; }
- (BOOL) shouldBreakConnectionsReparsingClass: (NSString *)name
{ decisions++; return allow; }
- (void) couldNotParseClassAtPath: (NSString *)path {}
- (void) exceptionWhileParsingClass: (NSException *)exception {}
- (void) exceptionWhileLoadingModel: (NSString *)message {}
- (id) palettesManager { return nil; }
@end

static int builderMode = 0;
@interface ServiceBuilder : GormWrapperBuilder
@end
@implementation ServiceBuilder
+ (NSString *) fileType { return @"GormServiceTest"; }
- (NSFileWrapper *) buildFileWrapperWithDocument: (GormDocument *)doc
{
  if (builderMode == 1) return nil;
  if (builderMode == 2)
    [NSException raise: @"TestBuilderFailure" format: @"Expected builder failure"];
  return AUTORELEASE([[NSFileWrapper alloc] initRegularFileWithContents:
    [@"document" dataUsingEncoding: NSUTF8StringEncoding]]);
}
@end

@interface ServiceLoader : GormWrapperLoader
@end
@implementation ServiceLoader
+ (NSString *) fileType { return @"GormServiceTest"; }
- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper
          withDocument: (GormDocument *)doc
{
  NSString *text = AUTORELEASE([[NSString alloc]
    initWithData: [wrapper regularFileContents] encoding: NSUTF8StringEncoding]);
  if ([text isEqual: @"throw"])
    [NSException raise: @"TestLoaderFailure" format: @"Expected loader failure"];
  return [text isEqual: @"document"];
}
@end

@interface ServiceDocument : GormDocument
{
@public
  BOOL editorsActive;
}
- (void) markOlderArchive;
@end
@implementation ServiceDocument
- (void) markOlderArchive { isOlderArchive = YES; }
- (void) deactivateEditors { editorsActive = NO; }
- (void) reactivateEditors { editorsActive = YES; }
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  START_SET("Document services")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    SKIP("A graphical GNUstep backend is required (run under Xvfb)")
  NS_ENDHANDLER

  DocumentPolicy *reject = [DocumentPolicy new];
  DocumentPolicy *accept = [DocumentPolicy new];
  accept->allow = YES;
  ServiceDocument *first = [[ServiceDocument alloc] initWithDocumentPolicy: reject];
  GormDocument *second = [[GormDocument alloc] initWithDocumentPolicy: accept];
  NSMethodSignature *signature = [first methodSignatureForSelector:
    @selector(outlineView:writeItems:toPasteboard:)];
  PASS([[NSString stringWithUTF8String: [signature methodReturnType]]
         isEqualToString: [NSString stringWithUTF8String: @encode(BOOL)]],
       "the metadata drag callback has the BOOL return type required by AppKit")
  PASS([(id<NSOutlineViewDataSource>)first outlineView: nil
          writeItems: [NSArray arrayWithObject: @"metadata"]
        toPasteboard: nil] == NO,
       "the metadata data source refuses unsupported drag exports")
  [NSApp setDelegate: reject];
  NSObject *source = [NSObject new];
  NSObject *target = [NSObject new];
  NSNibOutletConnector *connection = [NSNibOutletConnector new];
  [connection setSource: source];
  [connection setDestination: target];
  [connection setLabel: @"target"];
  [first addConnector: connection];
  [second addConnector: connection];
  PASS(![first removeConnectionsForClassNamed: @"NSObject"] &&
       [[first connections] containsObject: connection],
       "a rejecting document policy preserves connector identity")
  PASS([second removeConnectionsForClassNamed: @"NSObject"] &&
       ![[second connections] containsObject: connection],
       "another document uses its own policy despite the global delegate")
  PASS(reject->decisions == 1 && accept->decisions == 1,
       "decisions are isolated per document")
  [second setDocumentPolicy: nil];
  PASS([second documentPolicy] == reject &&
       ![second removeConnectionsForClassNamed: @"NSObject"],
       "nil policy preserves legacy application-delegate behavior")
  [second setDocumentPolicy: accept];
  [NSApp setDelegate: nil];

  [GormWrapperBuilderFactory registerWrapperBuilderClass: [ServiceBuilder class]];
  [GormWrapperLoaderFactory registerWrapperLoaderClass: [ServiceLoader class]];
  NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:
    [[NSProcessInfo processInfo] globallyUniqueString]];
  NSError *error = nil;
  [first setDocumentPolicy: accept];
  [first markOlderArchive];
  builderMode = 2;
  PASS(![GormDocumentIO writeDocument: first toFile: path
         ofType: @"GormServiceTest" error: &error] && error != nil && first->editorsActive,
       "builder exceptions become errors and reactivate editors")
  volatile BOOL raised = NO;
  NS_DURING
    [first fileWrapperRepresentationOfType: @"GormServiceTest"];
  NS_HANDLER
    raised = [[localException name] isEqual: @"TestBuilderFailure"];
  NS_ENDHANDLER;
  PASS(raised && first->editorsActive,
       "direct serialization preserves the exception after restoring editors")
  NSUInteger before = accept->decisions;
  builderMode = 1;
  error = nil;
  PASS(![GormDocumentIO writeDocument: first toFile: path
         ofType: @"GormServiceTest" error: &error] && error != nil && first->editorsActive,
       "nil builder output reports failure and reactivates editors")
  PASS(accept->decisions == before + 1,
       "failed serialization restores the pending archive upgrade decision")
  builderMode = 0;
  PASS([GormDocumentIO writeDocument: first toFile: path
         ofType: @"GormServiceTest" error: &error] && error == nil,
       "a failed save can be retried successfully and clears the error")
  NSUInteger count = [[[NSDocumentController sharedDocumentController] documents] count];
  GormDocument *loaded = [GormDocumentIO readDocumentFromFile: path
    ofType: @"GormServiceTest" policy: reject error: &error];
  PASS(loaded != nil && [loaded documentPolicy] == reject && error == nil,
       "loading returns a document with the supplied policy")
  PASS([[[NSDocumentController sharedDocumentController] documents] count] == count,
       "file operations leave document registration to the host")
  [@"throw" writeToFile: path atomically: YES encoding: NSUTF8StringEncoding error: NULL];
  PASS([GormDocumentIO readDocumentFromFile: path ofType: @"GormServiceTest"
         policy: reject error: &error] == nil && error != nil,
       "loader exceptions return errors without document-controller dialogs")
  [@"corrupt" writeToFile: path atomically: YES encoding: NSUTF8StringEncoding error: NULL];
  PASS([GormDocumentIO readDocumentFromFile: path ofType: @"GormServiceTest"
         policy: reject error: &error] == nil && error != nil,
       "a rejected payload returns an error")
  PASS(![GormDocumentIO writeDocument: first toFile: path ofType: nil error: &error]
       && error != nil, "missing file types fail with an error")
  [[NSFileManager defaultManager] removeItemAtPath: path error: NULL];
  PASS([GormDocumentIO readDocumentFromFile: path ofType: @"GormServiceTest"
         policy: reject error: &error] == nil && error != nil,
       "missing input returns an error without a modal dialog")
  [first release];
  [second release];
  [connection release];
  [source release];
  [target release];
  [loaded setDocumentPolicy: nil];
  [reject release];
  [accept release];
  END_SET("Document services")
  [pool drain];
  return 0;
}
