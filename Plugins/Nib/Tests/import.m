/* Regression coverage for the OPENSTEP reader moved from GNUstep GUI. */
#import <GormCore/GormCore.h>
#import <GormCore/GormAbstractDelegate.h>
#import "../GormNibWrapperLoader.h"
#import "../GormOpenStepNibReader.h"
#import "Testing.h"

@interface ImportDelegate : GormAbstractDelegate
@end
@implementation ImportDelegate
- (BOOL) isInTool { return YES; }
@end

int main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  [NSApplication sharedApplication];
  ImportDelegate *delegate = [ImportDelegate new];
  [NSApp setDelegate: delegate];
  NSString *path = [NSString stringWithUTF8String: argv[1]];
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath: path];
  GormDocument *doc = [GormDocument new];
  Class loaderClass = NSClassFromString(@"GormNibWrapperLoader");
  PASS(loaderClass != Nil, "rebuilt Nib plugin is available")
  NSString *pluginPath = [[NSBundle bundleForClass: loaderClass] bundlePath];
  PASS([pluginPath rangeOfString: @"GormCore/GormCore.framework"].location != NSNotFound,
    "importer comes from checkout framework")
  GormNibWrapperLoader *loader = [loaderClass new];
  BOOL expected = argc < 3 || strcmp(argv[2], "roundtrip") == 0;
  [NSClassSwapper setIsInInterfaceBuilder: YES];
  BOOL loaded = [loader loadFileWrapper: wrapper withDocument: doc];
  PASS(loaded == expected, "import succeeds only for valid preferred payloads")
  PASS([NSClassSwapper isInInterfaceBuilder], "import restores previous editor state")
  [NSClassSwapper setIsInInterfaceBuilder: NO];
  if (!expected && argc > 3)
    {
      GormDocument *next = [GormDocument new];
      NSFileWrapper *valid = [[NSFileWrapper alloc] initWithPath:
        [NSString stringWithUTF8String: argv[3]]];
      PASS([loader loadFileWrapper: valid withDocument: next],
        "same loader can import after a failure")
      PASS(![NSClassSwapper isInInterfaceBuilder],
        "import also restores a previous non-editor state")
      [valid release];
    }
  if (loaded)
    {
      NSWindow *window = nil;
      NSButton *button = nil;
      for (id obj in [doc objects])
        if ([obj isKindOfClass: [NSWindow class]]) window = obj;
      PASS(window != nil, "unnamed top-level window is imported")
      for (id obj in [[window contentView] subviews])
        if ([obj isKindOfClass: [NSButton class]]) button = obj;
      PASS([[window title] isEqual: @"OPENSTEP fixture"], "window title survives")
      PASS([[button title] isEqual: @"Run"], "nested button survives")
      PASS(NSEqualRects([button frame], NSMakeRect(12.5,18.25,90.5,24.75)), "fractional geometry survives")
      PASS([[[doc filesOwner] className] isEqual: @"OpenStepTestOwner"], "owner custom class survives")
      GormClassManager *classManager = [doc classManager];
      PASS([classManager isCustomClass: @"OpenStepTestOwner"]
        && [[classManager nonCustomSuperClassOf: @"OpenStepTestOwner"] isEqual: @"NSObject"],
        "owner without companion metadata has an exportable superclass")
      PASS([classManager isCustomClass: @"OpenStepTestObject"]
        && [[classManager nonCustomSuperClassOf: @"OpenStepTestObject"] isEqual: @"NSObject"],
        "custom object without companion metadata has an exportable superclass")
      NSMutableDictionary *links = [NSMutableDictionary dictionary];
      for (id link in [doc connections])
        if ([link isKindOfClass: [NSNibConnector class]] && [link label] != nil)
          [links setObject: link forKey: [link label]];
      id customObject = [[links objectForKey: @"object"] destination];
      PASS([doc containsObject: customObject]
        && [[customObject className] isEqual: @"OpenStepTestObject"],
        "custom object outlet retains its document object and class")
      PASS([[links objectForKey: @"button"] destination] == button
        && [[links objectForKey: @"alias"] destination] == button, "shared outlet identity survives")
      PASS([[links objectForKey: @"button"] source] == [doc filesOwner]
        && [[links objectForKey: @"object"] source] == [doc filesOwner],
        "outlets originate from the document owner")
      PASS([[links objectForKey: @"window"] destination] == window, "window outlet uses instantiated window")
      PASS([[links objectForKey: @"run:"] source] == [button cell]
        || [[links objectForKey: @"run:"] source] == button, "action source survives")
      PASS([[links objectForKey: @"run:"] destination] == [doc filesOwner], "action targets document owner")
      float delay = 0, interval = 0;
      [[button cell] getPeriodicDelay: &delay interval: &interval];
      if (argc < 3)
      PASS(fabs(delay - 0.2) < 0.0001 && fabs(interval - 0.025) < 0.0001,
        "historical periodic timing is restored")
    }
  [loader release]; [wrapper release];
  /* Gorm documents keep editor objects alive until process exit. */
  [pool drain];
  return 0;
}
