/* GormDocument.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include "GormPrivate.h"

NSString *IBDidOpenDocumentNotification = @"IBDidOpenDocumentNotification";
NSString *IBWillSaveDocumentNotification = @"IBWillSaveDocumentNotification";
NSString *IBDidSaveDocumentNotification = @"IBDidSaveDocumentNotification";
NSString *IBWillCloseDocumentNotification = @"IBWillCloseDocumentNotification";

/*
 * Each document has a GormFilesOwner object that is used as a placeholder
 * for the owner of the document.
 */
@interface	GormFilesOwner : NSObject
{
}
@end

@implementation	GormFilesOwner
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormFilesOwner"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end

/*
 * Each document has a GormFirstResponder object that is used as a placeholder
 * for the first responder at any instant.
 */
@interface	GormFirstResponder : NSObject
{
}
@end

@implementation	GormFirstResponder
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormFirstResponder"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end

/*
 * Each document may have a GormFontManager object that is used as a
 * placeholder for the current fornt manager.
 */
@interface	GormFontManager : NSObject
{
}
@end

@implementation	GormFontManager
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormFontManager"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end



/*
 * Trivial classes for connections from objects to their editors, and from
 * child editors to their parents.  This does nothing special, but we can
 * use the fact that it's a different class to search for it in the connections
 * array.
 */
@interface	GormObjectToEditor : NSNibConnector
@end

@implementation	GormObjectToEditor
@end

@interface	GormEditorToParent : NSNibConnector
@end

@implementation	GormEditorToParent
@end

@implementation GormDocument

+ (void) initialize
{
  if (self == [GormDocument class])
    {
    }
}

- (void) addConnector: (id<IBConnectors>)aConnector
{
  if ([connections indexOfObjectIdenticalTo: aConnector] == NSNotFound)
    {
      [connections addObject: aConnector];
    }
}

- (NSArray*) allConnectors
{
  return [NSArray arrayWithArray: connections];
}

- (void) attachObject: (id)anObject toParent: (id)aParent
{
  NSArray	*old;

  /*
   * Create a connector that links this object to its parent.
   * A nil parent is the root of the hierarchy so we use a dummy object for it.
   */
  if (aParent == nil)
    {
      aParent = filesOwner;
    }
  old = [self connectorsForSource: anObject ofClass: [NSNibConnector class]];
  if ([old count] > 0)
    {
      [[old objectAtIndex: 0] setDestination: aParent];
    }
  else
    {
      NSNibConnector	*con = [NSNibConnector new];

      [con setSource: anObject];
      [con setDestination: aParent];
      [self addConnector: (id<IBConnectors>)con];
      RELEASE(con);
    }
  [self setName: nil forObject: anObject];

  if ([anObject isKindOfClass: [NSWindow class]] == YES
    || [anObject isKindOfClass: [NSMenu class]] == YES)
    {
      [resourcesManager addObject: anObject];
      [[self openEditorForObject: anObject] activate];
    }
}

- (void) attachObjects: (NSArray*)anArray toParent: (id)aParent
{
  NSEnumerator	*enumerator = [anArray objectEnumerator];
  NSObject	*obj;

  while ((obj = [enumerator nextObject]) != nil)
    {
      [self attachObject: obj toParent: aParent];
    }
}

/*
 * A Gorm document is encoded in the archive as a GSNibContainer ...
 * A class that the gnustep gui library knbows about and can unarchive.
 */
- (Class) classForCoder
{
  return [GSNibContainer class];
}

- (NSArray*) connectorsForDestination: (id)destination
{
  return [self connectorsForDestination: destination ofClass: 0];
}

- (NSArray*) connectorsForDestination: (id)destination
                              ofClass: (Class)aConnectorClass
{
  NSMutableArray	*array = [NSMutableArray arrayWithCapacity: 16];
  NSEnumerator		*enumerator = [connections objectEnumerator];
  id<IBConnectors>	c;

  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c destination] == destination
	&& (aConnectorClass == 0 || aConnectorClass == [c class]))
	{
	  [array addObject: c];
	}
    }
  return array;
}

