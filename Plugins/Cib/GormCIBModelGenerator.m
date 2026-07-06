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
  if (value != nil)
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

  return [NSDictionary dictionaryWithObjectsAndKeys:
    @"CPColor", @"class",
    [NSNumber numberWithDouble: [rgbColor redComponent]], @"red",
    [NSNumber numberWithDouble: [rgbColor greenComponent]], @"green",
    [NSNumber numberWithDouble: [rgbColor blueComponent]], @"blue",
    [NSNumber numberWithDouble: [rgbColor alphaComponent]], @"alpha",
    nil];
}

- (NSArray *) _childObjectIDsForObject: (id)obj
{
  NSMutableArray *children = [NSMutableArray array];
  NSEnumerator *en = nil;
  id child = nil;

  if ([obj isKindOfClass: [NSWindow class]])
    {
      child = [obj contentView];
      if (child != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSView class]])
    {
      en = [[obj subviews] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSMenu class]])
    {
      en = [[obj itemArray] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSMenuItem class]])
    {
      child = [obj submenu];
      if (child != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSTabView class]])
    {
      en = [[obj tabViewItems] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSTabViewItem class]])
    {
      child = [obj view];
      if (child != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSScrollView class]])
    {
      child = [obj documentView];
      if (child != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }
  else if ([obj isKindOfClass: [NSTableView class]])
    {
      en = [[obj tableColumns] objectEnumerator];
      while ((child = [en nextObject]) != nil)
	{
	  [children addObject: [self _identifierForObject: child]];
	  [self _archiveObject: child];
	}
    }

  return children;
}

