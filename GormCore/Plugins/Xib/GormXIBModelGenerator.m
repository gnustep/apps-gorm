/** <title>GormXIBKeyedArchiver</title>

   <abstract>Interface of GormXIBKeyedArchiver</abstract>

   Copyright (C) 2023 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg.casamento@gmail.com>
   Date: 2023
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSXMLDocument.h>
#import <Foundation/NSXMLNode.h>
#import <Foundation/NSXMLElement.h>
#import <Foundation/NSXMLParser.h>

#import <AppKit/NSMenu.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSView.h>

#import <GNUstepBase/GSObjCRuntime.h>

#import "GormDocument.h"
#import "GormDocumentController.h"
#import "GormFilePrefsManager.h"
#import "GormProtocol.h"
#import "GormPrivate.h"

#import "GormXIBModelGenerator.h"

static NSDictionary *_methodReturnTypes = nil;
static NSUInteger _count = INT_MAX;

@interface NSString (_hex_)

- (NSString *) lowercaseFirstCharacter;
- (NSString *) splitString;
- (NSString *) hexString;
+ (NSString *) randomHex;

@end

@implementation NSString (_hex_)

- (NSString *) lowercaseFirstCharacter
{
  // Lowercase the first letter of the class to make the element name
  NSString *first = [[self substringToIndex: 1] lowercaseString];
  NSString *rest = [self substringFromIndex: 1];
  NSString *result = [NSString stringWithFormat: @"%@%@", first, rest];
  return result;
}

- (NSString *) splitString
{
  NSString *result = [self substringFromIndex: [self length] - 8];

  result = [NSString stringWithFormat: @"%@-%@-%@",
		     [result substringWithRange: NSMakeRange(0,3)],
		     [result substringWithRange: NSMakeRange(3,2)],
		     [result substringWithRange: NSMakeRange(5,3)]];

  return result;
}

- (NSString *) hexString
{
  NSUInteger l = [self length];
  unichar *c = malloc(l * sizeof(unichar));

  [self getCharacters: c];

  NSString *result = @"";

  for (NSUInteger i = 0; i < l; i++)
    {
      result = [result stringByAppendingString: [NSString stringWithFormat: @"%x", c[i]]];
    }

  free(c);

  return result;
}

+ (NSString *) randomHex
{
  srand((unsigned int)_count--);
  uint32_t r = (uint32_t)rand();
  return [NSString stringWithFormat: @"%08X", r];
}

@end

@implementation GormXIBModelGenerator

+ (void) initialize
{
  if (self == [GormXIBModelGenerator class])
    {
      _methodReturnTypes =
	[[NSDictionary alloc] initWithObjectsAndKeys:
				@"NSRect", @"frame",
			      @"NSImage", @"onStateImage",
			      @"NSImage", @"offStateImage",
			      @"NSUInteger", @"keyEquivalentModifierMask",
			      @"BOOL", @"releaseWhenClosed",
			      @"NSUInteger", @"windowStyleMask",
			      @"NSUInteger", @"borderType",
			      @"CGFloat", @"alphaValue",
			      @"NSFont", @"font",
			      @"NSRect", @"bounds",
			      @"NSUInteger", @"autoresizeMask",
			      @"NSString", @"toolTip",
			      @"NSString", @"keyEquivalent",
			      nil];
    }
}

/**
 * Returns an autoreleast GormXIBDocument object;
 */
+ (instancetype) xibWithGormDocument: (GormDocument *)doc
{
  return AUTORELEASE([[self alloc] initWithGormDocument: doc]);
}

/**
 * Initialize with GormDocument object to parse the XML from or into.
 */
- (instancetype) initWithGormDocument: (GormDocument *)doc
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_gormDocument, doc);
      _mappingDictionary = [[NSMutableDictionary alloc] init];
      _allIdentifiers = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_gormDocument);
  DESTROY(_mappingDictionary);
  DESTROY(_allIdentifiers);
  
  [super dealloc];
}

- (NSString *) _convertName: (NSString *)className
{
  NSString *result = [className stringByReplacingOccurrencesOfString: @"NS"
							  withString: @""];

  // Try removing other prefixes...
  result = [result stringByReplacingOccurrencesOfString: @"GS"
					     withString: @""];
  result = [result stringByReplacingOccurrencesOfString: @"Gorm"
					     withString: @""];

  // Lowercase the first letter of the class to make the element name
  result = [result lowercaseFirstCharacter];

  // Map certain names to XIB equivalents...
  if ([result isEqualToString: @"objectProxy"])
    {
      result = @"customObject";
    }  
  
  return result;
}

