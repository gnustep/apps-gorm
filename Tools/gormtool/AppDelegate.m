#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSProcessInfo.h>

#import <GNUstepGUI/GSNibLoading.h>

#import "AppDelegate.h"

@implementation AppDelegate

- (NSDictionary *) buildDictionary
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSArray *keys = [dict allKeys];
  /*
  FOR_IN(NSString*, k, keys)
    {
      
    }
  END_FOR_IN(keys);
  */
  
  return dict;
}

- (void) process
{
  NSDictionary *args = [self buildDictionary];
  [NSClassSwapper setIsInInterfaceBuilder: YES];

  NSLog(@"Processing... %@", args);
  
  [NSClassSwapper setIsInInterfaceBuilder: NO];
}

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  puts("== gormtool");

  NSLog(@"processInfo: %@", [NSProcessInfo processInfo]);
  [self process];
  
  [NSApp terminate: nil];
}

- (void) applicationWillTerminate: (NSNotification *)n
{
  puts("== finished...");
}

@end
