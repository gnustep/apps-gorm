#import <Foundation/NSNotification.h>
#import <Foundation/NSProcessInfo.h>

#import "AppDelegate.h"

@implementation AppDelegate

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  NSLog(@"== gormtool");

  NSLog(@"processInfo: %@", [NSProcessInfo processInfo]);
  
  [NSApp terminate: nil];
}

@end
