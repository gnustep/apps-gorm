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
- (NSString*) inspectorClassName
{
  return @"GormNotApplicableInspector";
}
- (NSString*) connectInspectorClassName
{
  return @"GormNotApplicableInspector";
}
- (NSString*) sizeInspectorClassName
{
  return @"GormNotApplicableInspector";
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

static NSImage	*objectsImage = nil;
static NSImage	*imagesImage = nil;
static NSImage	*soundsImage = nil;
static NSImage	*classesImage = nil;

+ (void) initialize
{
  if (self == [GormDocument class])
    {
      NSBundle	*bundle;
      NSString	*path;

      bundle = [NSBundle mainBundle];
      path = [bundle pathForImageResource: @"GormObject"];
      if (path != nil)
	{
	  objectsImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormImage"];
      if (path != nil)
	{
	  imagesImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormSound"];
      if (path != nil)
	{
	  soundsImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormClass"];
      if (path != nil)
	{
	  classesImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
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
  /*
   * Make sure that there is a name for this object.
   */
  if ([self nameForObject: anObject] == nil)
    {
      [self setName: nil forObject: anObject];
    }
  /*
   * Add top-level objects to objectsView and open their editors.
   */
  if ([anObject isKindOfClass: [NSWindow class]] == YES
    || [anObject isKindOfClass: [NSMenu class]] == YES)
    {
      [objectsView addObject: anObject];
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

- (void) beginArchiving
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  id			obj;

  /*
   * Map all connector sources and destinations to their name strings.
   * Deactivate editors so they won't be archived.
   */
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      if ([con isKindOfClass: [GormObjectToEditor class]] == YES)
	{
	  [savedEditors addObject: con];
	  [[con destination] deactivate];
	}
      else if ([con isKindOfClass: [GormEditorToParent class]] == YES)
	{
	  [savedEditors addObject: con];
	}
      else
	{
	  NSString	*name;

	  obj = [con source];
	  name = [self nameForObject: obj];
	  [con setSource: name];
	  obj = [con destination];
	  name = [self nameForObject: obj];
	  [con setDestination: name];
	}
    }
  [connections removeObjectsInArray: savedEditors];

  /*
   * Remove objects and connections that shouldn't be archived.
   */
  [nameTable removeObjectForKey: @"NSOwner"];
  [nameTable removeObjectForKey: @"NSFirst"];
  if (fontManager != nil)
    {
      [nameTable removeObjectForKey: @"NSFont"];
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

- (void) pasteboardChangedOwner: (NSPasteboard*)sender
{
  NSLog(@"Owner changed for %@", sender);
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [window setDelegate: nil];
  [window performClose: self];
  RELEASE(window);
  RELEASE(filesOwner);
  RELEASE(firstResponder);
  RELEASE(fontManager);
  NSFreeMapTable(objToName);
  RELEASE(documentPath);
  RELEASE(savedEditors);
  [super dealloc];
}

- (void) detachObject: (id)anObject
{
  NSString	*name = [self nameForObject: anObject];
  unsigned	count;

  [[self editorForObject: anObject create: NO] close];

  count = [connections count];
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
      [objectsView removeObject: anObject];
    }
  /*
   * Make sure this object isn't in the list of objects to be made visible
   * on nib loading.
   */
  [self setObject: anObject isVisibleAtLaunch: NO];

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

- (void) editor: (id<IBEditors>)anEditor didCloseForObject: (id)anObject
{
  NSArray		*links;

  /*
   * If there is a link from this editor to a parent, remove it.
   */
  links = [self connectorsForSource: anEditor
			    ofClass: [GormEditorToParent class]];
  NSAssert([links count] < 2, NSInternalInconsistencyException);
  if ([links count] == 1)
    {
      [connections removeObjectIdenticalTo: [links objectAtIndex: 0]];
    }

  /*
   * Remove the connection linking the object to this editor
   */
  links = [self connectorsForSource: anObject
			    ofClass: [GormObjectToEditor class]];
  NSAssert([links count] < 2, NSInternalInconsistencyException);
  [connections removeObjectIdenticalTo: [links objectAtIndex: 0]];

  /*
   * Make sure that this editor is not the selection owner.
   */
  if ([(id<IB>)NSApp selectionOwner] == anEditor)
    {
      [self resignSelectionForEditor: anEditor];
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
      if (anEditor == nil)
	{
	  /*
	   * By default all editors are owned by the top-level editor of
	   * the document.
           */
	  anEditor = objectsView;
	}
      if (anEditor != editor)
	{
	  /*
	   * Link to the parent of the editor.
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
      return [[links lastObject] destination];
    }
}

- (void) endArchiving
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  id			obj;

  /*
   * Restore removed objects.
   */
  [nameTable setObject: filesOwner forKey: @"NSOwner"];
  [nameTable setObject: firstResponder forKey: @"NSFirst"];
  if (fontManager != nil)
    {
      [nameTable setObject: fontManager forKey: @"NSFont"];
    }

  /*
   * Map all connector source and destination names to their objects.
   */
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSString	*name;

      name = (NSString*)[con source];
      obj = [self objectForName: name];
      [con setSource: obj];
      name = (NSString*)[con destination];
      obj = [self objectForName: name];
      [con setDestination: obj];
    }

  /*
   * Restore editor links and reactivate the editors.
   */
  [connections addObjectsFromArray: savedEditors];
  enumerator = [savedEditors objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      [[con destination] activate];
    }
  [savedEditors removeAllObjects];
}

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];

  if ([name isEqual: NSWindowWillCloseNotification] == YES)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSEnumerator	*enumerator;
      id<IBConnectors>	con;
      id		obj;

      [nc postNotificationName: IBWillCloseDocumentNotification
			object: self];

      [self setDocumentActive: NO];

      /*
       * Destroy all windows in this document before we go away.
       */
      enumerator = [nameTable objectEnumerator];
      while ((obj = [enumerator nextObject]) != nil)
	{
	  if ([obj isKindOfClass: [NSWindow class]] == YES)
	    {
	      [obj setReleasedWhenClosed: YES];
	      [obj close];
	    }
	}

      /*
       * Close all editors.
       */
      enumerator = [[NSArray arrayWithArray: connections] objectEnumerator];
      while ((con = [enumerator nextObject]) != nil)
	{
	  if ([con isKindOfClass: [GormObjectToEditor class]] == YES)
	    {
	      [[con destination] close];
	    }
	}

      /*
       * Remove objects from document.
       */
      [connections removeAllObjects];
      [nameTable removeAllObjects];
      NSResetMapTable(objToName);
      DESTROY(documentPath);
    }
  else if ([name isEqual: NSWindowDidBecomeKeyNotification] == YES)
    {
      [self setDocumentActive: YES];
    }
  else if ([name isEqual: NSWindowWillMiniaturizeNotification] == YES)
    {
      [self setDocumentActive: NO];
    }
  else if ([name isEqual: NSWindowDidDeminiaturizeNotification] == YES)
    {
      [self setDocumentActive: YES];
    }
  else if ([name isEqual: IBWillBeginTestingInterfaceNotification] == YES)
    {
      if ([window isVisible] == YES)
	{
	  hiddenDuringTest = YES;
	  [window setExcludedFromWindowsMenu: YES];
	  [window orderOut: self];
	  /*
	   * If this is the active document, we must replace the main menu with
	   * our own version using a modified 'Quit' item (to end testing).
	   * and we should try to make one of our windows key.
	   */
	  if ([(id<IB>)NSApp activeDocument] == self)
	    {
	      NSWindow		*keyWindow = nil;
	      NSMenu		*testMenu = nil;
	      NSMenuItem	*item;
	      NSArray		*links;
	      NSEnumerator	*e;
	      NSNibConnector	*con;

	      [connections makeObjectsPerform: @selector(establishConnection)];
	      /*
	       * Get links for all the top-level objects
	       */
	      links = [self connectorsForDestination: filesOwner
					     ofClass: [NSNibConnector class]];
	      e = [links objectEnumerator];
	      while ((con = [e nextObject]) != nil)
		{
		  id	obj = [con source];

		  if ([obj isKindOfClass: [NSMenu class]] == YES)
		    {
		      testMenu = obj;
		    }
		  else if ([obj isKindOfClass: [NSWindow class]] == YES)
		    {
		      if (keyWindow == nil || [keyWindow isVisible] == NO)
			{
			  keyWindow = obj;
			}
		    }
		}

	      if (testMenu == nil)
		{
		  testMenu = [[NSMenu alloc] initWithTitle: @"Test"];
		  AUTORELEASE(testMenu);
		}
	      item = [testMenu itemWithTitle: @"Quit"];
	      if (item != nil)
		{
		  quitItem = RETAIN(item);
		  [testMenu removeItem: item];
		}
	      [testMenu addItemWithTitle: @"Quit" 
				  action: @selector(endTesting:)
			   keyEquivalent: @"q"];	
	      savedMenu = RETAIN([NSApp mainMenu]);
	      [NSApp setMainMenu: testMenu];
	      [keyWindow makeKeyAndOrderFront: self];
	      RELEASE(testMenu);
	    }
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if (hiddenDuringTest == YES)
	{
	  hiddenDuringTest = NO;
	  /*
	   * If this is the active document, we must restore the main menu
	   * and restore the 'Quit' menu item (which was used to end testing)
	   * to its original value.
	   */
	  if ([(id<IB>)NSApp activeDocument] == self)
	    {
	      NSMenu		*testMenu = [NSApp mainMenu];
	      NSMenuItem	*item = [testMenu itemWithTitle: @"Quit"];

	      [testMenu removeItem: item];
	      if (quitItem != nil)
		{
		  [testMenu addItem: quitItem];
		  DESTROY(quitItem);
		}
	      /*
	       * restore the main menu.
	       */
	      [NSApp setMainMenu: savedMenu];
	      DESTROY(savedMenu);
	    }
	  [window orderFront: self];
	  [window setExcludedFromWindowsMenu: NO];
	}
    }
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSRect			winrect = NSMakeRect(100,100,340,252);
      NSRect			selectionRect = {{0, 188}, {240, 64}};
      NSRect			scrollRect = {{0, 0}, {340, 188}};
      NSRect			mainRect = {{20, 0}, {320, 188}};
      NSImage			*image;
      NSButtonCell		*cell;
      unsigned			style;

      objToName = NSCreateMapTableWithZone(NSNonRetainedObjectMapKeyCallBacks,
	NSNonRetainedObjectMapValueCallBacks, 128, [self zone]);

      savedEditors = [NSMutableArray new];

      style = NSTitledWindowMask | NSClosableWindowMask
	| NSResizableWindowMask | NSMiniaturizableWindowMask;
      window = [[NSWindow alloc] initWithContentRect: winrect
					   styleMask: style 
					     backing: NSBackingStoreRetained
					       defer: NO];
      [window setMinSize: [window frame].size];
      [window setTitle: @"UNTITLED"];

      [window setDelegate: self];

      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowWillCloseNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowDidBecomeKeyNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowWillMiniaturizeNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowDidDeminiaturizeNotification
	       object: window];

      selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
						 mode: NSRadioModeMatrix
					    cellClass: [NSButtonCell class]
					 numberOfRows: 1
				      numberOfColumns: 4];
      [selectionView setTarget: self];
      [selectionView setAction: @selector(changeView:)];
      [selectionView setAutosizesCells: NO];
      [selectionView setCellSize: NSMakeSize(64,64)];
      [selectionView setIntercellSpacing: NSMakeSize(28,0)];
      [selectionView setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];

      if ((image = objectsImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 0];
	  [cell setImage: image];
	  [cell setTitle: @"Objects"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = imagesImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 1];
	  [cell setImage: image];
	  [cell setTitle: @"Images"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = soundsImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 2];
	  [cell setImage: image];
	  [cell setTitle: @"Sounds"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = classesImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 3];
	  [cell setImage: image];
	  [cell setTitle: @"Classes"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      [[window contentView] addSubview: selectionView];
      RELEASE(selectionView);

      scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
      [scrollView setHasVerticalScroller: YES];
      [scrollView setHasHorizontalScroller: NO];
      [scrollView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [[window contentView] addSubview: scrollView];
      RELEASE(scrollView);

      mainRect.origin = NSMakePoint(0,0);
      objectsView = [[GormObjectEditor alloc] initWithObject: nil
						  inDocument: self];
      [objectsView setFrame: mainRect];
      [objectsView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [scrollView setDocumentView: objectsView];
      RELEASE(objectsView);

      /*
       * Set up special-case dummy objects and add them to the objects view.
       */
      filesOwner = [GormFilesOwner new];
      [self setName: @"NSOwner" forObject: filesOwner];
      [objectsView addObject: filesOwner];
      firstResponder = [GormFirstResponder new];
      [self setName: @"NSFirst" forObject: firstResponder];
      [objectsView addObject: firstResponder];
      fontManager = [GormFontManager new];
      [self setName: @"NSFont" forObject: fontManager];

      /*
       * Watch to see when we are starting/ending testing.
       */
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBWillBeginTestingInterfaceNotification
	       object: nil];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBWillEndTestingInterfaceNotification
	       object: nil];
    }
  return self;
}

- (BOOL) isActive
{
  return isActive;
}

- (NSString*) nameForObject: (id)anObject
{
  return (NSString*)NSMapGet(objToName, (void*)anObject);
}

- (id) objectForName: (NSString*)name
{
  return [nameTable objectForKey: name];
}

- (BOOL) objectIsVisibleAtLaunch: (id)anObject
{
  return [[nameTable objectForKey: @"NSVisible"] containsObject: anObject];
}

- (NSArray*) objects
{
  return [nameTable allValues];
}

/*
 * NB. This assumes we have an empty document to start with - the loaded
 * document is merged in to it.
 */
- (id) loadDocument: (NSString*)aFile
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSMutableDictionary	*nt;
  NSData		*data;
  NSUnarchiver		*u;
  GSNibContainer	*c;
  NSEnumerator		*enumerator;
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

      if ([obj isKindOfClass: [NSMenu class]] == YES)
	{
	  [objectsView addObject: obj];
	  if ([name isEqual: @"NSMenu"] == YES)
	    {
	      NSRect	frame = [[NSScreen mainScreen] frame];

	      [[obj window] setFrameTopLeftPoint:
		NSMakePoint(1, frame.size.height-200)];
	      [[self openEditorForObject: obj] activate];
	    }
	}
      else if ([obj isKindOfClass: [NSWindow class]] == YES)
	{
	  [objectsView addObject: obj];
	  [[self openEditorForObject: obj] activate];
	}
    }

  /*
   * Finally, we set our new file name
   */
  ASSIGN(documentPath, aFile);
  [window setTitleWithRepresentedFilename: documentPath];
  [nc postNotificationName: IBDidOpenDocumentNotification
		    object: self];
  return self;
}

/*
 * NB. This assumes we have an empty document to start with - the loaded
 * document is merged in to it.
 */
- (id) openDocument: (id)sender
{
  NSArray	*fileTypes;
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OpenNibs"] == YES)
    {
      fileTypes = [NSArray arrayWithObjects: @"gorm", @"nib", nil];
    }
  else
    {
      fileTypes = [NSArray arrayWithObjects: @"gorm", nil];
    }
  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      return [self loadDocument: [oPanel filename]];
    }
  return nil;		/* Failed	*/
}

- (id<IBEditors>) openEditorForObject: (id)anObject
{
  id<IBEditors>	e = [self editorForObject: anObject create: YES];
  id<IBEditors>	p = [self parentEditorForEditor: e];
  
  if (p != nil && p != objectsView)
    {
      [self openEditorForObject: [p editedObject]];
    }
  [e orderFront];
  [[e window] makeKeyAndOrderFront: self];
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
  NSData	*data;
  NSArray	*objects;
  NSEnumerator	*enumerator;
  NSPoint	filePoint;
  NSPoint	screenPoint;

  data = [aPasteboard dataForType: aType];
  if (data == nil)
    {
      NSLog(@"Pasteboard %@ doesn't contain data of %@", aPasteboard, aType);
      return nil;
    }
  objects = [NSUnarchiver unarchiveObjectWithData: data];
  enumerator = [objects objectEnumerator];
  filePoint = [window mouseLocationOutsideOfEventStream];
  screenPoint = [window convertBaseToScreen: filePoint];

  /*
   * Windows and panels are a special case - they need to be set to be
   * visible at launch time (by default), and for a multiple window paste,
   * the windows need to be positioned so they are not on top of each other.
   */
  if ([aType isEqualToString: IBWindowPboardType] == YES)
    {
      NSWindow	*win;

      while ((win = [enumerator nextObject]) != nil)
	{
	  [self setObject: win isVisibleAtLaunch: YES];
	  [win setFrameTopLeftPoint: screenPoint];
	  screenPoint.x += 10;
	  screenPoint.y -= 10;
	}
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
   * find (if any).
   */
  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c class] == editClass)
	{
	  id<IBEditors>	e = [c destination];

	  if (e != editor && [e wantsSelection] == YES)
	    {
	      [e activate];
	      [self setSelectionFromEditor: e];
	      return;
	    }
	}
    }
  /*
   * No editor available to take the selection - set a nil owner.
   */
  [self setSelectionFromEditor: nil];
}

- (void) setupDefaults: (NSString*)type
{
  if (hasSetDefaults == YES)
    {
      return;
    }
  hasSetDefaults = YES;
  if ([type isEqual: @"Application"] == YES)
    {
      NSMenu	*aMenu = [NSMenu new];
      NSWindow	*aWindow;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask
                        | NSResizableWindowMask | NSMiniaturizableWindowMask;

      aWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,600, 400)
					    styleMask: style
					      backing: NSBackingStoreRetained
						defer: NO];
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: @"My Window"];
      [self attachObject: aWindow toParent: nil];
      RELEASE(aWindow);

      [aMenu setTitle: @"Main Menu"];
      [aMenu addItemWithTitle: @"Hide" 
		       action: @selector(hide:)
		keyEquivalent: @"h"];	
      [aMenu addItemWithTitle: @"Quit" 
		       action: @selector(terminate:)
		keyEquivalent: @"q"];	
      [self setName: @"NSMenu" forObject: aMenu];
      [self attachObject: aMenu toParent: nil];
      [[aMenu window] setFrameTopLeftPoint:
	NSMakePoint(1, frame.size.height-200)];
      RELEASE(aMenu);
    }
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
  if ([objectsView containsObject: object] == YES)
    {
      [objectsView refreshCells];
    }
}