- (BOOL) _isSameClass: (NSString *)className1
		  and: (NSString *)className2
{
  NSString *cc1 = [self _convertName: className1];
  NSString *cc2 = [self _convertName: className2];

  return [cc1 isEqualToString: cc2];
}

- (NSString *) _createIdentifierForObject: (id)obj
{
  NSString *result = nil; 

  if ([obj isKindOfClass: [GormObjectProxy class]])
    {
      NSString *className = [obj className];

      if ([className isEqualToString: @"NSApplication"])
	{
	  result = @"-3";
	}
      else if ([className isEqualToString: @"NSOwner"])
	{
	  result = @"-2";
	}
      else if ([className isEqualToString: @"NSFirst"])
	{
	  result = @"-1";
	}
    }
  else
    {
      result = [_gormDocument nameForObject: obj];
    }

  // Encoding
  NSString *originalName = [result copy];
  NSString *stackedResult = [NSString stringWithFormat: @"%@%@%@%@", result,
				      result, result, result];  // kludge...
  // 
  result = [stackedResult hexString];
  result = [result splitString];
  
  // Collision...
  id o = [_mappingDictionary objectForKey: result];
  if (o != nil)
    {
      result = [[NSString randomHex] splitString];
    }

  // If the id already exists, but isn't mapped...
  if ([_allIdentifiers containsObject: result])
    {
      result = [[NSString randomHex] splitString];
    }
  
  if (originalName != nil)
    {
      // Map the name...
      [_mappingDictionary setObject: originalName
			     forKey: result];
    }

  // Record the id...
  [_allIdentifiers addObject: result];
  
  return result;
}

- (NSString *) _userLabelForObject: (id)obj
{
  NSString *result = nil; 

  if ([obj isKindOfClass: [GormObjectProxy class]])
    {
      NSString *className = [obj className];

      if ([className isEqualToString: @"NSApplication"])
	{
	  result = @"Application";
	}
      else if ([className isEqualToString: @"NSOwner"])
	{
	  result = @"File's Owner";
	}
      else if ([className isEqualToString: @"NSFirst"])
	{
	  result = @"First Responder";
	}
    }

  return result;  
}

- (void) _createPlaceholderObjects: (NSXMLElement *)elem
{
  NSXMLElement *co = nil;
  NSXMLNode *attr = nil; 
  NSString *ownerClassName = [[_gormDocument filesOwner] className];

  // Application...
  co = [NSXMLNode elementWithName: @"customObject"];
  attr = [NSXMLNode attributeWithName: @"id" stringValue: @"-3"];
  [co addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"userLabel" stringValue: @"Application"];
  [co addAttribute: attr];

  attr = [NSXMLNode attributeWithName: @"customClass" stringValue: @"NSObject"];
  [co addAttribute: attr];
  [elem addChild: co];

  // File's Owner...
  co = [NSXMLNode elementWithName: @"customObject"];
  attr = [NSXMLNode attributeWithName: @"id" stringValue: @"-2"];
  [co addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"userLabel" stringValue: @"File's Owner"];
  [co addAttribute: attr];

  attr = [NSXMLNode attributeWithName: @"customClass" stringValue: ownerClassName];
  [co addAttribute: attr];
  [elem addChild: co];

  // First Responder
  co = [NSXMLNode elementWithName: @"customObject"];
  attr = [NSXMLNode attributeWithName: @"id" stringValue: @"-1"];
  [co addAttribute: attr];

  attr = [NSXMLNode attributeWithName: @"userLabel" stringValue: @"First Responder"];
  [co addAttribute: attr];

  attr = [NSXMLNode attributeWithName: @"customClass" stringValue: @"FirstResponder"];
  [co addAttribute: attr];
  [elem addChild: co];  
}

- (NSArray *) _propertiesFromMethods: (NSArray *)methods
{
  NSEnumerator *en = [methods objectEnumerator];
  NSString *name = nil;
  NSMutableArray *result = [NSMutableArray array];
  
  while ((name = [en nextObject]) != nil)
    {
      NSString *substring = [name substringToIndex: 3];
      if ([substring isEqualToString: @"set"])
	{
	  NSString *s = [name substringFromIndex: 3];
	  s = [s lowercaseFirstCharacter];
	  s = [s stringByReplacingOccurrencesOfString: @":" withString: @""];
	  
	  if ([methods containsObject: s])
	    {
	      SEL sel = NSSelectorFromString(s);
	      if (sel != NULL)
		{
		  [result addObject: s];
		}
	    }
	}
    }

  return result;
}

