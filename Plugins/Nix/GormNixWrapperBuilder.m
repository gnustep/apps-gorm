#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSNixSerialization.h>
#import <GormCore/GormCore.h>

/* Added by the NIX serialization API.  This declaration also permits staged
 * builds where the newly built AppKit has not yet installed its headers. */
@interface GSNixSerialization (GormNixWriting)
+ (void) setIntendedClassName: (NSString *)className
         designSuperclassName: (NSString *)superclassName
                    forObject: (id)object;
+ (NSData *) dataWithTopLevelObjects: (NSArray *)topLevelObjects
                       keyValuePairs: (NSDictionary *)keyValuePairs
                        excludedKeys: (NSDictionary *)excludedKeys
                         identifiers: (NSMapTable *)identifiers
                  classNameMappings: (NSDictionary *)classNameMappings
                         connections: (NSArray *)connections
                    errorDescription: (NSString **)errorDescription;
@end

@interface GormNixWrapperBuilder : GormWrapperBuilder
@end

@implementation GormNixWrapperBuilder

+ (NSString *) fileType
{
  return @"GSNixFileType";
}

- (NSFileWrapper *) buildFileWrapperWithDocument: (GormDocument *)doc
{
  NSMutableArray *connections = [NSMutableArray array];
  NSEnumerator *enumerator = [[doc connections] objectEnumerator];
  NSNibConnector *connector;
  id object;
  NSString *error = nil;
  NSData *data;
  GormPalettesManager *palettesManager =
    [(id<GormAppDelegate>)[NSApp delegate] palettesManager];
  NSDictionary *substituteClasses = [palettesManager substituteClasses];
  GormClassManager *classManager = [doc classManager];

  while ((connector = [enumerator nextObject]) != nil)
    {
      id source = [connector source];
      id destination = [connector destination];
      NSString *kind = nil;

      if ([connector isKindOfClass: [NSNibControlConnector class]])
        kind = @"action";
      else if ([connector isKindOfClass: [NSNibOutletConnector class]])
        kind = @"outlet";
      else
        continue;

      if (source == [doc filesOwner])
        source = @"owner";
      else if (source == [doc firstResponder])
        source = @"firstResponder";
      else if (source == NSApp)
        source = @"application";
      if (destination == [doc filesOwner])
        destination = @"owner";
      else if (destination == [doc firstResponder])
        destination = @"firstResponder";
      else if (destination == NSApp)
        destination = @"application";

      [connections addObject: [NSDictionary dictionaryWithObjectsAndKeys:
        kind, @"kind", source, @"source", destination, @"destination",
        [connector label], @"label", nil]];
    }

  /* Custom class metadata is object-specific. Palette substitutions are
   * passed to the encoder below so they apply to every traversed object,
   * including cells and nested menu items absent from Gorm's name table. */
  enumerator = [[[doc nameTable] allValues] objectEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    {
      NSString *customClass = [classManager customClassForObject: object];

      if (customClass != nil)
        {
          NSString *superclass =
            [classManager nonCustomSuperClassOf: customClass];
          [GSNixSerialization setIntendedClassName: customClass
                               designSuperclassName: superclass
                                          forObject: object];
        }
    }

  data = [GSNixSerialization
    dataWithTopLevelObjects: [[doc topLevelObjects] allObjects]
    keyValuePairs: nil
    excludedKeys: nil
    identifiers: nil
    classNameMappings: substituteClasses
    connections: connections
    errorDescription: &error];
  if (data == nil)
    {
      NSLog(@"Could not generate NIX data: %@", error);
      [error release];
      return nil;
    }

  return [[NSFileWrapper alloc] initRegularFileWithContents: data];
}

@end
