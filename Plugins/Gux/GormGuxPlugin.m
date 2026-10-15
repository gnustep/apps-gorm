#import <Foundation/Foundation.h>
#import <GormCore/GormCore.h>

#import "GormGuxWrapperLoader.h"

@interface NSMatrix (GSGuxCompatibilityInstall)
+ (void) gormInstallGuxCodingCompatibility;
@end

@interface GormGuxWrapperBuilder : GormWrapperBuilder
@end

@interface GormGuxPlugin : GormPlugin
@end

@implementation GormGuxPlugin
- (void) didLoad
{
  [NSMatrix gormInstallGuxCodingCompatibility];
  [GormWrapperLoaderFactory registerWrapperLoaderClass:
                              [GormGuxWrapperLoader class]];
  [GormWrapperBuilderFactory registerWrapperBuilderClass:
                               [GormGuxWrapperBuilder class]];
  [self registerDocumentTypeName: [GormGuxWrapperLoader fileType]
               humanReadableName: @"GNUstep GUX Interface XML"
                   forExtensions: [NSArray arrayWithObject: @"gux"]];
}
@end
