/* GormCIBModelGenerator.m
 *
 * Builds a Cappuccino keyed CIB archive from a Gorm document.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>

#import "GormCIBModelGenerator.h"

@interface GormCIBModelGenerator (Private)
- (NSString *) _cappuccinoNameForClassName: (NSString *)className;
- (NSDictionary *) _identifierForObject: (id)obj;
- (NSDictionary *) _encodeValue: (id)value;
- (NSDictionary *) _encodeRecord: (NSDictionary *)record;
- (NSDictionary *) _archiveObject: (id)obj;
- (NSDictionary *) _childArchiveEntriesForObject: (id)obj;
@end

@implementation GormCIBModelGenerator

+ (instancetype) cibWithGormDocument: (GormDocument *)doc
{
  return AUTORELEASE([[self alloc] initWithGormDocument: doc]);
}

- (instancetype) initWithGormDocument: (GormDocument *)doc
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_gormDocument, doc);
      _objectIDs = [[NSMutableDictionary alloc] init];
      _visitedObjects = [[NSMutableSet alloc] init];
      _objects = [[NSMutableArray alloc] init];
      _sourceObjects = [[NSMutableArray alloc] init];
      _parentIDs = [[NSMutableDictionary alloc] init];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_gormDocument);
  DESTROY(_objectIDs);
  DESTROY(_visitedObjects);
  DESTROY(_objects);
  DESTROY(_sourceObjects);
  DESTROY(_parentIDs);
  [super dealloc];
}

- (NSString *) _cappuccinoClassNameForObject: (id)obj
{
  NSString *className = NSStringFromClass([obj class]);
  NSDictionary *classMap = [NSDictionary dictionaryWithObjectsAndKeys:
    @"CPWindow", @"NSWindow",
    @"CPWindow", @"NSPanel",
    @"CPWindow", @"GormNSWindow",
    @"CPWindow", @"GormNSPanel",
    @"CPView", @"NSView",
    @"CPView", @"GormCustomView",
    @"CPButton", @"NSButton",
    @"CPPopUpButton", @"NSPopUpButton",
    @"CPClipView", @"NSClipView",
    @"CPScroller", @"NSScroller",
    @"CPTextField", @"NSTextField",
    @"CPSecureTextField", @"NSSecureTextField",
    @"CPBox", @"NSBox",
    @"CPImageView", @"NSImageView",
    @"CPScrollView", @"NSScrollView",
    @"CPTabView", @"NSTabView",
    @"CPTabViewItem", @"NSTabViewItem",
    @"CPMenu", @"NSMenu",
    @"CPMenuItem", @"NSMenuItem",
    nil];
  NSString *mappedName = [classMap objectForKey: className];

  if (mappedName != nil)
    {
      return mappedName;
    }

  if ([obj isKindOfClass: [GormFilesOwner class]])
    {
      return @"CPObject";
    }
  if ([obj isKindOfClass: [GormFirstResponder class]])
    {
      return @"CPResponder";
    }
  if ([obj isKindOfClass: [GormObjectProxy class]])
    {
      NSString *proxyClassName = [obj className];
      if ([proxyClassName isEqualToString: @"NSApplication"])
	{
	  return @"CPApplication";
	}
      if ([proxyClassName isEqualToString: @"NSFirst"])
	{
	  return @"CPResponder";
	}
      if ([proxyClassName isEqualToString: @"NSOwner"])
	{
	  return @"CPObject";
	}
      return [self _cappuccinoNameForClassName: proxyClassName];
    }

  [NSException raise: NSInvalidArgumentException
              format: @"CIB export does not support class %@", className];
  return nil;
}

- (NSString *) _cappuccinoNameForClassName: (NSString *)className
{
  NSString *name = className;

  if ([name hasPrefix: @"GormNS"])
    {
      name = [name substringFromIndex: 6];
    }

  if ([name hasPrefix: @"CPGormNS"])
    {
      name = [name substringFromIndex: 8];
    }

  if ([name hasPrefix: @"CPNS"])
    {
      name = [name substringFromIndex: 4];
    }

  if ([name hasPrefix: @"NS"])
    {
      name = [name substringFromIndex: 2];
    }

  if ([name hasPrefix: @"CP"])
    {
      return name;
    }

  if ([className hasPrefix: @"NS"] || [className hasPrefix: @"GormNS"])
    return [NSString stringWithFormat: @"CP%@", name];
  return className;
}

- (NSString *) _customClassNameForObject: (id)obj
{
  NSString *name = [_gormDocument nameForObject: obj];
  NSString *customClassName = nil;

  if (name != nil)
    {
      customClassName = [[_gormDocument classManager] customClassForName: name];
    }
  if (customClassName == nil && [obj isKindOfClass: [GormFilesOwner class]])
    {
      customClassName = [obj className];
    }
  if ([customClassName isEqualToString: @"NSOwner"]
      || [customClassName isEqualToString: @"NSFirst"])
    {
      customClassName = nil;
    }
  if ([customClassName isEqualToString: @"NSApplication"])
    customClassName = @"CPApplication";
  else if ([customClassName isEqualToString: @"NSObject"])
    customClassName = @"CPObject";
  return customClassName;
}

/* Reserve the slot before traversing children: references may be cyclic. */
- (NSDictionary *) _identifierForObject: (id)obj
{
  NSValue *key;
  NSDictionary *reference;

  if (obj == nil || [obj isKindOfClass: [GormFirstResponder class]])
    return [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: 0]
                                      forKey: @"CP$UID"];
  key = [NSValue valueWithPointer: obj];
  reference = [_objectIDs objectForKey: key];
  if (reference == nil)
    {
      reference = [NSDictionary dictionaryWithObject:
        [NSNumber numberWithUnsignedInteger: [_objects count]] forKey: @"CP$UID"];
      [_objectIDs setObject: reference forKey: key];
      [_objects addObject: @"$null"];
      [_sourceObjects addObject: obj];
    }
  return reference;
}

