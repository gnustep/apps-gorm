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
 * A private connector for child->parent relationships.
 */
@interface GormConnector : NSNibConnector
@end

@implementation	GormConnector
@end


@implementation GormDocument

- (void) addConnector: (id<IBConnectors>)aConnector
{
  if ([connections indexOfObjectIdenticalTo: aConnector] == NSNotFound)
    {
      [connections addObject: aConnector];
    }
}

- (NSArray*) allConnectors
{
  return AUTORELEASE([connections copy]);
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
      aParent = owner;
    }
  old = [self connectorsForSource: anObject ofClass: [GormConnector class]];
  if ([old count] > 0)
    {
      [[old objectAtIndex: 0] setDestination: aParent];
    }
  else
    {
      GormConnector	*con = [GormConnector new];

      [con setSource: anObject];
      [con setDestination: aParent];
      [self addConnector: (id<IBConnectors>)con];
      RELEASE(con);
    }
  [self setName: nil forObject: anObject];

  if ([anObject isKindOfClass: [NSWindow class]] == YES)
    {
      [resourcesManager addObject: anObject];
    }
  else if ([anObject isKindOfClass: [NSMenu class]] == YES)
    {
      [resourcesManager addObject: anObject];
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
 /* FIXME */
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
  NSFreeMapTable(objToName);
  RELEASE(documentPath);
  RELEASE(owner);
  [super dealloc];
}

- (void) detachObject: (id)anObject
{
  NSString	*name = [self nameForObject: anObject];
  unsigned	count = [connections count];

  while (count-- > 0)
    {
      id<IBConnectors>	con = [connections objectAtIndex: count];

      if ([con destination] == anObject || [con source] == anObject)
	{
	  [connections removeObjectAtIndex: count];
	}
    }
  NSMapRemove(objToName, (void*)anObject);
  if ([anObject isKindOfClass: [NSWindow class]] == YES)
    {
      [resourcesManager removeObject: anObject];
    }
  else if ([anObject isKindOfClass: [NSMenu class]] == YES)
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
  /* FIXME */
  [self notImplemented: _cmd];
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
  /* FIXME */
  [self notImplemented: _cmd];
  return nil;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;

  /*
   * Map all connector sources and destinations to their name strings.
   * The 'owner' dummy object maps to 'NSOwner'.
   * The nil object maps to 'NSFirstResponder'.
   */
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSString	*name;
      id	obj;

      obj = [con source];
      name = [self nameForObject: obj];
      [con setSource: name];
      obj = [con destination];
      name = [self nameForObject: obj];
      [con setDestination: name];
    }

  [super encodeWithCoder: aCoder];

  /*
   * Map all connector source and destination names to their objects.
   * The string 'NSOwner' maps to the 'owner' dummy object.
   * The string 'NSFirstResponder' maps to nil.
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
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      objToName = NSCreateMapTableWithZone(NSNonRetainedObjectMapKeyCallBacks,
	NSNonRetainedObjectMapValueCallBacks, 128, [self zone]);
      owner = [NSObject new];
      resourcesManager = [GormResourcesManager newManagerForDocument: self];
    }
  return self;
}

- (NSString*) nameForObject: (id)anObject
{
  if (anObject == nil)
    {
      return @"NSFirstResponder";
    }
  else if (anObject == owner)
    {
      return @"NSOwner";
    }
  else
    {
      return (NSString*)NSMapGet(objToName, (void*)anObject);
    }
}

- (id) objectForName: (NSString*)name
{
  id	obj = [nameTable objectForKey: name];

  if (obj == nil)
    {
      if ([name isEqualToString: @"NSOwner"] == YES)
	{
	  obj = owner;
	}
    }
  return obj;
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
      NSString		*aFile = [oPanel filename];
      NSData		*data;
      NSUnarchiver	*u;
      GSNibContainer	*c;
      NSEnumerator	*enumerator;
      NSDictionary	*nt;
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
      u = AUTORELEASE([[NSUnarchiver alloc] initForReadingWithData: data]);
/* FIXME - need to handle class replacement here */
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
      [[c nameTable] setObject: owner forKey: @"NSOwner"];
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
      [[c nameTable] removeObjectForKey: @"NSOwner"];

      /*
       * Now we merge the objects from the nib container into our own
       * data structures.
       */
      [connections addObjectsFromArray: [c connections]];
      [nameTable addEntriesFromDictionary: [c nameTable]];

      /*
       * Now we build our reverse mapping information and other initialisation
       */
      NSResetMapTable(objToName);
      enumerator = [nameTable keyEnumerator];
      while ((name = [enumerator nextObject]) != nil)
	{
	  id	obj = [nameTable objectForKey: name];

	  NSMapInsert(objToName, (void*)obj, (void*)name);

	  if ([obj isKindOfClass: [NSWindow class]] == YES)
	    {
	      [resourcesManager addObject: obj];
	    }
	  else if ([obj isKindOfClass: [NSMenu class]] == YES)
	    {
	      [resourcesManager addObject: obj];
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
  /* FIXME */
  [self notImplemented: _cmd];
  return nil;
}

- (id<IBEditors>) parentEditorForEditor: (id<IBEditors>)anEditor
{
  /* FIXME */
  [self notImplemented: _cmd];
  return nil;
}

- (id) parentOfObject: (id)anObject
{
  NSArray		*old;
  id<IBConnectors>	con;

  old = [self connectorsForSource: anObject ofClass: [GormConnector class]];
  con = [old lastObject];
  if (con != nil && [con destination] != owner)
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
	  [win orderFront: self];
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
  /* FIXME */
  [self notImplemented: _cmd];
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
  if ([aName isEqualToString: @"NSOwner"]
    || [aName isEqualToString: @"NSFirstResponder"])
    {
      NSLog(@"Attempt to set object name to '%@' ignored", aName);
      return;
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
  /* FIXME */
  [self notImplemented: _cmd];
}

- (void) touch
{
  [[resourcesManager window] setDocumentEdited: YES];
}

@end

