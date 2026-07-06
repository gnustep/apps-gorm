/* GormCIBModelGenerator.m
 *
 * Builds a Cappuccino-oriented CIB property-list model from a Gorm document.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>

#import "GormCIBModelGenerator.h"

@interface GormCIBModelGenerator (Private)
- (NSString *) _cappuccinoNameForClassName: (NSString *)className;
- (NSString *) _cappuccinoIdentifierForName: (NSString *)name;
- (NSString *) _identifierForObject: (id)obj;
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
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_gormDocument);
  DESTROY(_objectIDs);
  DESTROY(_visitedObjects);
  DESTROY(_objects);
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
    @"CPButton", @"NSPopUpButton",
    @"CPTextField", @"NSTextField",
    @"CPTextField", @"NSSecureTextField",
    @"CPTextView", @"NSTextView",
    @"CPBox", @"NSBox",
    @"CPImageView", @"NSImageView",
    @"CPScrollView", @"NSScrollView",
    @"CPSplitView", @"NSSplitView",
    @"CPTabView", @"NSTabView",
    @"CPTabViewItem", @"NSTabViewItem",
    @"CPTableView", @"NSTableView",
    @"CPTableColumn", @"NSTableColumn",
    @"CPOutlineView", @"NSOutlineView",
    @"CPBrowser", @"NSBrowser",
    @"CPMenu", @"NSMenu",
    @"CPMenuItem", @"NSMenuItem",
    @"CPColor", @"NSColor",
    @"CPFont", @"NSFont",
    @"CPImage", @"NSImage",
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

  return [self _cappuccinoNameForClassName: className];
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

  return [NSString stringWithFormat: @"CP%@", name];
}

- (NSString *) _cappuccinoIdentifierForName: (NSString *)name
{
  NSString *baseName = name;
  NSString *cappuccinoName = nil;
  NSMutableString *identifier = [NSMutableString string];
  NSUInteger length = 0;
  NSUInteger i = 0;

  if ([baseName hasSuffix: @")"])
    {
      NSRange openParenRange = [baseName rangeOfString: @"("
					       options: NSBackwardsSearch];

      if (openParenRange.location != NSNotFound)
	{
	  NSString *suffix = [baseName substringWithRange:
					 NSMakeRange(openParenRange.location + 1,
						     [baseName length] - openParenRange.location - 2)];
	  BOOL numericSuffix = ([suffix length] > 0);

	  for (i = 0; i < [suffix length]; i++)
	    {
	      unichar c = [suffix characterAtIndex: i];

	      if (c < '0' || c > '9')
		{
		  numericSuffix = NO;
		  break;
		}
	    }

	  if (numericSuffix == YES)
	    {
	      baseName = [baseName substringToIndex: openParenRange.location];
	    }
	}
    }

  cappuccinoName = [self _cappuccinoNameForClassName: baseName];
  length = [cappuccinoName length];

  for (i = 0; i < length; i++)
    {
      unichar c = [cappuccinoName characterAtIndex: i];

      if ((c >= 'a' && c <= 'z')
	  || (c >= 'A' && c <= 'Z')
	  || (c >= '0' && c <= '9')
	  || c == '_')
	{
	  [identifier appendFormat: @"%C", c];
	}
    }

  if ([identifier length] == 0)
    {
      return @"CPObject";
    }

  return identifier;
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
  return customClassName;
}

- (NSString *) _identifierForObject: (id)obj
{
  NSString *key;
  NSString *identifier;
  NSString *name;

  if (obj == nil)
    {
      return nil;
    }

  key = [NSString stringWithFormat: @"%p", obj];
  identifier = [_objectIDs objectForKey: key];
  if (identifier != nil)
    {
      return identifier;
    }

  if ([obj isKindOfClass: [GormFilesOwner class]])
    {
      identifier = @"CPOwner";
    }
  else if ([obj isKindOfClass: [GormFirstResponder class]])
    {
      identifier = @"CPFirstResponder";
    }
  else
    {
      name = [_gormDocument nameForObject: obj];
      if (name == nil)
	{
	  name = [NSString stringWithFormat: @"%@", key];
	}
      identifier = [self _cappuccinoIdentifierForName: name];
    }

  [_objectIDs setObject: identifier forKey: key];
  return identifier;
}

- (void) _setObject: (id)value forKey: (NSString *)key inDictionary: (NSMutableDictionary *)dict
{
  if (value != nil && key != nil)
    {
      [dict setObject: value forKey: key];
    }
}

- (NSDictionary *) _rectDictionary: (NSRect)rect
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithDouble: rect.origin.x], @"x",
    [NSNumber numberWithDouble: rect.origin.y], @"y",
    [NSNumber numberWithDouble: rect.size.width], @"width",
    [NSNumber numberWithDouble: rect.size.height], @"height",
    nil];
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
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSTabView class]])
    {
      children = [NSMutableArray array];
      en = [[obj tabViewItems] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
      if ([children count] > 0)
	{
	  [entries setObject: children forKey: @"CPTabViewItemsKey"];
	}
    }
  else if ([obj isKindOfClass: [NSScrollView class]])
    {
      child = [obj documentView];
      if (child != nil)
	{
	  [entries setObject: [self _identifierForObject: child]
		      forKey: @"CPScrollViewContentView"];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSTableView class]])
    {
      children = [NSMutableArray array];
      en = [[obj tableColumns] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
      if ([children count] > 0)
	{
	  [entries setObject: children forKey: @"CPTableViewTableColumnsKey"];
	}
    }
  else if ([obj isKindOfClass: [NSView class]])
    {
      children = [NSMutableArray array];
      en = [[obj subviews] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
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
	  [self _archiveObject: child];
	}
      if ([children count] > 0)
	{
	  [entries setObject: children forKey: @"CPMenuItemsKey"];
	}
    }
  else if ([obj isKindOfClass: [NSMenuItem class]])
    {
      child = [obj submenu];
      if (child != nil)
	{
	  [entries setObject: [self _identifierForObject: child]
		      forKey: @"CPMenuItemSubmenuKey"];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSTabViewItem class]])
    {
      child = [obj view];
      if (child != nil)
	{
	  [entries setObject: [self _identifierForObject: child]
		      forKey: @"CPTabViewItemViewKey"];
	  [self _archiveObject: child];
	}
    }

  return entries;
}

- (NSDictionary *) _archiveObject: (id)obj
{
  NSMutableDictionary *dict = nil;
  NSString *identifier = nil;
  NSString *name = nil;
  NSDictionary *children = nil;

  if (obj == nil)
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
      [dict setObject: [self _rectDictionary: [obj frame]] forKey: @"CPViewFrameKey"];
    }
  if ([obj respondsToSelector: @selector(bounds)])
    {
      [dict setObject: [self _rectDictionary: [obj bounds]] forKey: @"CPViewBoundsKey"];
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
  if ([obj respondsToSelector: @selector(isEnabled)])
    {
      NSString *enabledKey = ([obj isKindOfClass: [NSMenuItem class]])
	? @"CPMenuItemIsEnabledKey"
	: @"CPControlIsEnabledKey";

      [dict setObject: [NSNumber numberWithBool: [obj isEnabled]] forKey: enabledKey];
    }
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
    {
      /*
       * Cappuccino stores text color as a theme attribute for these controls,
       * not as a keyed coding field.
       */
    }
  if ([obj isKindOfClass: [NSTabView class]]
      && [obj respondsToSelector: @selector(font)]
      && [obj font] != nil)
    {
      NSFont *font = [obj font];
      NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
	@"CPFont", @"class",
	[font fontName], @"CPFontNameKey",
	[NSNumber numberWithDouble: [font pointSize]], @"CPFontSizeKey",
	nil];
      [dict setObject: fontDict forKey: @"CPTabViewFontKey"];
    }
  if ([obj respondsToSelector: @selector(image)] && [obj image] != nil)
    {
      NSImage *image = [obj image];
      NSString *imageKey = nil;

      if ([obj isKindOfClass: [NSButton class]])
	{
	  imageKey = @"CPButtonImageKey";
	}
      else if ([obj isKindOfClass: [NSMenuItem class]])
	{
	  imageKey = @"CPMenuItemImageKey";
	}
      else if ([obj isKindOfClass: [NSImageView class]])
	{
	  imageKey = @"CPImageViewImageKey";
	}

      [self _setObject: [image name] forKey: imageKey inDictionary: dict];
    }
  if ([obj isKindOfClass: [NSWindow class]])
    {
      [dict setObject: [self _rectDictionary: [obj frame]]
	       forKey: @"_CPCibWindowTemplateWindowRectKey"];
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj styleMask]]
	   forKey: @"_CPCibWindowTempatStyleMaskKey"];
      [dict setObject: [NSNumber numberWithBool: [_gormDocument objectIsDeferred: obj]]
	   forKey: @"deferred"];
      [dict setObject: [NSNumber numberWithBool: [_gormDocument objectIsVisibleAtLaunch: obj]]
	   forKey: @"visibleAtLaunch"];
      [self _setObject: [obj title]
		forKey: @"_CPCibWindowTemplateWindowTitleKey"
	  inDictionary: dict];
    }
  if ([obj isKindOfClass: [NSButton class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] highlightsBy]]
	   forKey: @"CPButtonHighlightsByKey"];
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] showsStateBy]]
	   forKey: @"CPButtonShowsStateByKey"];
    }
  if ([obj isKindOfClass: [NSMenuItem class]])
    {
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
  if ([obj isKindOfClass: [NSTableColumn class]])
    {
      [self _setObject: [obj identifier]
		forKey: @"CPTableColumnIdentifierKey"
	  inDictionary: dict];
      [dict setObject: [NSNumber numberWithDouble: [obj width]]
	       forKey: @"CPTableColumnWidthKey"];
      [dict setObject: [NSNumber numberWithDouble: [obj minWidth]]
	       forKey: @"CPTableColumnMinWidthKey"];
      [dict setObject: [NSNumber numberWithDouble: [obj maxWidth]]
	       forKey: @"CPTableColumnMaxWidthKey"];
    }
  if ([obj isKindOfClass: [NSTabViewItem class]])
    {
      [self _setObject: [obj label] forKey: @"CPTabViewItemLabelKey" inDictionary: dict];
    }

  children = [self _childArchiveEntriesForObject: obj];
  if ([children count] > 0)
    {
      [dict addEntriesFromDictionary: children];
    }

  [_objects addObject: dict];
  return dict;
}