- (NSArray*) connectorsForSource: (id)source
{
  return [self connectorsForSource: source ofClass: 0];
}

- (NSArray*) connectorsForSource: (id)source
			 ofClass: (Class)aConnectorClass
{
  NSMutableArray	*array = [NSMutableArray arrayWithCapacity: 16];
  NSEnumerator		*enumerator = [connections objectEnumerator];
  id<IBConnectors>	c;

  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c source] == source
	&& (aConnectorClass == 0 || aConnectorClass == [c class]))
	{
	  [array addObject: c];
	}
    }
  return array;
}

- (BOOL) containsObject: (id)anObject
{
  if ([self nameForObject: anObject] == nil)
    {
      return NO;
    }
  return YES;
}

- (BOOL) containsObjectWithName: (NSString*)aName forParent: (id)parent
{
  id	obj = [nameTable objectForKey: aName];

  if (obj == nil)
    {
      return NO;
    }
  return YES; 
}

- (BOOL) copyObject: (id)anObject
               type: (NSString*)aType
       toPasteboard: (NSPasteboard*)aPasteboard
{
  return [self copyObjects: [NSArray arrayWithObject: anObject]
		      type: aType
	      toPasteboard: aPasteboard];
}

- (BOOL) copyObjects: (NSArray*)anArray
                type: (NSString*)aType
        toPasteboard: (NSPasteboard*)aPasteboard
{
  NSData	*obj = [NSArchiver archivedDataWithRootObject: anArray];

  [aPasteboard declareTypes: [NSArray arrayWithObject: aType]
		      owner: self];
  return [aPasteboard setData: obj forType: aType];
}

- (void) dealloc
{
  [[resourcesManager window] performClose: self];
  RELEASE(resourcesManager);
  RELEASE(filesOwner);
  RELEASE(firstResponder);
  RELEASE(fontManager);
  NSFreeMapTable(objToName);
  RELEASE(documentPath);
  [super dealloc];
}

- (void) detachObject: (id)anObject
{
  NSString	*name = [self nameForObject: anObject];
  unsigned	count = [connections count];

  [[self editorForObject: anObject create: NO] close];

  while (count-- > 0)
    {
      id<IBConnectors>	con = [connections objectAtIndex: count];

      if ([con destination] == anObject || [con source] == anObject)
	{
	  [connections removeObjectAtIndex: count];
	}
    }
  NSMapRemove(objToName, (void*)anObject);
  if ([anObject isKindOfClass: [NSWindow class]] == YES
    || [anObject isKindOfClass: [NSMenu class]] == YES)
    {
      [resourcesManager removeObject: anObject];
    }
  [nameTable removeObjectForKey: name];
}

- (void) detachObjects: (NSArray*)anArray
{
  NSEnumerator  *enumerator = [anArray objectEnumerator];
  NSObject      *obj;

  while ((obj = [enumerator nextObject]) != nil)
    {
      [self detachObject: obj];
    }
}

- (NSString*) documentPath
{
  return documentPath;
}

- (BOOL) documentShouldClose
{
  if ([[resourcesManager window] isDocumentEdited] == YES)
    {
      NSString	*msg;
      int	result;

      if (documentPath == nil || [documentPath isEqualToString: @""])
	{
	  msg = @"Document 'UNTITLED' has been modified";
	}
      else
	{
	  msg = [NSString stringWithFormat: @"Document '%@' has been modified",
	    [documentPath lastPathComponent]];
	}
      result = NSRunAlertPanel(NULL, msg, @"Save", @"Cancel", @"Don't Save");
      if (result == NSAlertAlternateReturn)
	{
	  return NO;
	}
      else if (result != NSAlertOtherReturn)
	{
	  [self saveDocument: self];
	}
    }
  return YES;
}

- (void) documentWillClose
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  Class		winClass = [NSWindow class];
  NSEnumerator	*enumerator;
  id		obj;

  [nc postNotificationName: IBWillCloseDocumentNotification
		    object: self];
  /*
   * Close all open windows in this document befoew we go away.
   */
  enumerator = [nameTable objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    {
      if ([obj isKindOfClass: winClass] == YES)
	{
	  [obj setReleasedWhenClosed: YES];
	  [obj close];
	}
    }
  [self setDocumentActive: NO];
}

