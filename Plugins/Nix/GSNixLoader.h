#import <Foundation/Foundation.h>

@interface GSNixLoader : NSObject
+ (BOOL) canReadData: (NSData *)data;
- (BOOL) loadModelData: (NSData *)data
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
@end
