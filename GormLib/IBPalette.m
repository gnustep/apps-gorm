/* IBPalette.m
 *
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <InterfaceBuilder/IBPalette.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

NSString	*IBCellPboardType = @"IBCellPboardType";
NSString	*IBMenuPboardType = @"IBMenuPboardType";
NSString	*IBMenuCellPboardType = @"IBMenuCellPboardType";
NSString	*IBObjectPboardType = @"IBObjectPboardType";
NSString	*IBViewPboardType = @"IBViewPboardType";
NSString	*IBWindowPboardType = @"IBWindowPboardType";
NSString	*IBFormatterPboardType = @"IBFormatterPboardType";

// Gorm specific paste board types..
NSString        *GormImagePboardType = @"GormImagePboardType";
NSString        *GormSoundPboardType = @"GormSoundPboardType";
NSString        *GormLinkPboardType = @"GormLinkPboardType";

@interface IBPaletteDocument : NSObject <IBDocuments>
{
  NSMutableDictionary *nameTable;
  NSMutableArray *connections;
  NSMutableArray *parentLinks;
  NSString *documentPath;
}
@end

@implementation	IBPalette

static NSMapTable	*viewToObject = 0;
static NSMapTable	*viewToType = 0;

+ (void) initialize
{
  if (self == [IBPalette class])
    {
      viewToObject = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
	NSObjectMapValueCallBacks, 20);
      viewToType = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
	NSObjectMapValueCallBacks, 20);
    }
}

+ (id) objectForView: (NSView*)aView
{
  id	obj = (id)NSMapGet(viewToObject, (void*)aView);

  if (obj == nil)
    {
      obj = aView;
    }
  return obj;
}

+ (NSString*) typeForView: (NSView*)aView
{
  NSString	*type = (NSString*)NSMapGet(viewToType, (void*)aView);

  if (type == nil)
    {
      type = IBViewPboardType;
    }
  return type;
}

- (void) associateObject: (id)anObject
		    type: (NSString*)aType
		    with: (NSView*)aView
{
  NSMapInsert(viewToType, (void*)aView, (id)aType);
  NSMapInsert(viewToObject, (void*)aView, (id)anObject);
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(icon);
  RELEASE(document);
  [super dealloc];
}

- (void) finishInstantiate
{
}

- (id) init
{
  NSBundle	*bundle;
  NSDictionary	*paletteInfo;
  NSString	*fileName;
  
  bundle = [NSBundle bundleForClass: [self class]]; 

  // load the palette dictionary...
  fileName = [bundle pathForResource: @"palette" ofType: @"table"];
  paletteInfo = [[NSString stringWithContentsOfFile: fileName]
		  propertyList];

  // load the image...
  fileName = [paletteInfo objectForKey: @"Icon"];
  fileName = [bundle pathForImageResource: fileName];
  if (fileName == nil)
    {
      NSRunAlertPanel(NULL, @"Icon for palette is missing",
		       @"OK", NULL, NULL);
      AUTORELEASE(self);
      return nil;
    }
  icon = [[NSImage alloc] initWithContentsOfFile: fileName];

  // load the nibfile...
  fileName = [paletteInfo objectForKey: @"NibFile"];
  if (fileName != nil && [fileName isEqual: @""] == NO)
    {
      NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: self, @"NSOwner",nil];
      if ([bundle loadNibFile: fileName
		  externalNameTable: context
		  withZone: NSDefaultMallocZone()] == NO)
	{
	  NSRunAlertPanel(NULL, @"Nib for palette would not load",
			   @"OK", NULL, NULL);
	  AUTORELEASE(self);
	  return nil;
	}
    }

  document = [[IBPaletteDocument alloc] init];

  return self;
}

- (NSImage*) paletteIcon
{
  return icon;
}

- (NSWindow*) originalWindow
{
  return originalWindow;
}

- (id<IBDocuments>) paletteDocument
{
  return document;
}
@end

/**
 * Implementation of document protocol for palette.  
 */

//
// NOTE: This is a very rudimentary implementation.
//
@implementation IBPaletteDocument