- (void) _addRect: (NSRect)r toElement: (NSXMLElement *)elem withName: (NSString *)name
{
  NSXMLElement *rectElem = [NSXMLNode elementWithName: @"rect"];
  NSXMLNode *attr = nil;

  attr = [NSXMLNode attributeWithName: @"key" stringValue: name];
  [rectElem addAttribute: attr];
  attr = [NSXMLNode attributeWithName: @"x" stringValue: [NSString stringWithFormat: @"%4.1f",r.origin.x]];
  [rectElem addAttribute: attr];
  attr = [NSXMLNode attributeWithName: @"y" stringValue: [NSString stringWithFormat: @"%4.1f",r.origin.y]];
  [rectElem addAttribute: attr];
  attr = [NSXMLNode attributeWithName: @"width" stringValue: [NSString stringWithFormat: @"%4.0f",r.size.width]];
  [rectElem addAttribute: attr];
  attr = [NSXMLNode attributeWithName: @"height" stringValue: [NSString stringWithFormat: @"%4.0f",r.size.height]];
  [rectElem addAttribute: attr];

  [elem addChild: rectElem];
}

- (void) _addKeyEquivalent: (NSString *)ke toElement: (NSXMLElement *)elem
{
  if ([ke isEqualToString: @""] == NO)
    {
      NSCharacterSet *cs = [NSCharacterSet alphanumericCharacterSet];
      unichar c = [ke characterAtIndex: 0];

      if ([cs characterIsMember: c])
	{
	  NSXMLNode *attr = [NSXMLNode attributeWithName: @"keyEquivalent" stringValue: ke];
	  [elem addAttribute: attr];
	}
      
      NSLog(@"elem = %@", elem);
    }
}

- (void) _addKeyEquivalentModifierMask: (NSUInteger)mask toElement: (NSXMLElement *)elem
{
  NSXMLNode *attr = nil;
  
  NSDebugLog(@"keyEquivalentModifierMask = %ld, element = %@", mask, elem);
  if ([elem attributeForName: @"keyEquivalent"] != nil)
    {
      if (mask | NSCommandKeyMask)
	{
	  attr = [NSXMLNode attributeWithName: @"command" stringValue: @"YES"];
	}
      if (mask | NSShiftKeyMask)
	{
	  attr = [NSXMLNode attributeWithName: @"shift" stringValue: @"YES"];
	}
      if (mask | NSControlKeyMask)
	{
	  attr = [NSXMLNode attributeWithName: @"control" stringValue: @"YES"];
	}
      if (mask | NSAlternateKeyMask)
	{
	  attr = [NSXMLNode attributeWithName: @"option" stringValue: @"YES"];
	}
      
      if (attr != nil)
	{
	  [elem addAttribute: attr];
	}
    }
}

- (void) _addProperty: (NSString *)name
	     withType: (NSString *)type
	       toElem: (NSXMLElement *)elem
	   fromObject: (id)obj
{
  NSDebugLog(@"%@ -> %@: %@", name, type, elem);
  if ([name isEqualToString: @"frame"])
    {
      NSRect f = [obj frame];
      [self _addRect: f toElement: elem withName: name];
    }
  else if ([name isEqualToString: @"keyEquivalent"])
    {
      NSString *ke = [obj keyEquivalent];
      NSDebugLog(@"keyEquivalent %@", ke);
      [self _addKeyEquivalent: ke toElement: elem];
    }
  else if ([name isEqualToString: @"keyEquivalentModifierMask"])
    {
      NSUInteger k = [obj keyEquivalentModifierMask];
      [self _addKeyEquivalentModifierMask: k toElement: elem];
    }
}

- (void) _addAllProperties: (NSXMLElement *)elem fromObject: (id)obj
{
  NSArray *methods = GSObjCMethodNames(obj, YES);
  NSArray *props = [self _propertiesFromMethods: methods];
  NSEnumerator *en = [props objectEnumerator];
  NSString *name = nil;
  
  while ((name = [en nextObject]) != nil)
    {
      NSString *type = [_methodReturnTypes objectForKey: name];
      NSDebugLog(@"%@ -> %@", name, type);

      if (type != nil)
	{
	  [self _addProperty: name withType: type toElem: elem fromObject: obj];
	}
    }
  
  NSDebugLog(@"methods = %@", props);
}