- (void) editor: (id<IBEditors>)anEditor didCloseForObject: (id)anObject
{
  NSArray		*links;
  id<IBConnectors>	con;

  /*
   * If there is a link from this editor to a parent, remove it.
   */
  links = [self connectorsForSource: anEditor
			    ofClass: [GormEditorToParent class]];
  con = [links lastObject];
  if (con != nil)
    {
      [connections removeObjectIdenticalTo: con];
    }
      
  /*
   * Remove the connection linking the object to this editor.
   */
  links = [self connectorsForSource: anObject
			    ofClass: [GormObjectToEditor class]];
  con = [links lastObject];
  if (con != nil)
    {
      [connections removeObjectIdenticalTo: con];
    }
  else
    {
      NSLog(@"Strange - removing editor without link from edited object");
    }
}

- (id<IBEditors>) editorForObject: (id)anObject
                           create: (BOOL)flag
{
  return [self editorForObject: anObject inEditor: nil create: flag];
}

- (id<IBEditors>) editorForObject: (id)anObject
                         inEditor: (id<IBEditors>)anEditor
                           create: (BOOL)flag
{
  NSArray	*links;

  /*
   * Look up the editor links for the object to see if it already has an
   * editor.  If it does return it, otherwise create a new editor and a
   * link to it if the flag is set.
   */
  links = [self connectorsForSource: anObject
			    ofClass: [GormObjectToEditor class]];
  if ([links count] == 0 && flag == YES)
    {
      Class		eClass;
      id<IBEditors>	editor;
      id<IBConnectors>	link;

      eClass = NSClassFromString([anObject editorClassName]);
      editor = [[eClass alloc] initWithObject: anObject inDocument: self];
      link = [GormObjectToEditor new];
      [link setSource: anObject];
      [link setDestination: editor];
      [connections addObject: link];
      RELEASE(link);
      if (anEditor != nil)
	{
	  /*
	   * This editor has a parent - so link to it.
	   */
	  link = [GormEditorToParent new];
	  [link setSource: editor];
	  [link setDestination: anEditor];
	  [connections addObject: link];
	  RELEASE(link);
	}
      RELEASE(editor);
      return editor;
    }
  else
    {
      return [links lastObject];
    }
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  NSMutableArray	*editorInfo;
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  id			obj;

  /*
   * Map all connector sources and destinations to their name strings.
   */
  editorInfo = [NSMutableArray new];
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      if ([con isKindOfClass: [GormObjectToEditor class]] == YES)
	{
	  [editorInfo addObject: con];
	}
      else if ([con isKindOfClass: [GormEditorToParent class]] == YES)
	{
	  [editorInfo addObject: con];
	}
      else
	{
	  NSString	*name;
	  id		obj;

	  obj = [con source];
	  name = [self nameForObject: obj];
	  [con setSource: name];
	  obj = [con destination];
	  name = [self nameForObject: obj];
	  [con setDestination: name];
	}
    }
  /*
   * Remove objects and connections that shouldn't be archived.
   * All editors are closed (this removes their links).
   */
  enumerator = [editorInfo objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      if ([con isKindOfClass: [GormObjectToEditor class]] == YES)
	{
	  [[con destination] close];
	}
    }
  RELEASE(editorInfo);
  [nameTable removeObjectForKey: @"NSOwner"];
  [nameTable removeObjectForKey: @"NSFirst"];

  /*
   * Archive self into file
   */
  [super encodeWithCoder: aCoder];

  /*
   * Restore removed objects.
   */
  [nameTable setObject: filesOwner forKey: @"NSOwner"];
  [nameTable setObject: firstResponder forKey: @"NSFirst"];

  /*
   * Map all connector source and destination names to their objects.
   */
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSString	*name;
      id	obj;

      name = (NSString*)[con source];
      obj = [self objectForName: name];
      [con setSource: obj];
      name = (NSString*)[con destination];
      obj = [self objectForName: name];
      [con setDestination: obj];
    }

  /*
   * Restore basic editor information.
   */
  enumerator = [nameTable objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    {
      if ([obj isKindOfClass: [NSWindow class]] == YES
       || [obj isKindOfClass: [NSMenu class]] == YES)
	{
	  [[self openEditorForObject: obj] activate];
	}
    }
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      objToName = NSCreateMapTableWithZone(NSNonRetainedObjectMapKeyCallBacks,
	NSNonRetainedObjectMapValueCallBacks, 128, [self zone]);

      resourcesManager = [GormResourcesManager newManagerForDocument: self];
      /*
       * Set up special-case dummy objects and add them to the resources mgr.
       */
      filesOwner = [GormFilesOwner new];
      [self setName: @"NSOwner" forObject: filesOwner];
      [resourcesManager addObject: filesOwner];
      firstResponder = [GormFirstResponder new];
      [self setName: @"NSFirst" forObject: firstResponder];
      [resourcesManager addObject: firstResponder];
      fontManager = [GormFontManager new];
    }
  return self;
}