/* CPKeyedUnarchiver accepts primitive values inline, but array elements
 * must be UID references. Class records are part of the same object table. */
- (NSDictionary *) _encodeValue: (id)value
{
  NSDictionary *reference;
  NSUInteger index;
  if ([value isKindOfClass: [NSDictionary class]])
    {
      if ([value objectForKey: @"CP$UID"] != nil)
        return value;
      if ([value objectForKey: @"class"] != nil)
        return [self _encodeRecord: value];
      {
        NSMutableDictionary *items = [NSMutableDictionary dictionary];
        NSEnumerator *en = [value keyEnumerator];
        NSString *key;
        while ((key = [en nextObject]) != nil)
          [items setObject: [self _encodeValue: [value objectForKey: key]] forKey: key];
        return [self _encodeRecord: [NSDictionary dictionaryWithObjectsAndKeys:
          @"CPDictionary", @"class", items, @"CP.objects", nil]];
      }
    }
  if ([value isKindOfClass: [NSArray class]])
    {
      NSMutableArray *items = [NSMutableArray array];
      NSEnumerator *en = [value objectEnumerator];
      id item;
      while ((item = [en nextObject]) != nil)
        [items addObject: [self _encodeValue: item]];
      return [self _encodeRecord: [NSDictionary dictionaryWithObjectsAndKeys:
        @"CPArray", @"class", items, @"CP.objects", nil]];
    }
  index = [_objects count];
  reference = [NSDictionary dictionaryWithObject:
    [NSNumber numberWithUnsignedInteger: index] forKey: @"CP$UID"];
  [_objects addObject: value != nil ? value : @"$null"];
  return reference;
}

- (NSDictionary *) _encodeRecord: (NSDictionary *)record
{
  NSString *className = [record objectForKey: @"class"];
  NSMutableDictionary *encoded = [NSMutableDictionary dictionary];
  NSDictionary *reference = [record objectForKey: @"id"];
  NSUInteger index;
  NSEnumerator *en;
  NSString *key;

  if (reference == nil)
    {
      reference = [NSDictionary dictionaryWithObject:
        [NSNumber numberWithUnsignedInteger: [_objects count]] forKey: @"CP$UID"];
      [_objects addObject: @"$null"];
    }
  index = [[reference objectForKey: @"CP$UID"] unsignedIntegerValue];
  [encoded setObject: [NSDictionary dictionaryWithObject:
    [NSNumber numberWithUnsignedInteger: [_objects count]] forKey: @"CP$UID"]
              forKey: @"$class"];
  {
    NSDictionary *superclasses = [NSDictionary dictionaryWithObjectsAndKeys:
      @"CPControl", @"CPButton", @"CPButton", @"CPPopUpButton",
      @"CPControl", @"CPTextField", @"CPTextField", @"CPSecureTextField",
      @"CPControl", @"CPImageView", @"CPControl", @"CPScroller",
      @"CPControl", @"CPTableView", @"CPTableView", @"CPOutlineView",
      @"CPControl", @"CPBrowser", @"CPView", @"CPControl",
      @"CPView", @"CPBox", @"CPView", @"CPScrollView",
      @"CPView", @"CPClipView", @"CPView", @"CPSplitView",
      @"CPView", @"CPTabView", @"CPView", @"_CPCibCustomView",
      @"CPResponder", @"CPView", @"CPValue", @"_CPKeyedArchiverValue",
      @"CPCibConnector", @"CPCibControlConnector",
      @"CPCibConnector", @"CPCibOutletConnector", nil];
    NSMutableArray *hierarchy = [NSMutableArray arrayWithObject: className];
    NSString *ancestor = className;
    while (![ancestor isEqual: @"CPObject"])
      {
        ancestor = [superclasses objectForKey: ancestor];
        if (ancestor == nil)
          ancestor = @"CPObject";
        [hierarchy addObject: ancestor];
      }
    [_objects addObject: [NSDictionary dictionaryWithObjectsAndKeys:
      className, @"$classname", hierarchy, @"$classes", nil]];
  }
  en = [record keyEnumerator];
  while ((key = [en nextObject]) != nil)
    {
      id value = [record objectForKey: key];
      if ([key isEqual: @"class"] || [key isEqual: @"id"]
          || [key isEqual: @"name"] || [key isEqual: @"customClass"])
        continue;
      if (![key isEqual: @"CP.objects"]
          && ([value isKindOfClass: [NSArray class]]
              || [value isKindOfClass: [NSDictionary class]]))
        value = [self _encodeValue: value];
      [encoded setObject: value forKey: key];
    }
  [_objects replaceObjectAtIndex: index withObject: encoded];
  return reference;
}

