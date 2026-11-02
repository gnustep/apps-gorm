/* Regression for custom-object proxies exported through the Gorm builder.
 * This deliberately avoids NSApplication so archive checks need no display. */
#import <GormCore/GormCore.h>
#import "Testing.h"

@interface GormGormWrapperBuilder : GormWrapperBuilder
- (void) _replaceObjectsWithTemplates: (NSArchiver *)archiver;
@end

/* Only the document queries used by template selection are needed here. */
@interface ProxyDocument : NSObject
{
  NSDictionary *objects;
}
- (id) initWithProxy: (id)proxy;
@end
@implementation ProxyDocument
- (id) initWithProxy: (id)proxy
{
  self = [super init];
  if (self != nil)
    objects = [[NSDictionary alloc] initWithObjectsAndKeys: proxy, @"controller", nil];
  return self;
}
- (id) nameTable { return objects; }
- (id) objectForName: (NSString *)name { return [objects objectForKey: name]; }
- (id) classManager { return self; }
- (NSString *) customClassForName: (NSString *)name { return @"ProxyRuntimeObject"; }
- (NSString *) nonCustomSuperClassOf: (NSString *)name { return @"NSObject"; }
- (void) dealloc { [objects release]; [super dealloc]; }
@end

@interface ProxyBuilder : GormGormWrapperBuilder
- (void) setTestDocument: (id)doc;
@end
@implementation ProxyBuilder
- (void) setTestDocument: (id)doc { document = doc; }
@end

@interface ProxyRuntimeObject : NSObject
@end
@implementation ProxyRuntimeObject
@end

int main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSString *path = [NSString stringWithUTF8String: argv[2]];
  if (strcmp(argv[1], "write") == 0)
    {
      GormObjectProxy *proxy = [[GormObjectProxy alloc]
        initWithClassName: @"ProxyRuntimeObject"];
      ProxyDocument *doc = [[ProxyDocument alloc] initWithProxy: proxy];
      ProxyBuilder *builder = [ProxyBuilder new];
      NSMutableData *data = [NSMutableData data];
      NSArchiver *archiver = [[NSArchiver alloc] initForWritingWithMutableData: data];
      [builder setTestDocument: doc];
      [archiver encodeClassName: @"GormObjectProxy" intoClassName: @"GSNibItem"];
      [builder _replaceObjectsWithTemplates: archiver];
      [archiver encodeRootObject: [NSArray arrayWithObjects: proxy, proxy, @"tail", nil]];
      PASS([data writeToFile: path atomically: YES], "custom proxy archive is written")
      [archiver release]; [builder release]; [doc release]; [proxy release];
    }
  else
    {
      BOOL editor = strcmp(argv[1], "editor") == 0;
      NSUnarchiver *unarchiver = [[NSUnarchiver alloc]
        initForReadingWithData: [NSData dataWithContentsOfFile: path]];
      if (editor)
        [unarchiver decodeClassName: @"GSNibItem" asClassName: @"GormObjectProxy"];
      [GSClassSwapper setIsInInterfaceBuilder: editor];
      NSArray *objects = [unarchiver decodeObject];
      id proxy = [objects objectAtIndex: 0];
      PASS([objects count] == 3 && [[objects objectAtIndex: 2] isEqual: @"tail"],
        "proxy payload does not corrupt subsequent archive fields")
      PASS(proxy == [objects objectAtIndex: 1], "shared proxy identity survives")
      if (editor)
        {
          PASS([proxy isKindOfClass: [GormObjectProxy class]]
            && [[proxy className] isEqual: @"ProxyRuntimeObject"],
            "editor restores the custom object proxy and class name")
        }
      else
        {
          PASS([proxy isKindOfClass: [ProxyRuntimeObject class]],
            "runtime instantiates the custom class")
        }
      [unarchiver release];
    }
  [pool drain];
  return 0;
}