- (void) setObject: (id)anObject isVisibleAtLaunch: (BOOL)flag
{
  NSMutableArray	*a = [nameTable objectForKey: @"NSVisible"];

  if (flag == YES)
    {
      if (a == nil)
	{
	  a = [NSMutableArray new];
	  [nameTable setObject: a forKey: @"NSVisible"];
	  RELEASE(a);
	}
      if ([a containsObject: anObject] == NO)
	{
	  [a addObject: anObject];
	}
    }
  else
    {
      [a removeObject: anObject];
    }
}

/*
 * To revert to a saved version, we actually load a new document and
 * close the original document, returning the id of the new document.
 */
- (id) revertDocument: (id)sender
{
  GormDocument	*reverted = AUTORELEASE([GormDocument new]);

  if ([reverted loadDocument: documentPath] != nil)
    {
      NSRect	frame = [window frame];

      [window setReleasedWhenClosed: YES];
      [window close];
      [[reverted window] setFrame: frame display: YES];
      return reverted;
    }
  return nil;
}

- (id) saveAsDocument: (id)sender
{
  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
  NSSavePanel		*sp;
  int			result;

  sp = [NSSavePanel savePanel];

  if ([defs boolForKey: @"SaveAsNib"] == YES)
    {
      [sp setRequiredFileType: @"nib"];
    }
  else
    {
      [sp setRequiredFileType: @"gorm"];
    }

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
  BOOL			archiveResult;

  if (documentPath == nil)
    {
      return [self saveAsDocument: sender];
    }

  [nc postNotificationName: IBWillSaveDocumentNotification
		    object: self];

  [self beginArchiving];

  archiveResult = [NSArchiver archiveRootObject: self toFile: documentPath];

  [self endArchiving];

  if (archiveResult == NO)
    {
      NSRunAlertPanel(NULL, @"Could not save document", 
		       @"OK", NULL, NULL);
      return nil;
    }

  [window setDocumentEdited: NO];
  [window setTitleWithRepresentedFilename: documentPath];

  [nc postNotificationName: IBDidSaveDocumentNotification
		    object: self];
  return self;
}

