#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSModelLoaderFactory.h>
#import <GNUstepGUI/GSNibLoading.h>
#import <GNUstepGUI/GSNixSerialization.h>
#import <GormCore/GormCore.h>

#import "GormNixWrapperLoader.h"

extern NSString * const GSNixClassSubstitutions;

/* These methods were added with NIX.  Keep the plugin buildable while an
 * older AppKit header is still installed during a staged framework update. */
@interface GSNixSerialization (GormNixMetadata)
+ (NSString *) identifierForObject: (id)object;
+ (NSString *) intendedClassNameForObject: (id)object;
+ (NSString *) designSuperclassNameForObject: (id)object;
+ (NSArray *) preservedConnectionsForObject: (id)object;
@end

static void
GormNixRestoreViewAlpha(NSView *view)
{
  NSEnumerator *enumerator;
  NSView *subview;

  if ([view alphaValue] <= 0.0)
    [view setAlphaValue: 1.0];
  if (([view bounds].size.width <= 0.0 || [view bounds].size.height <= 0.0)
      && [view frame].size.width > 0.0 && [view frame].size.height > 0.0)
    [view setBounds: NSMakeRect(0.0, 0.0,
      [view frame].size.width, [view frame].size.height)];
  if ([view isKindOfClass: [NSPopUpButton class]])
    {
      NSPopUpButton *popup = (NSPopUpButton *)view;
      NSInteger selected = [popup indexOfSelectedItem];
      NSInteger index;

      if (selected < 0)
        {
          for (index = 0; index < [popup numberOfItems]; index++)
            if ([[popup itemAtIndex: index] state] == NSOnState)
              {
                selected = index;
                break;
              }
        }
      if (selected < 0 && [popup numberOfItems] != 0)
        selected = 0;
      if (selected >= 0)
        [popup selectItemAtIndex: selected];
      [popup synchronizeTitleAndSelectedItem];
      [popup setNeedsDisplay: YES];
    }
  enumerator = [[view subviews] objectEnumerator];
  while ((subview = [enumerator nextObject]) != nil)
    GormNixRestoreViewAlpha(subview);
}

@implementation GormNixWrapperLoader

+ (NSString *) fileType
{
  return @"GSNixFileType";
}

