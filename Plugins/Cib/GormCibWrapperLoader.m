/* GormCibWrapperLoader.m
 *
 * Export-only loader stub for Cappuccino CIB files.
 */

#include <Foundation/Foundation.h>

#include <GormCore/GormCore.h>

#include "GormCibWrapperLoader.h"

@implementation GormCibWrapperLoader
+ (NSString *) fileType
{
  return @"GSCibFileType";
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *)doc
{
  NSLog(@"Cappuccino CIB import is not implemented");
  return NO;
}
@end
