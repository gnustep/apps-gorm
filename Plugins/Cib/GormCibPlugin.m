/* GormCibPlugin.m
 *
 * Cappuccino CIB export plugin for Gorm.
 */

#include <Foundation/Foundation.h>

#include <GormCore/GormCore.h>

#include "GormCibWrapperBuilder.h"
#include "GormCibWrapperLoader.h"

@interface GormCibPlugin : GormPlugin
@end

@implementation GormCibPlugin
- (void) didLoad
{
  [GormWrapperLoaderFactory registerWrapperLoaderClass:
			      NSClassFromString(@"GormCibWrapperLoader")];
  [GormWrapperBuilderFactory registerWrapperBuilderClass:
			       [GormCibWrapperBuilder class]];
  [self registerDocumentTypeName: [GormCibWrapperLoader fileType]
	      humanReadableName: @"Cappuccino CIB"
		  forExtensions: [NSArray arrayWithObjects: @"cib", nil]];
}
@end