- (id) _objectForEndpoint: (id)endpoint
                  objects: (NSDictionary *)objects
                 document: (GormDocument *)doc
{
  NSString *identifier;

  if ([endpoint isKindOfClass: [NSString class]])
    identifier = endpoint;
  else
    identifier = [endpoint objectForKey: @"$ref"];
  if ([identifier isEqualToString: @"owner"])
    return [doc filesOwner];
  if ([identifier isEqualToString: @"application"])
    return NSApp;
  if ([identifier isEqualToString: @"firstResponder"])
    return [doc firstResponder];
  return [objects objectForKey: identifier];
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper
             withDocument: (GormDocument *)doc
{
  NSData *data;
  GSModelLoader *loader;
  NSMutableArray *topLevel = [NSMutableArray array];
  NSDictionary *context;
  NSMutableDictionary *objects = [NSMutableDictionary dictionary];
  GormClassManager *classManager = [doc classManager];
  GormPalettesManager *palettesManager =
    [(id<GormAppDelegate>)[NSApp delegate] palettesManager];
  NSDictionary *substituteClasses = [palettesManager substituteClasses];
  NSMutableDictionary *loadingSubstitutions = [NSMutableDictionary dictionary];
  NSEnumerator *enumerator;
  id object;

  if (![wrapper isRegularFile]
      || ![super loadFileWrapper: wrapper withDocument: doc])
    return NO;

  data = [wrapper regularFileContents];
  loader = [GSModelLoaderFactory modelLoaderForData: data];
  if (loader == nil || ![[[loader class] type] isEqualToString: @"nix"])
    return NO;

  enumerator = [substituteClasses keyEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    {
      NSString *runtimeClass = [substituteClasses objectForKey: object];
      [loadingSubstitutions setObject: object forKey: runtimeClass];
      /* Compatibility with early NIX output that accidentally persisted the
       * editor substitute name itself.  A subsequent save uses the forward
       * palette mapping and writes the runtime AppKit class name. */
      [loadingSubstitutions setObject: object forKey: object];
    }
  /* NSWindow's keyed representation is NSWindowTemplate.  Substitute the
   * Gorm template just as the nib and XIB plugins do so nibInstantiate
   * creates GormNSWindow/GormNSPanel instances.  Besides editor behavior,
   * this makes viewer resources such as GormWindow.tiff resolve from the
   * GormCore bundle rather than AppKit's bundle. */
  [loadingSubstitutions setObject: @"GormWindowTemplate"
                           forKey: @"NSWindowTemplate"];
  context = [NSDictionary dictionaryWithObjectsAndKeys:
    [doc filesOwner], NSNibOwner,
    topLevel, NSNibTopLevelObjects,
    loadingSubstitutions, GSNixClassSubstitutions,
    nil];
  if (![loader loadModelData: data externalNameTable: context withZone: NULL])
    return NO;

  enumerator = [topLevel objectEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    {
      /* Older Gorm objects were created before NSView's alpha ivar existed,
       * so early NIX files captured zero for otherwise visible views. */
      if ([object isKindOfClass: [NSWindow class]])
        GormNixRestoreViewAlpha([(NSWindow *)object contentView]);
      else if ([object isKindOfClass: [NSView class]])
        GormNixRestoreViewAlpha(object);

      /* Older NIX files written before NSWindow.frame was explicit contain
       * only the content-view frame.  Give such windows a usable design-time
       * frame before Gorm creates and fronts their editors. */
      if ([object isKindOfClass: [NSWindow class]]
          && ([(NSWindow *)object frame].size.width <= 1.0
              || [(NSWindow *)object frame].size.height <= 1.0))
        {
          NSView *contentView = [(NSWindow *)object contentView];
          NSRect contentRect = contentView != nil
            ? [contentView frame] : NSMakeRect(100, 100, 480, 320);
          NSRect frameRect = [(NSWindow *)object
            frameRectForContentRect: contentRect];
          [(NSWindow *)object setFrame: frameRect display: NO];
        }
      /* Early NIX writers encoded GSNamedColor as an empty object.  Its
       * catalog metadata cannot be recovered, but the standard window color
       * is the correct compatibility fallback for a window background. */
      if ([object isKindOfClass: [NSWindow class]])
        {
          NSColor *background = [(NSWindow *)object backgroundColor];
          if ([[background colorSpaceName] isEqualToString: NSNamedColorSpace]
              && ([background catalogNameComponent] == nil
                  || [background colorNameComponent] == nil))
            [(NSWindow *)object setBackgroundColor:
              [NSColor windowBackgroundColor]];
        }
      [doc attachObject: object toParent: nil];
      /* GSModelLoader follows nib ownership rules for top-level objects. */
      [object release];
    }

  enumerator = [[[doc nameTable] allValues] objectEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    {
      NSString *identifier = [GSNixSerialization identifierForObject: object];
      NSString *customClass =
        [GSNixSerialization intendedClassNameForObject: object];
      NSString *superclass =
        [GSNixSerialization designSuperclassNameForObject: object];
      NSString *name = [doc nameForObject: object];

      if (identifier != nil)
        [objects setObject: object forKey: identifier];
      if (customClass != nil && superclass != nil
          && ![customClass isEqualToString: superclass]
          && ![customClass isEqualToString: NSStringFromClass([object class])])
        {
          [classManager addClassNamed: customClass
                  withSuperClassNamed: superclass
                          withActions: nil
                          withOutlets: nil
                             isCustom: YES];
          if (name != nil)
            [classManager setCustomClass: customClass forName: name];
        }
    }

  enumerator = [[[doc nameTable] allValues] objectEnumerator];
  while ((object = [enumerator nextObject]) != nil)
    {
      NSEnumerator *connections =
        [[GSNixSerialization preservedConnectionsForObject: object]
          objectEnumerator];
      NSDictionary *connection;

      while ((connection = [connections nextObject]) != nil)
        {
          NSString *kind = [connection objectForKey: @"kind"];
          NSNibConnector *connector;
          id source = [self _objectForEndpoint:
            [connection objectForKey: @"source"] objects: objects document: doc];
          id destination = [self _objectForEndpoint:
            [connection objectForKey: @"destination"] objects: objects document: doc];

          if ([kind isEqualToString: @"action"])
            connector = [[NSNibControlConnector alloc] init];
          else if ([kind isEqualToString: @"outlet"])
            connector = [[NSNibOutletConnector alloc] init];
          else
            continue;
          if (source == nil || destination == nil)
            {
              [connector release];
              continue;
            }
          [connector setSource: source];
          [connector setDestination: destination];
          [connector setLabel: [connection objectForKey: @"label"]];
          if ([kind isEqualToString: @"action"])
            [classManager addAction: [connector label] forObject: destination];
          else
            [classManager addOutlet: [connector label] forObject: source];
          [doc addConnector: connector];
          [connector release];
        }
    }

  [doc updateChangeCount: NSChangeCleared];
  return YES;
}

@end
