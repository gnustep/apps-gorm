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
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
 * Implementation of document protocol.  
 */

@implementation IBPaletteDocument

- (id) initWithDocumentPath: (NSString *)docPath
{
  if((self = [super init]) != nil)
    {
      ASSIGN(documentPath, docPath);
      nameTable = [[NSMutableDictionary alloc] init];
      connections = [[NSMutableArray alloc] init];
    }
  return self;
}

- (void) dealloc
{
  RELEASE(documentPath);
  RELEASE(nameTable);
  RELEASE(connections);
  [super dealloc];
}

- (void) addConnector: (id<IBConnectors>)aConnector
{
  // does nothing...
}

- (NSArray*) allConnectors
{
  return nil;
}

- (void) attachObject: (id)anObject toParent: (id)aParent
{
  // does nothing...
}

- (void) attachObjects: (NSArray*)anArray toParent: (id)aParent
{
  // does nothing...
}

- (NSArray*) connectorsForDestination: (id)destination
{
  return nil;
}

- (NSArray*) connectorsForDestination: (id)destination
			      ofClass: (Class)aConnectorClass
{
  return nil;
}

- (NSArray*) connectorsForSource: (id)source
{
  return nil;
}

- (NSArray*) connectorsForSource: (id)source
			 ofClass: (Class)aConnectorClass
{
  return nil;
}

- (BOOL) containsObject: (id)anObject
{
  return NO;
}

- (BOOL) containsObjectWithName: (NSString*)aName forParent: (id)parent
{
  return NO;
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
  // does nothing...
}

- (void) detachObjects: (NSArray*)anArray
{
  // does nothing...
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
  return nil;
}

- (id<IBEditors>) editorForObject: (id)anObject
			 inEditor: (id<IBEditors>)anEditor
			   create: (BOOL)flag
{
  return nil;
}

- (NSString*) nameForObject: (id)anObject
{
  return nil;
}

- (id) objectForName: (NSString*)aName
{
  return nil;
}

- (NSArray*) objects
{
  return nil;
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
  return nil;
}

- (NSArray*) pasteType: (NSString*)aType
	fromPasteboard: (NSPasteboard*)aPasteboard
		parent: (id)parent
{
  return nil;
}

- (void) removeConnector: (id<IBConnectors>)aConnector
{
  // does nothing...
}

- (void) resignSelectionForEditor: (id<IBEditors>)editor
{
  // does nothing...
}

- (void) setName: (NSString*)aName forObject: (id)object
{
  
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