// This method recursively navigates the entire object tree and emits XML
- (void) _collectObjectsFromObject: (id)obj
			  withNode: (NSXMLElement  *)node
{
  NSString *ident = [self _createIdentifierForObject: obj];

  if (ident != nil)
    {
      NSString *className = NSStringFromClass([obj class]);
      NSString *elementName = [self _convertName: className];
      NSXMLElement *elem = [NSXMLNode elementWithName: elementName];
      NSXMLNode *attr = [NSXMLNode attributeWithName: @"id" stringValue: ident];
      [elem addAttribute: attr];

      NSString *name = [_gormDocument nameForObject:  obj];
      NSString *userLabel = [self _userLabelForObject: obj];
      if (userLabel != nil)
	{
	  attr = [NSXMLNode attributeWithName: @"userLabel" stringValue: userLabel];
	  [elem addAttribute: attr];
	}
      
      if ([obj isKindOfClass: [GormObjectProxy class]] ||
	  [obj respondsToSelector: @selector(className)])
	{
	  if ([self _isSameClass: className and: [obj className]] == NO)
	    {
	      className = [obj className];
	      attr = [NSXMLNode attributeWithName: @"customClass" stringValue: className];
	      [elem addAttribute: attr];      
	    }
	}
      
      // Add all properties, then add the element to the parent...
      [self _addAllProperties: elem fromObject: obj];
      if ([name isEqualToString: @"NSMenu"] == NO)
	{
	  [node addChild: elem];
	}
      
      // If the object responds to "title" get that and add it to the XML
      if ([obj respondsToSelector: @selector(title)])
	{
	  NSString *title = [obj title];
	  if (title != nil)
	    {
	      attr = [NSXMLNode attributeWithName: @"title" stringValue: title];
	      [elem addAttribute: attr];
	    }
	}

      // For each different class, recurse through the structure as needed.
      if ([obj isKindOfClass: [NSMenu class]] ||
	  [obj isKindOfClass: [NSPopUpButton class]]) 
	{
	  NSArray *items = [obj itemArray];
	  NSEnumerator *en = [items objectEnumerator];
	  id item = nil;

	  if ([name isEqualToString: @"NSMenu"])
	    {
	      NSXMLNode *systemMenuAttr = [NSXMLNode attributeWithName: @"systemMenu" stringValue: @"apple"];
	      [elem addAttribute: systemMenuAttr];

	      NSXMLElement *mainMenuElem = [NSXMLNode elementWithName: @"menu"];
	      
	      attr = [NSXMLNode attributeWithName: @"id" stringValue: [[NSString randomHex] splitString]];	      
	      [mainMenuElem addAttribute: attr];

	      attr = [NSXMLNode attributeWithName: @"systemMenu" stringValue: @"main"];
	      [mainMenuElem addAttribute: attr];

	      attr = [NSXMLNode attributeWithName: @"title" stringValue: @"Main Menu"];
	      [mainMenuElem addAttribute: attr];

	      NSXMLElement *mainItemsElem = [NSXMLNode elementWithName: @"items"];
	      [mainMenuElem addChild: mainItemsElem];

	      NSXMLElement *mainMenuItem = [NSXMLNode elementWithName: @"menuItem"];
	      [mainItemsElem addChild: mainMenuItem];
	      attr = [NSXMLNode attributeWithName: @"id" stringValue: [[NSString randomHex] splitString]];
	      [mainMenuItem addAttribute: attr];
	      attr = [NSXMLNode attributeWithName: @"title" stringValue: [obj title]];

	      [mainMenuItem addChild: elem]; // Now add the node, since we have inserted the proper system menu

	      [node addChild: mainMenuElem];
	    }

	  // Add submenu attribute...
	  attr = [NSXMLNode attributeWithName: @"key" stringValue: @"submenu"];
	  [elem addAttribute: attr];

	  NSXMLElement *itemsElem = [NSXMLNode elementWithName: @"items"];
	  while ((item = [en nextObject]) != nil)
	    {
	      [self _collectObjectsFromObject: item
				     withNode: itemsElem];
	    }
	  [elem addChild: itemsElem]; // Add to parent element...
	}

      if ([obj isKindOfClass: [NSMenuItem class]])
	{
	  NSMenu *sm = [obj submenu];
	  if (sm != nil)
	    {
	      [self _collectObjectsFromObject: sm
				     withNode: elem];
	    }
	}

      if ([obj isKindOfClass: [NSWindow class]])
	{
	  NSRect s = [[NSScreen mainScreen] frame];
	  NSRect c = [[obj contentView] frame];

	  [self _addRect: c toElement: elem withName: @"contentRect"];
	  [self _addRect: s toElement: elem withName: @"screenRect"];
	  [self _collectObjectsFromObject: [obj contentView]
				 withNode: elem];
	}

      if ([obj isKindOfClass: [NSView class]])
	{
	  NSArray *subviews = [obj subviews];
	  NSEnumerator *en = [subviews objectEnumerator];
	  id v = nil;

	  if ([obj respondsToSelector: @selector(contentView)])
	    {
	      NSView *sv = [obj superview];
	    }

	  if (obj == [[obj window] contentView])
	    {
	      NSXMLNode *contentViewAttr = [NSXMLNode attributeWithName: @"key" stringValue: @"contentView"];
	      [elem addAttribute: contentViewAttr];
	    }

	  NSXMLElement *subviewsElement = [NSXMLNode elementWithName: @"subviews"];
	  while ((v = [en nextObject]) != nil)
	    {
	      [self _collectObjectsFromObject: v
				     withNode: subviewsElement];
	    }
	  [elem addChild: subviewsElement];
	}
    }
}

