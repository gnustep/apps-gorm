/* The compatibility translator must reject incomplete or unsupported graphs
 * before any application objects can be instantiated. */
#import <Foundation/Foundation.h>
#import "../GormOpenStepNibReader.h"
#import "Testing.h"

int main(int argc, char **argv)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSData *data = [NSData dataWithContentsOfFile:
    [NSString stringWithUTF8String: argv[1]]];
  NSUInteger i;
  if (argc > 2)
    {
      BOOL rejected = NO;
      NS_DURING
        GormOpenStepNibKeyedData(data);
      NS_HANDLER
        rejected = [[localException reason] rangeOfString: @"version 999"].location != NSNotFound;
      NS_ENDHANDLER;
      PASS(rejected, "unsupported class version fails with a useful diagnostic")
    }
  else
    {
      PASS(GormOpenStepNibIsTypedStream(data), "recognizes generated typed stream")
      PASS(GormOpenStepNibKeyedData(data) != nil, "complete graph translates")
      for (i = 0; i < [data length]; i++)
        {
          BOOL rejected = NO;
          NSData *shortData = [data subdataWithRange: NSMakeRange(0, i)];
          if (i < 13)
            PASS(!GormOpenStepNibIsTypedStream(shortData), "short signature rejected")
          NS_DURING
            GormOpenStepNibKeyedData(shortData);
          NS_HANDLER
            rejected = YES;
          NS_ENDHANDLER;
          PASS(rejected, "truncated archive rejected")
        }
    }
  [pool drain];
  return 0;
}
