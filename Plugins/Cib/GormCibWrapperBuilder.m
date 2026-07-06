/* GormCibWrapperBuilder.m
 *
 * Cappuccino CIB wrapper builder.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>

#import "GormCIBModelGenerator.h"
#import "GormCibWrapperBuilder.h"

@implementation GormCibWrapperBuilder

+ (NSString *) fileType
{
  return @"GSCibFileType";
}

- (NSFileWrapper *) buildFileWrapperWithDocument: (GormDocument *)doc
{
  GormCIBModelGenerator *generator = [GormCIBModelGenerator cibWithGormDocument: doc];
  NSData *data = [generator data];
  NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: data];

  return fileWrapper;
}

@end
