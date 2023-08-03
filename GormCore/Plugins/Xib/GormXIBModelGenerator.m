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

#import "GormDocument.h"
#import "GormDocumentController.h"
#import "GormFilePrefsManager.h"
#import "GormProtocol.h"
#import "GormPrivate.h"

#import "GormXIBModelGenerator.h"

@interface NSString (_hex_)

- (NSString *) hexString;
+ (NSString *) randomHex;

@end

@implementation NSString (_hex_)

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
  srand((unsigned int)time(NULL));
  uint32_t r = (uint32_t)rand();
  return [NSString stringWithFormat: @"%08X", r];
}

@end

@implementation GormXIBModelGenerator

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
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_gormDocument);
  DESTROY(_mappingDictionary);
  
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
  NSString *first = [[result substringToIndex: 1] lowercaseString];
  NSString *rest = [result substringFromIndex: 1];
 
  result = [NSString stringWithFormat: @"%@%@", first, rest];

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
  result = [result substringFromIndex: [result length] - 8];
  result = [NSString stringWithFormat: @"%@-%@-%@",
		     [result substringWithRange: NSMakeRange(0,3)],
		     [result substringWithRange: NSMakeRange(3,2)],
		     [result substringWithRange: NSMakeRange(5,3)]];

  // Collision...
  if ([_mappingDictionary objectForKey: result] != nil)
    {
      result = [NSString randomHex];
    }
  
  // Map the name...
  [_mappingDictionary setObject: originalName
			 forKey: result];

  
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
      
      [node addChild: elem];
      
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
	  NSString *name = [_gormDocument nameForObject: obj];

	  if ([name isEqualToString: @"NSMenu"])
	    {
	      NSXMLNode *systemMenuAttr = [NSXMLNode attributeWithName: @"systemMenu" stringValue: @"main"];
	      [elem addAttribute: systemMenuAttr];
	    }
	  
	  while ((item = [en nextObject]) != nil)
	    {
	      [self _collectObjectsFromObject: item
				     withNode: elem];
	    }
	}
      else if ([obj isKindOfClass: [NSMenuItem class]])
	{
	  NSMenu *sm = [obj submenu];
	  if (sm != nil)
	    {
	      [self _collectObjectsFromObject: sm
				     withNode: elem];
	    }
	}
      else if ([obj isKindOfClass: [NSWindow class]])
	{
	  [self _collectObjectsFromObject: [obj contentView]
				 withNode: elem];
	}
      else if ([obj isKindOfClass: [NSView class]])
	{
	  NSArray *subviews = [obj subviews];
	  NSEnumerator *en = [subviews objectEnumerator];
	  id v = nil;

	  while ((v = [en nextObject]) != nil)
	    {
	      [self _collectObjectsFromObject: v
				     withNode: elem];
	    }
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