- (NSString*) nameForObject: (id)anObject
{
  return (NSString*)NSMapGet(objToName, (void*)anObject);
}

- (id) objectForName: (NSString*)name
{
  return [nameTable objectForKey: name];
}

- (NSArray*) objects
{
  return [nameTable allValues];
}

/*
 * NB. This assumes we have an empty document to start with - the loaded
 * document is merged in to it.
 */
- (id) openDocument: (id)sender
{
  NSArray	*fileTypes = [NSArray arrayWithObject: @"nib"];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSMutableDictionary	*nt;
      NSString		*aFile = [oPanel filename];
      NSData		*data;
      NSUnarchiver	*u;
      GSNibContainer	*c;
      NSEnumerator	*enumerator;
      id <IBConnectors>	con;
      NSString		*name;

      data = [NSData dataWithContentsOfFile: aFile];
      if (data == nil)
	{
	  NSRunAlertPanel(NULL,
	    [NSString stringWithFormat: @"Could not read '%@' data", aFile],
	     @"OK", NULL, NULL);
	  return nil;
	}

      /*
       * Create an unarchiver, and use it to unarchive the nib file while
       * handling class replacement so that standard objects understood
       * by the gui library are converted to their Gorm internal equivalents.
       */
      u = AUTORELEASE([[NSUnarchiver alloc] initForReadingWithData: data]);
      [u decodeClassName: @"GSNibContainer"
	     asClassName: @"GormDocument"];
      c = [u decodeObject];
      if (c == nil || [c isKindOfClass: [GSNibContainer class]] == NO)
	{
	  NSRunAlertPanel(NULL, @"Could not unarchive document data", 
			   @"OK", NULL, NULL);
	  return nil;
	}

      /*
       * In the newly loaded nib container, we change all the connectors
       * to hold the objects rather than their names (using our own dummy
       * object as the 'NSOwner'.
       */
      [[c nameTable] setObject: filesOwner forKey: @"NSOwner"];
      [[c nameTable] setObject: firstResponder forKey: @"NSFirst"];
      nt = [c nameTable];
      enumerator = [[c connections] objectEnumerator];
      while ((con = [enumerator nextObject]) != nil)
	{
	  NSString  *name;
	  id        obj;

	  name = (NSString*)[con source];
	  obj = [nt objectForKey: name];
	  [con setSource: obj];
	  name = (NSString*)[con destination];
	  obj = [nt objectForKey: name];
	  [con setDestination: obj];
	}
 
      /*
       * Now we merge the objects from the nib container into our own data
       * structures, taking care not to overwrite our NSOwner and NSFirst.
       */
      [nt removeObjectForKey: @"NSOwner"];
      [nt removeObjectForKey: @"NSFirst"];
      [connections addObjectsFromArray: [c connections]];
      [nameTable addEntriesFromDictionary: nt];

      /*
       * Now we build our reverse mapping information and other initialisation
       */
      NSResetMapTable(objToName);
      NSMapInsert(objToName, (void*)filesOwner, (void*)@"NSOwner");
      NSMapInsert(objToName, (void*)firstResponder, (void*)@"NSFirst");
      enumerator = [nameTable keyEnumerator];
      while ((name = [enumerator nextObject]) != nil)
	{
	  id	obj = [nameTable objectForKey: name];

	  NSMapInsert(objToName, (void*)obj, (void*)name);

	  if ([obj isKindOfClass: [NSWindow class]] == YES
	   || [obj isKindOfClass: [NSMenu class]] == YES)
	    {
	      [resourcesManager addObject: obj];
	      [[self openEditorForObject: obj] activate];
	    }
	}

      /*
       * Finally, we set our new file name
       */
      ASSIGN(documentPath, aFile);
      [[resourcesManager window] setTitleWithRepresentedFilename: documentPath];
      [nc postNotificationName: IBDidOpenDocumentNotification
			object: self];
      return self;
    }
  return nil;		/* Failed	*/
}

