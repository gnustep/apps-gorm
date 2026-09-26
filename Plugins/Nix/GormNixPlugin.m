#import <Foundation/Foundation.h>
#import <GormCore/GormCore.h>

#import "GormNixWrapperLoader.h"

@interface GormNixWrapperBuilder : GormWrapperBuilder
@end

@interface GormNixPlugin : GormPlugin
@end

@implementation GormNixPlugin
- (void) didLoad
{
  [GormWrapperLoaderFactory registerWrapperLoaderClass:
                              [GormNixWrapperLoader class]];
  [GormWrapperBuilderFactory registerWrapperBuilderClass:
                               [GormNixWrapperBuilder class]];
  [self registerDocumentTypeName: [GormNixWrapperLoader fileType]
               humanReadableName: @"GNUstep Native Interface XML"
                   forExtensions: [NSArray arrayWithObject: @"nix"]];
}
@end