- (void) _setObject: (id)value forKey: (NSString *)key inDictionary: (NSMutableDictionary *)dict
{
  if (value != nil && key != nil)
    {
      [dict setObject: value forKey: key];
    }
}

- (NSString *) _rectString: (NSRect)rect
{
  return [NSString stringWithFormat: @"{{%.17g, %.17g}, {%.17g, %.17g}}",
    (double)rect.origin.x, (double)rect.origin.y,
    (double)rect.size.width, (double)rect.size.height];
}

- (NSDictionary *) _colorDictionary: (NSColor *)color
{
  NSColor *rgbColor = nil;
  NSArray *components = nil;

  NS_DURING
    {
      rgbColor = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    }
  NS_HANDLER
    {
      rgbColor = nil;
    }
  NS_ENDHANDLER;

  if (rgbColor == nil)
    {
      return nil;
    }

  components = [NSArray arrayWithObjects:
    [NSNumber numberWithDouble: [rgbColor redComponent]],
    [NSNumber numberWithDouble: [rgbColor greenComponent]],
    [NSNumber numberWithDouble: [rgbColor blueComponent]],
    [NSNumber numberWithDouble: [rgbColor alphaComponent]],
    nil];

  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"CPColor", @"class",
    components, @"CPColorComponentsKey",
    nil];
}

- (void) _archiveChild: (id)child ofObject: (id)parent
{
  [_parentIDs setObject: [self _identifierForObject: parent]
                forKey: [NSValue valueWithPointer: child]];
  [self _archiveObject: child];
}