- (NSData *) data
{
  NSMutableDictionary *root = [NSMutableDictionary dictionary];
  NSMutableArray *topLevelIDs = [NSMutableArray array];
  NSEnumerator *en = [[_gormDocument topLevelObjects] objectEnumerator];
  id obj = nil;
  NSDictionary *classes = nil;
  NSString *errorString = nil;
  NSData *data = nil;

  [_objects removeAllObjects];
  [_visitedObjects removeAllObjects];

  [self _archiveObject: [_gormDocument filesOwner]];
  [self _archiveObject: [_gormDocument firstResponder]];

  while ((obj = [en nextObject]) != nil)
    {
      [topLevelIDs addObject: [self _identifierForObject: obj]];
      [self _archiveObject: obj];
    }

  [root setObject: @"CIB" forKey: @"format"];
  [root setObject: @"1.0" forKey: @"formatVersion"];
  [root setObject: @"Cappuccino" forKey: @"targetRuntime"];
  [root setObject: topLevelIDs forKey: @"topLevelObjectIDs"];
  [root setObject: _objects forKey: @"objects"];

  classes = [[_gormDocument classManager] customClassMap];
  if ([classes count] > 0)
    {
      [root setObject: classes forKey: @"classes"];
    }

  data = [NSPropertyListSerialization dataFromPropertyList: root
						    format: NSPropertyListXMLFormat_v1_0
					  errorDescription: &errorString];
  if (data == nil)
    {
      NSLog(@"Unable to generate CIB property list: %@", errorString);
      RELEASE(errorString);
      data = [NSData data];
    }

  return data;
}

- (BOOL) exportCIBDocumentWithName: (NSString *)name
{
  return [[self data] writeToFile: name atomically: YES];
}

@end
