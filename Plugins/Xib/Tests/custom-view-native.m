/* Run in a fresh process: GSCustomView must not already be initialized. */
#import <AppKit/AppKit.h>
#import <GormCore/GormCustomView.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  @try
    {
  [NSApplication sharedApplication];
  GormCustomView *view = [[GormCustomView alloc]
    initWithFrame: NSMakeRect(12, 34, 56, 78)];
  [view setClassName: @"ExampleView"];
  [view setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
  NSMutableData *data = [NSMutableData data];
  NSArchiver *writer = [[NSArchiver alloc] initForWritingWithMutableData: data];
  [writer encodeClassName: @"GormCustomView" intoClassName: @"GSCustomView"];
  [writer encodeRootObject: [NSArray arrayWithObjects: view, @"sentinel", nil]];
  [writer release];
  NSUnarchiver *reader = [[NSUnarchiver alloc] initForReadingWithData: data];
  [reader decodeClassName: @"GSCustomView" asClassName: @"GormCustomView"];
  NSArray *objects = [reader decodeObject];
  GormCustomView *decoded = [objects objectAtIndex: 0];
  if ([objects count] != 2
      || ![[objects objectAtIndex: 1] isEqual: @"sentinel"]
      || ![[decoded className] isEqual: @"ExampleView"]
      || !NSEqualRects([decoded frame], [view frame])
      || [decoded autoresizingMask] != [view autoresizingMask])
    [NSException raise: @"TestFailure" format: @"Custom view native roundtrip failed"];
  NSLog(@"Custom view native roundtrip passed");
  [reader release];
  [view release];
    }
  @catch (NSException *exception)
    {
      NSLog(@"Native roundtrip failed: %@", exception);
      [pool drain];
      return 1;
    }
  [pool drain];
  return 0;
}