- (void) setDocumentActive: (BOOL)flag
{
  if (flag != isActive)
    {
      NSEnumerator	*enumerator;
      id		obj;

      enumerator = [nameTable objectEnumerator];
      if (flag == YES)
	{
	  [(GormDocument*)[(id<IB>)NSApp activeDocument] setDocumentActive: NO];
	  isActive = YES;
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderFront: self];
		}
	      else if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  [obj display];
		}
	    }
	}
      else
	{
	  isActive = NO;
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderOut: self];
		}
	      else if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  [obj close];
		}
	    }
	}
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
  [window setDocumentEdited: YES];
}

- (NSWindow*) windowAndRect: (NSRect*)r forObject: (id)object
{
  /*
   * Get the window and rectangle for which link markup should be drawn.
   */
  if ([objectsView containsObject: object] == YES)
    {
      /*
       * objects that exist in the document objects view must have their link
       * markup drawn there, so we ask the view for the required rectangle.
       */
      *r = [objectsView rectForObject: object];
      return [objectsView window];
    }
  else if ([object isKindOfClass: [NSMenuItem class]] == YES)
    {
      NSArray	*links;
      NSMenu	*menu;
      id	editor;

      /*
       * Menu items must have their markup drawn in the window of the
       * editor of the parent menu.
       */
      links = [self connectorsForSource: object
				ofClass: [NSNibConnector class]];
      menu = [[links lastObject] destination];
      editor = [self editorForObject: menu create: NO];
      *r = [editor rectForObject: object];
      return [editor window];
    }
  else if ([object isKindOfClass: [NSView class]] == YES)
    {
      /*
       * Nowmal view objects just get link markup drawn on them.
       */
      *r = [object convertRect: [object bounds] toView: nil];
      return [object window];
    }
  else
    {
      *r = NSZeroRect;
      return nil;
    }
}

- (NSWindow*) window
{
  return window;
}

- (BOOL) windowShouldClose: (id)sender
{
  if ([window isDocumentEdited] == YES)
    {
      NSString	*msg;
      int	result;

      if (documentPath == nil)
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

@end