- (NSDictionary *) _childArchiveEntriesForObject: (id)obj
{
  NSMutableDictionary *entries = [NSMutableDictionary dictionary];
  NSMutableArray *children = nil;
  NSEnumerator *en = nil;
  id child = nil;

  if ([obj isKindOfClass: [NSWindow class]])
    {
      child = [obj contentView];
      if (child != nil)
	{
	  [entries setObject: [self _identifierForObject: child]
		      forKey: @"_CPCibWindowTemplateWindowViewKey"];
	  [self _archiveChild: child ofObject: obj];
	}
    }
  else if ([obj isKindOfClass: [NSTabView class]])
    {
      children = [NSMutableArray array];
      en = [[obj tabViewItems] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveChild: child ofObject: obj];
	}
      if ([children count] > 0)
	{
	  [entries setObject: children forKey: @"CPTabViewItemsKey"];
	}
    }
  else if ([obj isKindOfClass: [NSScrollView class]])
    {
      children = [NSMutableArray array];
      child = [obj contentView];
      [entries setObject: [self _identifierForObject: child] forKey: @"CPScrollViewContentView"];
      [children addObject: [self _identifierForObject: child]];
      [self _archiveChild: child ofObject: obj];
      if ([obj hasVerticalScroller])
        {
          child = [obj verticalScroller];
          [entries setObject: [self _identifierForObject: child] forKey: @"CPScrollViewVScroller"];
          [children addObject: [self _identifierForObject: child]];
          [self _archiveChild: child ofObject: obj];
        }
      if ([obj hasHorizontalScroller])
        {
          child = [obj horizontalScroller];
          [entries setObject: [self _identifierForObject: child] forKey: @"CPScrollViewHScroller"];
          [children addObject: [self _identifierForObject: child]];
          [self _archiveChild: child ofObject: obj];
        }
      [entries setObject: children forKey: @"CPViewSubviewsKey"];
    }
  else if ([obj isKindOfClass: [NSClipView class]])
    {
      child = [obj documentView];
      if (child != nil)
        {
          NSDictionary *reference = [self _identifierForObject: child];
          [entries setObject: reference forKey: @"CPScrollViewDocumentView"];
          [entries setObject: [NSArray arrayWithObject: reference] forKey: @"CPViewSubviewsKey"];
          [self _archiveChild: child ofObject: obj];
        }
    }
  else if ([obj isKindOfClass: [NSBox class]])
    {
      child = [obj contentView];
      if (child != nil)
        {
          [entries setObject: [self _identifierForObject: child] forKey: @"CPBoxContentViewKey"];
          [self _archiveChild: child ofObject: obj];
        }
    }
  else if ([obj isKindOfClass: [NSView class]])
    {
      children = [NSMutableArray array];
      en = [[obj subviews] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveChild: child ofObject: obj];
	}
      if ([children count] > 0)
	{
	  [entries setObject: children forKey: @"CPViewSubviewsKey"];
	}
    }
  else if ([obj isKindOfClass: [NSMenu class]])
    {
      children = [NSMutableArray array];
      en = [[obj itemArray] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveChild: child ofObject: obj];
	}
      [entries setObject: children forKey: @"CPMenuItemsKey"];
    }
  else if ([obj isKindOfClass: [NSMenuItem class]])
    {
      child = [obj submenu];
      if (child != nil)
	{
	  [entries setObject: [self _identifierForObject: child]
		      forKey: @"CPMenuItemSubmenuKey"];
	  [self _archiveChild: child ofObject: obj];
	}
    }
  else if ([obj isKindOfClass: [NSTabViewItem class]])
    {
      child = [obj view];
      if (child != nil)
	{
	  [entries setObject: [self _identifierForObject: child]
		      forKey: @"CPTabViewItemViewKey"];
	  [self _archiveChild: child ofObject: obj];
	}
    }

  return entries;
}

