#import <Foundation/NSNotification.h>
#import <Foundation/NSProcessInfo.h>
#import <GNUstepGUI/GSNibLoading.h>

#import "AppDelegate.h"

@implementation AppDelegate

- (void) process
{
  [NSClassSwapper setIsInInterfaceBuilder: YES];

  NSLog(@"Processing...");
  
  [NSClassSwapper setIsInInterfaceBuilder: NO];
}

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  NSLog(@"== gormtool");

  NSLog(@"processInfo: %@", [NSProcessInfo processInfo]);
  [self process];
  
  [NSApp terminate: nil];
}

@end
