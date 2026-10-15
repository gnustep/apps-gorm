#import <Foundation/Foundation.h>

@interface GSGuxLoader : NSObject
+ (BOOL) canReadData: (NSData *)data;
- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
@end