- (void) _buildXIBDocumentWithParentNode: (NSXMLElement *)parentNode
{
  NSEnumerator *en = [[_gormDocument topLevelObjects] objectEnumerator];
  id o = nil;

  [_gormDocument deactivateEditors];
  while ((o = [en nextObject]) != nil)
    {
      [self _collectObjectsFromObject: o
			     withNode: parentNode];
    }
  [_gormDocument reactivateEditors];
}

- (NSData *) data
{
  NSString *plugInId = @"com.apple.InterfaceBuilder.CocoaPlugin";
  NSString *typeId = @"com.apple.InterfaceBuilder3.Cocoa.XIB";
  NSString *toolVersion = @"21507";
  
  // Build root element...
  NSXMLElement *rootElement = [NSXMLNode elementWithName: @"document"];
  NSXMLNode *attr = [NSXMLNode attributeWithName: @"type"
				     stringValue: typeId];
  [rootElement addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"version" stringValue: @"3.0"];
  [rootElement addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"toolsVersion" stringValue: toolVersion];
  [rootElement addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"targetRuntime" stringValue: @"MacOSX.Cocoa"];
  [rootElement addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"useAutolayout" stringValue: @"YES"];
  [rootElement addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"propertyAccessControl" stringValue: @"none"];
  [rootElement addAttribute: attr];
  
  attr = [NSXMLNode attributeWithName: @"customObjectInstantiationMethod" stringValue: @"direct"];
  [rootElement addAttribute: attr];
  
  // Build dependencies...
  NSXMLElement *dependencies = [NSXMLNode elementWithName: @"dependencies"];
  NSXMLElement *deployment = [NSXMLNode elementWithName: @"deployment"];
  attr = [NSXMLNode attributeWithName: @"identifier" stringValue: @"macosx"];
  [deployment addAttribute: attr];
  [dependencies addChild: deployment];
  
  NSXMLElement *plugIn = [NSXMLNode elementWithName: @"plugIn"];
  attr = [NSXMLNode attributeWithName: @"identifier" stringValue: plugInId];
  [plugIn addAttribute: attr];
  attr = [NSXMLNode attributeWithName: @"version" stringValue: toolVersion];
  [plugIn addAttribute: attr];
  [dependencies addChild: plugIn];
  
  NSXMLElement *capability = [NSXMLNode elementWithName: @"capability"];
  attr = [NSXMLNode attributeWithName: @"name" stringValue: @"documents saved in the Xcode 8 format"];
  [capability addAttribute: attr];
  attr = [NSXMLNode attributeWithName: @"minToolsVersion" stringValue: @"8"];
  [capability addAttribute: attr];
  [dependencies addChild: capability];
  [rootElement addChild: dependencies];
  
  NSXMLDocument *xibDocument = [NSXMLNode documentWithRootElement: rootElement];      
  NSXMLElement *objects = [NSXMLNode elementWithName: @"objects"];

  // Add placeholder objects to XIB
  [self _createPlaceholderObjects: objects];
  
  // add body to document...
  [rootElement addChild: objects];
  
  // Recursively build the XIB document from the GormDocument...
  [self _buildXIBDocumentWithParentNode: objects];
  
  NSData *data = [xibDocument XMLDataWithOptions: NSXMLNodePrettyPrint | NSXMLNodeCompactEmptyElement ];

  return data;
}

- (BOOL) exportXIBDocumentWithName: (NSString *)name
{
  BOOL result = NO;

  if (name != nil)
    {
      NSData *data = [self data];
      NSString *xmlString = [[NSString alloc] initWithBytes: [data bytes] length: [data length] encoding: NSUTF8StringEncoding];
      
      AUTORELEASE(xmlString);
      result = [xmlString writeToFile: name atomically: YES];
    }
  
  return result;
}

@end