- (NSDictionary *) _archiveObject: (id)obj
{
  NSMutableDictionary *dict = nil;
  NSString *identifier = nil;
  NSString *name = nil;
  NSArray *children = nil;

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
      [dict setObject: [self _rectDictionary: [obj frame]] forKey: @"frame"];
    }
  if ([obj respondsToSelector: @selector(bounds)])
    {
      [dict setObject: [self _rectDictionary: [obj bounds]] forKey: @"bounds"];
    }
  if ([obj respondsToSelector: @selector(title)]
      && [obj isKindOfClass: [NSWindow class]] == NO)
    {
      [self _setObject: [obj title] forKey: @"title" inDictionary: dict];
    }
  if ([obj respondsToSelector: @selector(stringValue)])
    {
      [self _setObject: [obj stringValue] forKey: @"stringValue" inDictionary: dict];
    }
  if ([obj respondsToSelector: @selector(isEnabled)])
    {
      [dict setObject: [NSNumber numberWithBool: [obj isEnabled]] forKey: @"enabled"];
    }
  if ([obj respondsToSelector: @selector(isHidden)])
    {
      [dict setObject: [NSNumber numberWithBool: [obj isHidden]] forKey: @"hidden"];
    }
  if ([obj respondsToSelector: @selector(tag)])
    {
      [dict setObject: [NSNumber numberWithInteger: [obj tag]] forKey: @"tag"];
    }
  if ([obj respondsToSelector: @selector(autoresizingMask)])
    {
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj autoresizingMask]]
	       forKey: @"autoresizingMask"];
    }
  if ([obj respondsToSelector: @selector(backgroundColor)])
    {
      [self _setObject: [self _colorDictionary: [obj backgroundColor]]
		forKey: @"backgroundColor"
	  inDictionary: dict];
    }
  if ([obj respondsToSelector: @selector(textColor)])
    {
      [self _setObject: [self _colorDictionary: [obj textColor]]
		forKey: @"textColor"
	  inDictionary: dict];
    }
  if ([obj respondsToSelector: @selector(font)] && [obj font] != nil)
    {
      NSFont *font = [obj font];
      NSDictionary *fontDict = [NSDictionary dictionaryWithObjectsAndKeys:
	@"CPFont", @"class",
	[font fontName], @"name",
	[NSNumber numberWithDouble: [font pointSize]], @"size",
	nil];
      [dict setObject: fontDict forKey: @"font"];
    }
  if ([obj respondsToSelector: @selector(image)] && [obj image] != nil)
    {
      NSImage *image = [obj image];
      [self _setObject: [image name] forKey: @"imageName" inDictionary: dict];
    }
  if ([obj isKindOfClass: [NSWindow class]])
    {
      [dict setObject: [self _rectDictionary: [obj frame]] forKey: @"frame"];
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj styleMask]]
	   forKey: @"styleMask"];
      [dict setObject: [NSNumber numberWithBool: [_gormDocument objectIsDeferred: obj]]
	   forKey: @"deferred"];
      [dict setObject: [NSNumber numberWithBool: [_gormDocument objectIsVisibleAtLaunch: obj]]
	   forKey: @"visibleAtLaunch"];
    }
  if ([obj isKindOfClass: [NSButton class]])
    {
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] highlightsBy]]
	   forKey: @"highlightsBy"];
      [dict setObject: [NSNumber numberWithInteger: [[obj cell] showsStateBy]]
	   forKey: @"showsStateBy"];
    }
  if ([obj isKindOfClass: [NSMenuItem class]])
    {
      [self _setObject: [obj keyEquivalent] forKey: @"keyEquivalent" inDictionary: dict];
      [dict setObject: [NSNumber numberWithUnsignedInteger: [obj keyEquivalentModifierMask]]
	   forKey: @"keyEquivalentModifierMask"];
      if ([obj submenu] != nil)
	{
	  [dict setObject: [self _identifierForObject: [obj submenu]] forKey: @"submenu"];
	}
    }
  if ([obj isKindOfClass: [NSTableColumn class]])
    {
      [self _setObject: [obj identifier] forKey: @"identifier" inDictionary: dict];
      [dict setObject: [NSNumber numberWithDouble: [obj width]] forKey: @"width"];
      [dict setObject: [NSNumber numberWithDouble: [obj minWidth]] forKey: @"minWidth"];
      [dict setObject: [NSNumber numberWithDouble: [obj maxWidth]] forKey: @"maxWidth"];
    }
  if ([obj isKindOfClass: [NSTabViewItem class]])
    {
      [self _setObject: [obj label] forKey: @"label" inDictionary: dict];
    }

  children = [self _childObjectIDsForObject: obj];
  if ([children count] > 0)
    {
      [dict setObject: children forKey: @"children"];
    }

  [_objects addObject: dict];
  return dict;
}

- (NSArray *) _resourceDictionaries
{
  NSMutableArray *resources = [NSMutableArray array];
  NSArray *objects = [[_gormDocument sounds] arrayByAddingObjectsFromArray: [_gormDocument images]];
  NSEnumerator *en = [objects objectEnumerator];
  id resource = nil;

  while ((resource = [en nextObject]) != nil)
    {
      NSMutableDictionary *dict = [NSMutableDictionary dictionary];

      [self _setObject: [resource fileName] forKey: @"fileName" inDictionary: dict];
      [self _setObject: [resource path] forKey: @"path" inDictionary: dict];
      if ([resource respondsToSelector: @selector(isSystemResource)])
	{
	  [dict setObject: [NSNumber numberWithBool: [resource isSystemResource]]
	       forKey: @"systemResource"];
	}
      [resources addObject: dict];
    }

  return resources;
}

- (NSData *) data
{
  NSMutableDictionary *root = [NSMutableDictionary dictionary];
  NSMutableArray *topLevelIDs = [NSMutableArray array];
  NSEnumerator *en = [[_gormDocument topLevelObjects] objectEnumerator];
  id obj = nil;
  NSArray *resources = nil;
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

  resources = [self _resourceDictionaries];
  if ([resources count] > 0)
    {
      [root setObject: resources forKey: @"resources"];
    }

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