- (NSDictionary *) _archiveObject: (id)obj
{
  NSMutableDictionary *dict = nil;
  NSDictionary *identifier = nil;
  NSString *name = nil;
  NSDictionary *children = nil;

  if (obj == nil || [obj isKindOfClass: [GormFirstResponder class]])
    {
      return nil;
    }

  identifier = [self _identifierForObject: obj];
  if ([_visitedObjects containsObject: identifier])
    {
      return nil;
    }
  [_visitedObjects addObject: identifier];

  dict = [NSMutableDictionary dictionary];
  [dict setObject: identifier forKey: @"id"];
  [dict setObject: [self _cappuccinoClassNameForObject: obj] forKey: @"class"];

  name = [_gormDocument nameForObject: obj];
  [self _setObject: name forKey: @"name" inDictionary: dict];
  [self _setObject: [self _customClassNameForObject: obj] forKey: @"customClass" inDictionary: dict];

  if ([obj respondsToSelector: @selector(frame)])
    {
      [dict setObject: [self _rectString: [obj frame]] forKey: @"CPViewFrameKey"];
    }
  if ([obj respondsToSelector: @selector(bounds)])
    {
      [dict setObject: [self _rectString: [obj bounds]] forKey: @"CPViewBoundsKey"];
    }
  if ([obj respondsToSelector: @selector(title)]
      && [obj isKindOfClass: [NSWindow class]] == NO)
    {
      NSString *titleKey = @"CPButtonTitleKey";

      if ([obj isKindOfClass: [NSMenu class]])
	{
	  titleKey = @"CPMenuTitleKey";
	}
      else if ([obj isKindOfClass: [NSMenuItem class]])
	{
	  titleKey = @"CPMenuItemTitleKey";
	}
      else if ([obj isKindOfClass: [NSBox class]])
	{
	  titleKey = @"CPBoxTitleKey";
	}

      [self _setObject: [obj title] forKey: titleKey inDictionary: dict];
    }
  if ([obj respondsToSelector: @selector(stringValue)])
    {
      [self _setObject: [obj stringValue] forKey: @"CPControlValueKey" inDictionary: dict];
    }
  if ([obj isKindOfClass: [NSMenuItem class]])
    [dict setObject: [NSNumber numberWithBool: [obj isEnabled]] forKey: @"CPMenuItemIsEnabledKey"];
  if ([obj respondsToSelector: @selector(isHidden)])
    {
      NSString *hiddenKey = ([obj isKindOfClass: [NSMenuItem class]])
	? @"CPMenuItemIsHiddenKey"
	: @"CPViewIsHiddenKey";

      [dict setObject: [NSNumber numberWithBool: [obj isHidden]] forKey: hiddenKey];
    }
  if ([obj respondsToSelector: @selector(tag)])
    {
      NSString *tagKey = ([obj isKindOfClass: [NSMenuItem class]])
	? @"CPMenuItemTagKey"
	: @"CPViewTagKey";

      [dict setObject: [NSNumber numberWithInteger: [obj tag]] forKey: tagKey];
    }
  if ([obj respondsToSelector: @selector(autoresizingMask)])
    {
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj autoresizingMask]]
	       forKey: @"CPViewAutoresizingMask"];
    }
  if ([obj respondsToSelector: @selector(backgroundColor)])
    {
      [self _setObject: [self _colorDictionary: [obj backgroundColor]]
		forKey: ([obj isKindOfClass: [NSTextField class]]
			 ? @"CPTextFieldBackgroundColorKey"
			 : @"CPViewBackgroundColor")
	  inDictionary: dict];
    }
  if ([obj respondsToSelector: @selector(textColor)])
    [self _setObject: [self _colorDictionary: [obj textColor]]
             forKey: @"$atext-color" inDictionary: dict];
  if ([obj respondsToSelector: @selector(font)]
      && [obj font] != nil)
    {
      NSFont *font = [obj font];
      NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
	@"CPFont", @"class",
	[font fontName], @"CPFontNameKey",
	[NSNumber numberWithDouble: [font pointSize]], @"CPFontSizeKey",
	nil];
      [dict setObject: fontDict forKey: ([obj isKindOfClass: [NSTabView class]]
        ? @"CPTabViewFontKey" : @"$afont")];
    }
  if ([obj respondsToSelector: @selector(image)] && [obj image] != nil)
    {
      NSImage *image = [obj image];
      NSString *imageKey = nil;

      if ([obj isKindOfClass: [NSButton class]])
	{
	  imageKey = @"$aimage";
	}
      else if ([obj isKindOfClass: [NSMenuItem class]])
	{
	  imageKey = @"CPMenuItemImageKey";
	}
      else if ([obj isKindOfClass: [NSImageView class]])
	{
	  imageKey = @"CPControlValueKey";
	}

      if (imageKey != nil && [image name] != nil)
        [dict setObject: [NSDictionary dictionaryWithObjectsAndKeys:
          @"_CPCibCustomResource", @"class", @"CPImage", @"_CPCibCustomResourceClassNameKey",
          [image name], @"_CPCibCustomResourceResourceNameKey",
          [NSDictionary dictionaryWithObject: [NSDictionary dictionaryWithObjectsAndKeys:
            @"_CPKeyedArchiverValue", @"class",
            [NSString stringWithFormat: @"{\"width\":%.17g,\"height\":%.17g}",
              (double)[image size].width, (double)[image size].height], @"CPValueValueKey", nil]
            forKey: @"size"], @"_CPCibCustomResourcePropertiesKey", nil] forKey: imageKey];
      else if (imageKey != nil)
        [NSException raise: NSInvalidArgumentException
                    format: @"CIB export requires a named image resource"];
    }
  if ([obj isKindOfClass: [NSWindow class]])
    {
      [dict setObject: @"_CPCibWindowTemplate" forKey: @"class"];
      [dict setObject: ([self _customClassNameForObject: obj] != nil
        ? [self _customClassNameForObject: obj] : @"CPWindow")
              forKey: @"_CPCibWindowTemplateWindowClassKey"];
      [dict setObject: [self _rectString: [obj contentRectForFrameRect: [obj frame]]]
              forKey: @"_CPCibWindowTemplateWindowRectKey"];
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj styleMask]]
	   forKey: @"_CPCibWindowTempatStyleMaskKey"];
      [dict setObject: [NSString stringWithFormat: @"{%.17g, %.17g}", (double)[obj minSize].width, (double)[obj minSize].height] forKey: @"_CPCibWindowTemplateMinSizeKey"];
      [dict setObject: [NSString stringWithFormat: @"{%.17g, %.17g}", (double)[obj maxSize].width, (double)[obj maxSize].height] forKey: @"_CPCibWindowTemplateMaxSizeKey"];
      [dict setObject: [NSNumber numberWithUnsignedInteger: (15 << 19)]
              forKey: @"_CPCibWindowTemplateWTFlagsKey"];
      [self _setObject: [obj title]
		forKey: @"_CPCibWindowTemplateWindowTitleKey"
	  inDictionary: dict];
    }
  if ([obj isKindOfClass: [NSControl class]])
    {
      [dict setObject: ([obj isEnabled] ? @"normal" : @"disabled") forKey: @"CPViewThemeStateKey"];
      [dict setObject: [NSNumber numberWithUnsignedInteger: NSLeftMouseUpMask] forKey: @"CPControlSendActionOnKey"];
    }
  if ([obj isKindOfClass: [NSTextField class]])
    {
      [dict setObject: [NSNumber numberWithBool: [obj isEditable]] forKey: @"CPTextFieldIsEditableKey"];
      [dict setObject: [NSNumber numberWithBool: [obj isSelectable]] forKey: @"CPTextFieldIsSelectableKey"];
      [dict setObject: [NSNumber numberWithBool: [obj drawsBackground]] forKey: @"CPTextFieldDrawsBackgroundKey"];
      [dict setObject: [NSNumber numberWithInteger: [obj alignment]] forKey: @"CPTextFieldAlignmentKey"];
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] lineBreakMode]] forKey: @"CPTextFieldLineBreakModeKey"];
      [dict setObject: [NSNumber numberWithBool: [[obj cell] wraps]] forKey: @"CPTextFieldWraps"];
    }
  if ([obj isKindOfClass: [NSButton class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [(NSButton *)obj state]] forKey: @"CPControlValueKey"];
      [dict setObject: [NSNumber numberWithBool: [obj allowsMixedState]] forKey: @"CPButtonAllowsMixedStateKey"];
      [dict setObject: [NSNumber numberWithBool: [obj isBordered]] forKey: @"CPButtonIsBorderedKey"];
      [dict setObject: [NSNumber numberWithInteger: [obj bezelStyle]] forKey: @"CPButtonBezelStyleKey"];
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] highlightsBy]]
	   forKey: @"CPButtonHighlightsByKey"];
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] showsStateBy]]
	   forKey: @"CPButtonShowsStateByKey"];
    }
  if ([obj isKindOfClass: [NSMenuItem class]])
    {
      [dict setObject: [NSNumber numberWithBool: [obj isSeparatorItem]] forKey: @"CPMenuItemIsSeparatorKey"];
      [dict setObject: [NSNumber numberWithInteger: [(NSMenuItem *)obj state]] forKey: @"CPMenuItemStateKey"];
      [self _setObject: [obj keyEquivalent]
		forKey: @"CPMenuItemKeyEquivalentKey"
	  inDictionary: dict];
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj keyEquivalentModifierMask]]
	   forKey: @"CPMenuItemKeyEquivalentModifierMaskKey"];
      if ([obj submenu] != nil)
	{
	  [dict setObject: [self _identifierForObject: [obj submenu]]
		   forKey: @"CPMenuItemSubmenuKey"];
	}
    }
  if ([obj isKindOfClass: [NSTabView class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [obj tabViewType]] forKey: @"CPTabViewTypeKey"];
      [dict setObject: [self _identifierForObject: [obj selectedTabViewItem]] forKey: @"CPTabViewSelectedItemKey"];
    }
  if ([obj isKindOfClass: [NSTabViewItem class]])
    {
      [self _setObject: [obj label] forKey: @"CPTabViewItemLabelKey" inDictionary: dict];
    }

  if ([obj isKindOfClass: [GormObjectProxy class]]
      || [obj isKindOfClass: [GormFilesOwner class]])
    {
      [dict setObject: @"_CPCibCustomObject" forKey: @"class"];
      [dict setObject: ([self _customClassNameForObject: obj] != nil
        ? [self _customClassNameForObject: obj] : [self _cappuccinoClassNameForObject: obj])
              forKey: @"_CPCibCustomObjectClassName"];
    }
  else if ([obj isKindOfClass: [NSView class]])
    {
      NSString *custom = [self _customClassNameForObject: obj];
      NSView *parent = [obj superview];
      NSUInteger mask = [obj autoresizingMask];
      NSRect frame = [obj frame];
      if (parent != nil && ![parent isFlipped])
        {
          frame.origin.y = NSHeight([parent bounds]) - NSMaxY(frame);
          mask = (mask & ~(NSViewMinYMargin | NSViewMaxYMargin))
            | ((mask & NSViewMinYMargin) ? NSViewMaxYMargin : 0)
            | ((mask & NSViewMaxYMargin) ? NSViewMinYMargin : 0);
        }
      [dict setObject: [NSNumber numberWithUnsignedInteger: mask] forKey: @"CPViewAutoresizingMask"];
      [dict setObject: [self _rectString: frame] forKey: @"CPViewFrameKey"];
      [dict setObject: [NSNumber numberWithBool: [obj autoresizesSubviews]]
              forKey: @"CPViewAutoresizesSubviews"];
      if (parent != nil && [_objectIDs objectForKey: [NSValue valueWithPointer: parent]] != nil)
        [dict setObject: [self _identifierForObject: parent] forKey: @"CPViewSuperviewKey"];
      if (custom != nil)
        {
          if ([obj isKindOfClass: [GormCustomView class]])
            {
              [dict setObject: @"_CPCibCustomView" forKey: @"class"];
              [dict setObject: custom forKey: @"_CPCibCustomViewClassNameKey"];
            }
          else
            {
              [dict setObject: [dict objectForKey: @"class"]
                      forKey: @"_CPCibClassSwapperOriginalClassNameKey"];
              [dict setObject: custom forKey: @"_CPCibClassSwapperClassNameKey"];
              [dict setObject: @"_CPCibClassSwapper" forKey: @"class"];
            }
        }
    }

  if ([obj isKindOfClass: [NSScrollView class]])
    {
      [dict setObject: [NSNumber numberWithBool: [obj hasVerticalScroller]] forKey: @"CPScrollViewHasVScroller"];
      [dict setObject: [NSNumber numberWithBool: [obj hasHorizontalScroller]] forKey: @"CPScrollViewHasHScroller"];
      [dict setObject: [NSNumber numberWithBool: [obj autohidesScrollers]] forKey: @"CPScrollViewAutohidesScroller"];
      [dict setObject: [NSNumber numberWithInteger: [obj borderType]] forKey: @"CPScrollViewBorderTypeKey"];
      [dict setObject: [NSNumber numberWithDouble: [obj verticalLineScroll]] forKey: @"CPScrollViewVLineScroll"];
      [dict setObject: [NSNumber numberWithDouble: [obj horizontalLineScroll]] forKey: @"CPScrollViewHLineScroll"];
      [dict setObject: [NSNumber numberWithDouble: [obj verticalPageScroll]] forKey: @"CPScrollViewVPageScroll"];
      [dict setObject: [NSNumber numberWithDouble: [obj horizontalPageScroll]] forKey: @"CPScrollViewHPageScroll"];
    }
  if ([obj isKindOfClass: [NSScroller class]])
    {
      [dict setObject: [NSNumber numberWithBool: NSHeight([obj frame]) > NSWidth([obj frame])]
              forKey: @"CPScrollerIsVerticalKey"];
      [dict setObject: [NSNumber numberWithDouble: [obj knobProportion]] forKey: @"CPScrollerKnobProportion"];
      [dict setObject: [NSNumber numberWithDouble: [obj doubleValue]] forKey: @"CPControlValueKey"];
    }
  if ([obj isKindOfClass: [NSPopUpButton class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [obj indexOfSelectedItem]] forKey: @"CPControlValueKey"];
      if ([obj pullsDown])
        [dict setObject: ([obj isEnabled] ? @"pulls-down" : @"disabled+pulls-down") forKey: @"CPViewThemeStateKey"];
      [dict setObject: [self _identifierForObject: [obj menu]] forKey: @"CPResponderMenuKey"];
      [self _archiveChild: [obj menu] ofObject: obj];
    }
  if ([obj isKindOfClass: [NSBox class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [obj boxType]] forKey: @"CPBoxTypeKey"];
      [dict setObject: [NSNumber numberWithInteger: [obj borderType]] forKey: @"CPBoxBorderTypeKey"];
      [dict setObject: [NSNumber numberWithInteger: [obj titlePosition]] forKey: @"CPBoxTitlePositionKey"];
    }
  if ([obj isKindOfClass: [NSImageView class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [obj imageScaling]] forKey: @"$aimage-scaling"];
      [dict setObject: [NSNumber numberWithInteger: [obj imageAlignment]] forKey: @"CPImageViewImageAlignmentKey"];
    }
  children = [self _childArchiveEntriesForObject: obj];
  if ([children count] > 0)
    {
      [dict addEntriesFromDictionary: children];
    }

  [self _encodeRecord: dict];
  return dict;
}