- (id<IBEditors>) openEditorForObject: (id)anObject
{
  id<IBEditors>	e = [self editorForObject: anObject create: YES];
  id<IBEditors>	p = [self parentEditorForEditor: e];
  
  if (p != nil)
    {
      [self openEditorForObject: [p editedObject]];
    }
  return e;
}

- (id<IBEditors>) parentEditorForEditor: (id<IBEditors>)anEditor
{
  NSArray		*links;
  GormObjectToEditor	*con;

  links = [self connectorsForSource: anEditor
			    ofClass: [GormObjectToEditor class]];
  con = [links lastObject];
  return [con destination];
}

- (id) parentOfObject: (id)anObject
{
  NSArray		*old;
  id<IBConnectors>	con;

  old = [self connectorsForSource: anObject ofClass: [NSNibConnector class]];
  con = [old lastObject];
  if ([con destination] != filesOwner && [con destination] != firstResponder)
    {
      return [con destination];
    }
  return nil;
}

- (NSArray*) pasteType: (NSString*)aType
        fromPasteboard: (NSPasteboard*)aPasteboard
                parent: (id)parent
{
  NSData	*data = [aPasteboard dataForType: aType];
  NSArray	*objects = [NSUnarchiver unarchiveObjectWithData: data];
  NSEnumerator	*enumerator = [objects objectEnumerator];
  NSPoint	filePoint;
  NSPoint	screenPoint;

  filePoint = [[resourcesManager window] mouseLocationOutsideOfEventStream];
  screenPoint = [[resourcesManager window] convertBaseToScreen: filePoint];

  if ([aType isEqualToString: IBWindowPboardType] == YES)
    {
      NSWindow	*win;

      while ((win = [enumerator nextObject]) != nil)
	{
	  [win setFrameTopLeftPoint: screenPoint];
	}
    }
  else
    {
      NSLog(@"Pasting %@ not implemented", aType);
      objects = nil;
/* FIXME */
    }

  [self attachObjects: objects toParent: parent];
  [self touch];
  return objects;
}

- (void) removeConnector: (id<IBConnectors>)aConnector
{
  [connections removeObjectIdenticalTo: aConnector];
}

- (void) resignSelectionForEditor: (id<IBEditors>)editor
{
  NSEnumerator		*enumerator = [connections objectEnumerator];
  Class			editClass = [GormObjectToEditor class];
  id<IBConnectors>	c;

  /*
   * This editor wants to give up the selection.  Go through all the known
   * editors (with links in the connections array) and try to find one
   * that wants to take over the selection.  Activate whatever editor we
   * find (or re-activate the one we already have).
   */
  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c class] == editClass)
	{
	  id<IBEditors>	e = [c destination];

	  if (e != editor && [e wantsSelection] == YES)
	    {
	      editor = e;
	      break;
	    }
	}
    }
  [editor activate];
}

- (GormResourcesManager*) resourcesManager
{
  return resourcesManager;
}