- (id) initWithDocumentPath: (NSString *)docPath
{
  if((self = [super init]) != nil)
    {
      ASSIGN(documentPath, docPath);
      nameTable = [[NSMutableDictionary alloc] init];
      connections = [[NSMutableArray alloc] init];
      parentLinks = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(documentPath);
  RELEASE(nameTable);
  RELEASE(connections);
  RELEASE(parentLinks);
  [super dealloc];
}

- (void) addConnector: (id<IBConnectors>)aConnector
{
  [connections addObject: aConnector];
}

- (NSArray*) allConnectors
{
  return connections;
}

- (NSString *) _uniqueObjectNameFrom: (NSString *)name
{
  NSString *search = [NSString stringWithString: name];
  int i = 1;

  while([nameTable objectForKey: search])
    {
      search = [name stringByAppendingString: [NSString stringWithFormat: @"%d",i++]];
    }

  return search;
}

- (void) attachObject: (id)anObject toParent: (id)aParent
{
  NSNibConnector *conn = [NSNibConnector init];
  NSString *name = [self _uniqueObjectNameFrom: [anObject className]];
  
  // create the relationship.
  [conn setSource: aParent];
  [conn setDestination: anObject];
  [parentLinks addObject: conn];
  [nameTable setObject: anObject forKey: name];
  [connections addObject: conn];
}

- (void) attachObjects: (NSArray*)anArray toParent: (id)aParent
{
  NSEnumerator *en = [anArray objectEnumerator];
  id obj;
  
  while((obj = [en nextObject]) != nil)
    {
      [self attachObject: obj toParent: aParent];
    }
}

- (NSArray*) connectorsForDestination: (id)destination
{
  return [self connectorsForDestination: destination ofClass: [NSObject class]];
}

- (NSArray*) connectorsForDestination: (id)destination
			      ofClass: (Class)aClass
{
  NSEnumerator *en = [connections objectEnumerator];
  NSMutableArray *array = [NSMutableArray array];
  id obj;
  
  while((obj = [en nextObject]) != nil)
    {
      id dest = [obj destination];
      if(dest == destination && [obj isKindOfClass: aClass])
	{
	  [array addObject: obj];
	}
    }

  return array;
}

- (NSArray*) connectorsForSource: (id)source
{
  return [self connectorsForSource: source ofClass: [NSObject class]];
}

- (NSArray*) connectorsForSource: (id)source
			 ofClass: (Class)aClass
{
  NSEnumerator *en = [connections objectEnumerator];
  NSMutableArray *array = [NSMutableArray array];
  id obj;
  
  while((obj = [en nextObject]) != nil)
    {
      id src = [obj source];
      if(src == source && [obj isKindOfClass: aClass])
	{
	  [array addObject: obj];
	}
    }

  return array;
}

- (BOOL) containsObject: (id)anObject
{
  return [[nameTable allValues] containsObject: anObject];
}

- (BOOL) containsObjectWithName: (NSString*)aName forParent: (id)parent
{
  BOOL result = NO;
  id obj = [nameTable objectForKey: aName];

  if(obj != nil)
    {
      NSEnumerator *en = [parentLinks objectEnumerator];
      id conn;
      
      while((conn = [en nextObject]) != nil)
	{
	  id dst = [conn destination];
	  if(dst == obj)
	    {
	      result = YES;
	      break;
	    }
	}
      
    }

  return result;
}

- (BOOL) copyObject: (id)anObject
	       type: (NSString*)aType
       toPasteboard: (NSPasteboard*)aPasteboard
{
  return NO;
}

- (BOOL) copyObjects: (NSArray*)anArray
		type: (NSString*)aType
	toPasteboard: (NSPasteboard*)aPasteboard
{
  return NO;
}

- (void) detachObject: (id)anObject
{
  NSString *name = [self nameForObject: anObject];
  [nameTable removeObjectForKey: name];
}

- (void) detachObjects: (NSArray*)anArray
{
  NSEnumerator *en = [anArray objectEnumerator];
  id obj;
  
  while((obj = [en nextObject]) != nil)
    {
      [self detachObject: obj];
    }  
}

- (NSString*) documentPath
{
  return documentPath;
}

- (void) editor: (id<IBEditors>)anEditor didCloseForObject: (id)anObject
{
  // does nothing...
}

- (id<IBEditors>) editorForObject: (id)anObject
			   create: (BOOL)flag
{
  // does nothing...
  return nil;
}

- (id<IBEditors>) editorForObject: (id)anObject
			 inEditor: (id<IBEditors>)anEditor
			   create: (BOOL)flag
{
  // does nothing...
  return nil;
}

- (NSString*) nameForObject: (id)anObject
{
  NSEnumerator *en = [nameTable keyEnumerator];
  NSString *key;

  while((key = [en nextObject]) != nil)
    {
      if(anObject == [nameTable objectForKey: key])
	{
	  break;
	}
    }
  
  return key;
}

- (id) objectForName: (NSString*)aName
{
  return [nameTable objectForKey: aName];
}

- (NSArray*) objects
{
  return [NSArray arrayWithArray: [nameTable allValues]];
}

- (id<IBEditors>) openEditorForObject: (id)anObject
{
  return nil;
}

- (id<IBEditors, IBSelectionOwners>) parentEditorForEditor: (id<IBEditors>)anEditor
{
  return nil;
}

- (id) parentOfObject: (id)anObject
{
  NSEnumerator *en = [parentLinks objectEnumerator];
  id conn;
  id result;

  while((conn = [en nextObject]) != nil)
    {
      id dst = [conn destination];
      if(dst == anObject)
	{
	  result = [conn source];
	  break;
	}
    }
  
  return result;
}

- (NSArray*) pasteType: (NSString*)aType
	fromPasteboard: (NSPasteboard*)aPasteboard
		parent: (id)parent
{
  return nil;
}

- (void) removeConnector: (id<IBConnectors>)aConnector
{
  [connections removeObjectIdenticalTo: aConnector];
}

- (void) resignSelectionForEditor: (id<IBEditors>)editor
{
  // does nothing...
}

- (void) setName: (NSString*)aName forObject: (id)object
{
  id obj = [nameTable objectForKey: aName];

  RETAIN(obj);
  [nameTable removeObjectForKey: aName];
  [nameTable setObject: object forKey: aName];
  RELEASE(obj);
	       
}
 
- (void) setSelectionFromEditor: (id<IBEditors>)anEditor
{
  // does nothing...
}

- (void) touch
{
  // does nothing...
}
@end