- (NSData *) _data
{
  NSMutableDictionary *root = [NSMutableDictionary dictionary];
  NSMutableDictionary *objectData = [NSMutableDictionary dictionary];
  NSMutableArray *keys = [NSMutableArray array];
  NSMutableArray *parents = [NSMutableArray array];
  NSMutableArray *names = [NSMutableArray array];
  NSMutableArray *namedObjects = [NSMutableArray array];
  NSMutableArray *visible = [NSMutableArray array];
  NSMutableArray *connections = [NSMutableArray array];
  NSEnumerator *en;
  id obj;
  NSDictionary *owner;
  NSDictionary *dataReference;
  NSString *errorString = nil;
  NSData *data;
  NSUInteger i;

  [_objectIDs removeAllObjects];
  [_objects removeAllObjects];
  [_sourceObjects removeAllObjects];
  [_parentIDs removeAllObjects];
  [_visitedObjects removeAllObjects];
  [_objects addObject: @"$null"];
  owner = [self _identifierForObject: [_gormDocument filesOwner]];
  [self _archiveObject: [_gormDocument filesOwner]];
  en = [[_gormDocument topLevelObjects] objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    [self _archiveObject: obj];

  en = [[_gormDocument connections] objectEnumerator];
  while ((obj = [en nextObject]) != nil)
    {
      NSString *className = nil;
      if ([obj isMemberOfClass: [NSNibConnector class]])
        {
          /* Gorm uses plain connectors to record document ownership. */
          NSDictionary *parent = [_objectIDs objectForKey: [NSValue valueWithPointer: [obj destination]]];
          if (parent != nil && [_objectIDs objectForKey: [NSValue valueWithPointer: [obj source]]] != nil)
            [_parentIDs setObject: parent forKey: [NSValue valueWithPointer: [obj source]]];
          continue;
        }
      if ([obj isKindOfClass: [NSNibControlConnector class]])
        className = @"CPCibControlConnector";
      else if ([obj isKindOfClass: [NSNibOutletConnector class]])
        className = @"CPCibOutletConnector";
      else if ([obj isKindOfClass: [GormObjectToEditor class]]
               || [obj isKindOfClass: [GormEditorToParent class]])
        continue;
      else
        [NSException raise: NSInvalidArgumentException
                    format: @"CIB export does not support connector %@", NSStringFromClass([obj class])];
      [self _archiveObject: [obj source]];
      [self _archiveObject: [obj destination]];
      [connections addObject: [self _encodeRecord:
        [NSDictionary dictionaryWithObjectsAndKeys:
          className, @"class",
          [self _identifierForObject: [obj source]], @"_CPCibConnectorSourceKey",
          [self _identifierForObject: [obj destination]], @"_CPCibConnectorDestinationKey",
          [obj label], @"_CPCibConnectorLabelKey", nil]]];
    }

  for (i = 0; i < [_sourceObjects count]; i++)
    {
      id source = [_sourceObjects objectAtIndex: i];
      NSDictionary *reference = [self _identifierForObject: source];
      NSDictionary *parent = owner;
      NSString *name = [_gormDocument nameForObject: source];
      NSDictionary *candidate = [_parentIDs objectForKey: [NSValue valueWithPointer: source]];
      if (candidate != nil)
        parent = candidate;
      [keys addObject: reference];
      [parents addObject: parent];
      if (name != nil)
        {
          [namedObjects addObject: reference];
          [names addObject: name];
        }
      if ([source isKindOfClass: [NSWindow class]]
          && [_gormDocument objectIsVisibleAtLaunch: source])
        [visible addObject: reference];
    }
  [objectData setObject: @"_CPCibObjectData" forKey: @"class"];
  [objectData setObject: owner forKey: @"_CPCibObjectDataFileOwnerKey"];
  [objectData setObject: keys forKey: @"_CPCibObjectDataObjectsKeysKey"];
  [objectData setObject: parents forKey: @"_CPCibObjectDataObjectsValuesKey"];
  [objectData setObject: namedObjects forKey: @"_CPCibObjectDataNamesKeysKey"];
  [objectData setObject: names forKey: @"_CPCibObjectDataNamesValuesKey"];
  [objectData setObject: connections forKey: @"_CPCibObjectDataConnectionsKey"];
  [objectData setObject: [NSDictionary dictionaryWithObjectsAndKeys:
    @"CPSet", @"class", visible, @"CPSetObjectsKey", nil]
                forKey: @"_CPCibObjectDataVisibleWindowsKey"];
  dataReference = [self _encodeRecord: objectData];
  [root setObject: [NSDictionary dictionaryWithObject: dataReference
                  forKey: @"CPCibObjectDataKey"] forKey: @"$top"];
  [root setObject: _objects forKey: @"$objects"];
  [root setObject: @"CPKeyedArchiver" forKey: @"$archiver"];
  [root setObject: @"100000" forKey: @"$version"];
  data = [NSPropertyListSerialization dataFromPropertyList: root
    format: NSPropertyListXMLFormat_v1_0 errorDescription: &errorString];
  if (data == nil)
    {
      NSDebugLog(@"Unable to generate CIB property list: %@", errorString);
      RELEASE(errorString);
    }
  return data;
}

/* A failed export must not turn into a successful empty file. The document
 * itself is never substituted or modified while building this object table. */
- (NSData *) data
{
  NSData *result = nil;
  NS_DURING
    result = [self _data];
  NS_HANDLER
    NSLog(@"CIB export failed: %@", [localException reason]);
  NS_ENDHANDLER;
  return result;
}

- (BOOL) exportCIBDocumentWithName: (NSString *)name
{
  return [[self data] writeToFile: name atomically: YES];
}

@end