- (void) setName: (NSString*)aName forObject: (id)object
{
  id		oldObject;
  NSString	*oldName;

  if (object == nil)
    {
      NSLog(@"Attempt to set name for nil object");
      return;
    }
  if (aName == nil)
    {
      /*
       * No name given - so we must generate one unless we already have one.
       */
      oldName = [self nameForObject: object];
      if (oldName == nil)
	{
	  NSString	*base;
	  unsigned	i = 0;

	  /*
	   * Generate a sensible name for the object based on its class.
	   */
	  base = NSStringFromClass([object class]);
	  if ([base hasPrefix: @"NS"] || [base hasPrefix: @"GS"])
	    {
	      base = [base substringFromIndex: 2];
	    }
	  aName = base;
	  while ([nameTable objectForKey: aName] != nil)
	    {
	      aName = [base stringByAppendingFormat: @"%u", ++i];
	    }
	}
      else
	{
	  return;	/* Already named ... nothing to do */
	}
    }
  else
    {
      oldObject = [nameTable objectForKey: aName];
      if (oldObject != nil)
	{
	  NSLog(@"Attempt to re-use name '%@'", aName);
	  return;
	}
      oldName = [self nameForObject: object];
      if (oldName != nil)
	{
	  if ([oldName isEqual: aName] == YES)
	    {
	      return;	/* Already have this namre ... nothing to do */
	    }
	  NSMapRemove(objToName, (void*)object);
	}
    }
  [nameTable setObject: object forKey: aName];
  NSMapInsert(objToName, (void*)object, (void*)aName);
  if (oldName != nil)
    {
      [nameTable removeObjectForKey: oldName];
    }
}

- (id) saveAsDocument: (id)sender
{
  NSSavePanel	*sp;
  int		result;

  sp = [NSSavePanel savePanel];

  [sp setRequiredFileType: @"nib"];
  result = [sp runModalForDirectory: NSHomeDirectory() file: @""];

  if (result == NSOKButton)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*path = [sp filename];
      NSString		*old = documentPath;
      id		retval;

      if ([path isEqual: documentPath] == NO
	&& [mgr fileExistsAtPath: path] == YES)
	{
	  if (NSRunAlertPanel(NULL, @"A document with that name exists", 
	    @"Replace", @"Cancel", NULL) != NSAlertDefaultReturn)
	    {
	      return nil;
	    }
	  else
	    {
	      NSString	*bPath = [path stringByAppendingString: @"~"];

	      [mgr removeFileAtPath: bPath handler: nil];
	      [mgr movePath: path toPath: bPath handler: nil];
	    }
	}
      documentPath = RETAIN(path);
      retval = [self saveDocument: sender];
      if (retval == nil)
	{
	  RELEASE(documentPath);
	  documentPath = old;
	}
      else
	{
	  RELEASE(old);
	  /* FIXME - need to update files window title etc */
	  return self;
	}
    }
  return nil;
}

- (id) saveDocument: (id)sender
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  if (documentPath == nil || [documentPath isEqualToString: @""])
    {
      return [self saveAsDocument: sender];
    }

  [nc postNotificationName: IBWillSaveDocumentNotification
		    object: self];

  if ([NSArchiver archiveRootObject: self toFile: documentPath] == NO)
    {
      NSRunAlertPanel(NULL, @"Could not save document", 
		       @"OK", NULL, NULL);
      return nil;
    }
  [[resourcesManager window] setDocumentEdited: NO];
  [[resourcesManager window] setTitleWithRepresentedFilename: documentPath];

  [nc postNotificationName: IBWillSaveDocumentNotification
		    object: self];
  return self;
}

- (void) setDocumentActive: (BOOL)flag
{
  NSEnumerator	*enumerator = [nameTable objectEnumerator];
  Class		winClass = [NSWindow class];
  id		obj;

  if (flag == YES)
    {
      while ((obj = [enumerator nextObject]) != nil)
	{
	  if ([obj isKindOfClass: winClass] == YES)
	    {
	      [obj orderFront: self];
	    }
	}
      [[resourcesManager window] orderFront: self];
    }
  else
    {
      while ((obj = [enumerator nextObject]) != nil)
	{
	  if ([obj isKindOfClass: winClass] == YES)
	    {
	      [obj orderOut: self];
	    }
	}
      [[resourcesManager window] orderOut: self];
    }
}

- (void) setSelectionFromEditor: (id<IBEditors>)anEditor
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName: IBSelectionChangedNotification
		    object: anEditor];
}

- (void) touch
{
  [[resourcesManager window] setDocumentEdited: YES];
}

@end

