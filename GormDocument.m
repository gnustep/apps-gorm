/* GormDocument.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2002,2003,2004
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
#include "GormClassManager.h"
#include "GormCustomView.h"
#include "GormOutlineView.h"
#include "GormFunctions.h"
#include "GormFilePrefsManager.h"
#include "GormViewWindow.h"
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSSound.h>
#include <AppKit/NSNibConnector.h>
#include <AppKit/NSNibLoading.h>
#include <GNUstepGUI/GSNibTemplates.h>


@interface GormDisplayCell : NSButtonCell
@end

@implementation	GormDisplayCell
- (void) setShowsFirstResponder: (BOOL)flag
{
  [super setShowsFirstResponder: NO];	// Never show ugly frame round button
}
@end

@interface NSNibConnector (GormExtension)
- (BOOL) isEqual: (id)object;
@end

@implementation NSNibConnector (GormExtension)
- (BOOL) isEqual: (id)object
{
  BOOL result = NO;

  if(self == object)
    {
      result = YES;
    }
  else if([[self source] isEqual: [object source]] &&
     [[self destination] isEqual: [object destination]] &&
     [[self label] isEqual: [object label]] &&
     ([self class] == [object class]))
    {
      result = YES;
    }
  return result;
}
@end

// Internal only
NSString *GSCustomClassMap = @"GSCustomClassMap";

@interface GormDocument (GModel)
- (id) openGModel: (NSString *)path;
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
- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}
- (NSString*) className
{
  return @"FirstResponder";
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
static NSImage  *fileImage = nil;

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
      path = [bundle pathForImageResource: @"Gorm"];
      if (path != nil)
	{
	  fileImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      
      [self setVersion: GNUSTEP_NIB_VERSION];
    }
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      if([NSBundle loadNibNamed: @"GormDocument" owner: self])
	{      
	  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
	  NSRect			scrollRect = {{0, 0}, {340, 188}};
	  NSRect			mainRect = {{20, 0}, {320, 188}};
	  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	  
	  
	  openEditors = [NSMutableArray new];
	  classManager = [[GormClassManager alloc] initWithDocument: self]; 
	  // classEditor = [[GormClassEditor alloc] initWithDocument: self];
	  
	  /*
	   * NB. We must retain the map values (object names) as the nameTable
	   * may not hold identical name objects, but merely equal strings.
	   */
	  objToName = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks,
					       NSObjectMapValueCallBacks, 128, [self zone]);
	  
	  // for saving the editors when the gorm file is persisted.
	  savedEditors = [NSMutableArray new];	  
	  [window setMinSize: [window frame].size];
	  [window setTitle: _(@"UNTITLED")];
	  
	  // observe certain notifications...
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
	  [nc addObserver: self
	      selector: @selector(handleNotification:)
	      name: IBClassNameChangedNotification
	      object: classManager];
	  [nc addObserver: self
	      selector: @selector(handleNotification:)
	      name: IBInspectorDidModifyObjectNotification
	      object: classManager];
	  [nc addObserver: self
	      selector: @selector(handleNotification:)
	      name: GormDidModifyClassNotification
	      object: classManager];
	  [nc addObserver: self
	      selector: @selector(handleNotification:)
	      name: GormDidAddClassNotification
	      object: classManager];
	  [nc addObserver: self
	      selector: @selector(handleNotification:)
	      name: IBWillBeginTestingInterfaceNotification
	      object: nil];
	  [nc addObserver: self
	      selector: @selector(handleNotification:)
	      name: IBWillEndTestingInterfaceNotification
	      object: nil];
	  
	  // objects...
	  mainRect.origin = NSMakePoint(0,0);
	  scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
	  [scrollView setHasVerticalScroller: YES];
	  [scrollView setHasHorizontalScroller: YES];
	  [scrollView setAutoresizingMask:
			NSViewHeightSizable|NSViewWidthSizable];
	  [scrollView setBorderType: NSBezelBorder];
	  
	  objectsView = [[GormObjectEditor alloc] initWithObject: nil
						  inDocument: self];
	  [objectsView setFrame: mainRect];
	  [objectsView setAutoresizingMask:
			 NSViewHeightSizable|NSViewWidthSizable];
	  [scrollView setDocumentView: objectsView];
	  RELEASE(objectsView); 
	  
	  // images...
	  mainRect.origin = NSMakePoint(0,0);
	  imagesScrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
	  [imagesScrollView setHasVerticalScroller: YES];
	  [imagesScrollView setHasHorizontalScroller: YES];
	  [imagesScrollView setAutoresizingMask:
			      NSViewHeightSizable|NSViewWidthSizable];
	  [imagesScrollView setBorderType: NSBezelBorder];
	  
	  imagesView = [[GormImageEditor alloc] initWithObject: nil
						inDocument: self];
	  [imagesView setFrame: mainRect];
	  [imagesView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
	  [imagesScrollView setDocumentView: imagesView];
	  RELEASE(imagesView);
	  
	  // sounds...
	  mainRect.origin = NSMakePoint(0,0);
	  soundsScrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
	  [soundsScrollView setHasVerticalScroller: YES];
	  [soundsScrollView setHasHorizontalScroller: YES];
	  [soundsScrollView setAutoresizingMask:
			      NSViewHeightSizable|NSViewWidthSizable];
	  [soundsScrollView setBorderType: NSBezelBorder];
	  
	  soundsView = [[GormSoundEditor alloc] initWithObject: nil
						inDocument: self];
	  [soundsView setFrame: mainRect];
	  [soundsView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
	  [soundsScrollView setDocumentView: soundsView];
	  RELEASE(soundsView);
	  
	  // classes...
	  classesScrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
	  [classesScrollView setHasVerticalScroller: YES];
	  [classesScrollView setHasHorizontalScroller: NO];
	  [classesScrollView setAutoresizingMask:
			       NSViewHeightSizable|NSViewWidthSizable];
	  [classesScrollView setBorderType: NSBezelBorder];
	  
	  mainRect.origin = NSMakePoint(0,0);
	  classesView = [[GormClassEditor alloc] initWithDocument: self];
	  [classesView setFrame: mainRect];
	  [classesScrollView setDocumentView: classesView];
	  RELEASE(classesView);	  
	  [classesView sizeToFit];
	  
	  /*
	   * Set the objects view as the initial view the user's see on startup.
	   */
	  [selectionBox setContentView: scrollView];
	  
	  /*
	   * Set up special-case dummy objects and add them to the objects view.
	   */
	  filesOwner = [GormFilesOwner new];
	  [self setName: @"NSOwner" forObject: filesOwner];
	  [objectsView addObject: filesOwner];
	  firstResponder = [GormFirstResponder new];
	  [self setName: @"NSFirst" forObject: firstResponder];
	  [objectsView addObject: firstResponder];
	  
	  /*
	   * Set image for this miniwindow.
	   */
	  [window setMiniwindowImage: [(id)filesOwner imageForViewer]];	  
	  hidden = [NSMutableArray new];
	  
	  // retain the file prefs view...
	  RETAIN(filePrefsView);

	  // preload headers...
	  if ([defaults boolForKey: @"PreloadHeaders"])
	    {
	      NSArray *headerList = [defaults arrayForKey: @"HeaderList"];
	      NSEnumerator *en = [headerList objectEnumerator];
	      id obj = nil;
	      
	      while ((obj = [en nextObject]) != nil)
		{
		  NSDebugLog(@"Preloading %@", obj);
		  [classManager parseHeader: (NSString *)obj];
		}
	    }

	  // are we upgrading an archive?
	  isOlderArchive = NO;
	  // document is open...
	  isDocumentOpen = YES;
	}
      else
	{
	  NSLog(@"Couldn't load GormDocument interface.");
	  [NSApp terminate: self];
	}
    }
  return self;
}

- (void) awakeFromNib
{
  // set up the toolbar...
  toolbar = [[NSToolbar alloc] initWithIdentifier: @"GormToolbar"];
  [toolbar setAllowsUserCustomization: NO];
  [toolbar setDelegate: self];
  [window setToolbar: toolbar];
  RELEASE(toolbar);
  [toolbar setUsesStandardBackgroundColor: YES];
}

- (void) addConnector: (id<IBConnectors>)aConnector
{
  if ([connections indexOfObjectIdenticalTo: aConnector] == NSNotFound)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName: IBWillAddConnectorNotification
			object: aConnector];
      [connections addObject: aConnector];
      [nc postNotificationName: IBDidAddConnectorNotification
			object: aConnector];
    }
}

- (NSArray*) allConnectors
{
  return [NSArray arrayWithArray: connections];
}

- (void) _instantiateFontManager
{
  GSNibItem *item = nil;
  
  item = [[GormObjectProxy alloc] initWithClassName: @"NSFontManager"
				  frame: NSMakeRect(0,0,0,0)];
  
  [self setName: @"NSFont" forObject: item];
  [self attachObject: item toParent: nil];
  RELEASE(item);

  // set the holder in the document.
  fontManager = (GormObjectProxy *)item;
  
  // [selectionView selectCellWithTag: 0];
  [selectionBox setContentView: scrollView];
}

- (void) attachObject: (id)anObject toParent: (id)aParent
{
  NSArray	*old;
  BOOL           newObject = NO;

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
      newObject = YES;
      [self setName: nil forObject: anObject];
    }

  /*
   * Add top-level objects to objectsView and open their editors.
   */
  if ([anObject isKindOfClass: [NSWindow class]] ||
      [anObject isKindOfClass: [GSNibItem class]])
    {
      [objectsView addObject: anObject];
      [topLevelObjects addObject: anObject];
      [[self openEditorForObject: anObject] activate];
      if ([anObject isKindOfClass: [NSWindow class]] == YES)
	{
	  [anObject setReleasedWhenClosed: NO];
	}
    }

  /*
   * Add the current menu and any submenus.
   */
  if ([anObject isKindOfClass: [NSMenu class]] == YES)
    {
      BOOL isMainMenu = NO;

      // if there is no main menu and a menu gets added, it
      // will become the main menu.
      if([self objectForName: @"NSMenu"] == nil)
	{
	  [self setName: @"NSMenu" forObject: anObject];
	  [objectsView addObject: anObject];
	  [topLevelObjects addObject: anObject];
	  isMainMenu = YES;
	}
      else
	{
	  if([[anObject title] isEqual: @"Services"] && [self servicesMenu] == nil)
	    {
	      [self setServicesMenu: anObject];
	    }
	  else if([[anObject title] isEqual: @"Windows"] && [self windowsMenu] == nil)
	    {
	      [self setWindowsMenu: anObject];
	    }
	}

      [[self openEditorForObject: anObject] activate];

      // if it's the main menu... locate it appropriately...
      if(isMainMenu)
	{
	  NSRect frame = [window frame];
	  NSPoint origin = frame.origin;

	  origin.y += (frame.size.height + 150);

	  // place the main menu appropriately...
	  [[anObject window] setFrameTopLeftPoint: origin];
	}
    }

  /*
   * if this a scrollview, it is interesting to add its contentview
   * if it is a tableview or a textview
   */
  if (([anObject isKindOfClass: [NSScrollView class]] == YES)
    && ([(NSScrollView *)anObject documentView] != nil))
    {
      if ([[anObject documentView] isKindOfClass: 
				    [NSTableView class]] == YES)
	{
	  int i;
	  int count;
	  NSArray *tc;
	  id tv = [anObject documentView];
	  tc = [tv tableColumns];
	  count = [tc count];
	  [self attachObject: tv toParent: aParent];
	  
	  for (i = 0; i < count; i++)
	    {
	      [self attachObject: [tc objectAtIndex: i]
			toParent: aParent];
	    }
	}
      else if ([[anObject documentView] isKindOfClass: 
					  [NSTextView class]] == YES)
	{
	  [self attachObject: [anObject documentView] toParent: aParent];
	}
    }

  // Detect and add any connection the object might have.
  // This is done so that any palette items which have predefined connections will be
  // shown in the connections list.
  if([anObject respondsToSelector: @selector(action)] == YES &&
     [anObject respondsToSelector: @selector(target)] == YES &&
     newObject == YES)
    {
      SEL sel = [anObject action];

      if(sel != NULL)
	{
	  NSString *label = NSStringFromSelector(sel);
	  id source = anObject;
	  NSNibControlConnector *con = [NSNibControlConnector new];
	  id destination = [anObject target];
	  NSArray *sourceConnections = [self connectorsForSource: source];

	  // if it's a menu item we want to connect it to it's parent...
	  if([anObject isKindOfClass: [NSMenuItem class]] && 
	     [label isEqual: @"submenuAction:"])
	    {
	      destination = aParent;
	    }
	  
	  // if the connection needs to be made with the font manager, replace
	  // it with our proxy object and proceed with creating the connection.
	  if(destination == nil && 
	     [classManager isAction: label ofClass: @"NSFontManager"])
	    {
	      if(!fontManager)
		{
		  // initialize font manager...
		  [self _instantiateFontManager];
		}
	      
	      // set the destination...
	      destination = fontManager;
	    }

	  // if the destination is still nil, back off to the first responder.
	  if(destination == nil)
	    {
	      destination = firstResponder;
	    }

	  // build the connection
	  [con setSource: source];
	  [con setDestination: destination];
	  [con setLabel: label];
	  
	  // don't duplicate the connection if it already exists.
	  // if([sourceConnections indexOfObjectIdenticalTo: con] == NSNotFound)
	  if([sourceConnections containsObject: con] == NO)
	    {
	      // add it to our connections set.
	      [self addConnector: (id<IBConnectors>)con];
	    }

	  // destroy the connection in the object to
	  // prevent any conflict.   The connections are restored when the 
	  // .gorm is loaded, so there's no need for it anymore.
	  [anObject setTarget: nil];
	  [anObject setAction: NULL];

	  // release the connection.
	  RELEASE(con);
	}
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

// sound support
- (GormSound *)_createSoundPlaceHolder: (NSString *)path
{
  NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
  return [[GormSound alloc] initWithName: name path: path];
}

// image support
- (GormImage *)_createImagePlaceHolder: (NSString *)path
{
  NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
  return [[GormImage alloc] initWithName: name path: path];
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

  NSDebugLog(@"*** customClassMap = %@",[classManager customClassMap]);
  [nameTable setObject: [classManager customClassMap] forKey: GSCustomClassMap];

  /*
   * Remove objects and connections that shouldn't be archived.
   */
  NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSOwner"]);
  [nameTable removeObjectForKey: @"NSOwner"];
  NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSFirst"]);
  [nameTable removeObjectForKey: @"NSFirst"];

  /* Add information about the NSOwner to the archive */
  NSMapInsert(objToName, (void*)[filesOwner className], (void*)@"NSOwner");
  [nameTable setObject: [filesOwner className] forKey: @"NSOwner"];

  /*
   * Set the appropriate profile so that we save the right versions of 
   * the classes for older GNUstep releases.
   */
  [filePrefsManager setClassVersions];
}

- (void) changeCurrentClass: (id)sender
{
  int	row = [classesView selectedRow];
  if (row >= 0)
    {
      [classesView setSelectedClassName: [classesView itemAtRow: row]];
      [self setSelectionFromEditor: (id)classesView];
    } 
}

// class selection...
- (void) selectClass: (NSString *)className
{
  NSString	*currentClass = nil;
  NSArray	*classes;
  NSEnumerator	*en;
  int		row = 0;
  
  if(className != nil)
    {
      if([className isEqual: @"CustomView"] || 
	 [className isEqual: @"GormSound"] || 
	 [className isEqual: @"GormImage"])
	{
	  return; // return only if it is a special class name...
	}
    }
  else
    {
      return; // return if it is nil
    }
  
  classes = [[self classManager] allSuperClassesOf: className]; 
  en = [classes objectEnumerator];

  // open the items...
  while ((currentClass = [en nextObject]) != nil)
    {
      [classesView expandItem: currentClass];
    }
  
  // select the item...
  row = [classesView rowForItem: className];
  if (row != NSNotFound)
    {
      [classesView selectRow: row byExtendingSelection: NO];
      [classesView scrollRowToVisible: row];
    }
}

- (void) selectClassWithObject: (id)obj 
{
  NSString *customClass = [classManager customClassForObject: obj];

  if(customClass != nil)
    {
      [self selectClass: customClass];
    }
  else if ([obj respondsToSelector: @selector(className)])
    { 
      [self selectClass: [obj className]];
    }
}

// change the views...
- (void) changeView: (id)sender
{
  int tag = [sender tag];

  switch (tag)
    {
    case 0: // objects
      {
	[selectionBox setContentView: scrollView];
      }
      break;
    case 1: // images
      {
	[selectionBox setContentView: imagesScrollView];
      }
      break;
    case 2: // sounds
      {
	[selectionBox setContentView: soundsScrollView];
      }
      break;
    case 3: // classes
      {
	NSArray *selection =  [[(id<IB>)NSApp selectionOwner] selection];
	[selectionBox setContentView: classesScrollView];
	
	// if something is selected, in the object view.
	// show the equivalent class in the classes view.
	if ([selection count] > 0)
	  {
	    id obj = [selection objectAtIndex: 0];
	    // if it's a scrollview focus on it's contents.
	    if([obj isKindOfClass: [NSScrollView class]])
	      {
		id newobj = nil;
		newobj = [obj documentView];
		if(newobj != nil)
		  {
		    obj = newobj;
		  }
	      }
	    [self selectClassWithObject: obj];
	  }
      }
      break;
    case 4: // file prefs
      {
	[selectionBox setContentView: filePrefsView];
      }
      break;
    }
}

- (GormClassManager*) classManager
{
  return classManager;
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
  NSEnumerator	*enumerator;
  NSMutableSet	*editorSet;
  id		obj;
  NSMutableData	*data;
  NSArchiver    *archiver;

  /*
   * Remove all editors from the selected objects before archiving
   * and restore them afterwards.
   */
  editorSet = [NSMutableSet new];
  enumerator = [anArray objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    {
      id editor = [self editorForObject: obj create: NO];
      if (editor != nil)
	{
	  [editorSet addObject: editor];
	  [editor deactivate];
	}
    }

  // encode the data
  data = [NSMutableData dataWithCapacity: 0];
  archiver = [[NSArchiver alloc] initForWritingWithMutableData: data];
  [archiver encodeClassName: @"GormCustomView" 
	    intoClassName: @"GSCustomView"];
  [archiver encodeRootObject: anArray];

  // reactivate
  enumerator = [editorSet objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    {
      [obj activate];
    }
  RELEASE(editorSet);

  [aPasteboard declareTypes: [NSArray arrayWithObject: aType]
		      owner: self];
  return [aPasteboard setData: data forType: aType];
}

- (id) createSubclass: (id)sender
{
  int		i = [classesView selectedRow];

  if (i >= 0 && ![classesView isEditing])
    {
      NSString	   *newClassName;
      id            itemSelected = [classesView itemAtRow: i];
      
      if([itemSelected isKindOfClass: [NSString class]])
	{
	  if(![itemSelected isEqualToString: @"FirstResponder"])
	    {
	      newClassName = [classManager addClassWithSuperClassName:
					     itemSelected];
	      [classesView reloadData];
	      [classesView expandItem: itemSelected];
	      i = [classesView rowForItem: newClassName]; 
	      [classesView selectRow: i byExtendingSelection: NO];
	      [classesView scrollRowToVisible: i];
	      [self editClass: self];
	    }
	  else
	    {
	      // beep to inform the user of this error.
	      NSBeep();
	    }
	}
    }

  return self;
}

//  For debugging ONLY.
/*
- (id) retain
{
  NSLog(@"Document being retained... %d: %@", [self retainCount], self);
  return [super retain];
}

- (oneway void) release
{
  NSLog(@"Document being released... %d: %@", [self retainCount], self);
  [super release];
}
*/

- (void) pasteboardChangedOwner: (NSPasteboard *)sender
{
  NSDebugLog(@"Owner changed for %@", sender);
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  // close the window...
  [window close];

  // Get rid of the selection box.
  [selectionBox removeFromSuperviewWithoutNeedingDisplay];

  // remove objects from the topLevelObjects set...
  // [topLevelObjects removeAllObjects];

  // release the managers...
  RELEASE(classManager);
  RELEASE(filePrefsManager);
  RELEASE(filePrefsView);

  // release editors...
  RELEASE(classesView);
  RELEASE(savedEditors);
  RELEASE(openEditors);

  // hidden objects...
  RELEASE(hidden);

  if (objToName != 0)
    {
      NSFreeMapTable(objToName);
    }

  // editor views...
  RELEASE(documentPath);
  RELEASE(scrollView);
  RELEASE(classesScrollView);
  RELEASE(soundsScrollView);
  RELEASE(imagesScrollView);

  // windows...
  RELEASE(window);
  RELEASE(filePrefsWindow);
  [super dealloc];
}

- (void) detachObject: (id)anObject
{
  NSString	*name = RETAIN([self nameForObject: anObject]); // released at end of method...
  GormClassManager *cm = [self classManager];
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

  // if the font manager is being reset, zero out the instance variable.
  if([name isEqual: @"NSFont"])
    {
      fontManager = nil;
    }

  if ([anObject isKindOfClass: [NSWindow class]] == YES
    || [anObject isKindOfClass: [NSMenu class]] == YES)
    {
      [objectsView removeObject: anObject];
    }

  // if it's in the top level items array, remove it.
  if([topLevelObjects containsObject: anObject])
    {
      [topLevelObjects removeObject: anObject];
    }

  // eliminate it from being the windows/services menu, if it's being detached.
  if ([anObject isKindOfClass: [NSMenu class]])
    {
      if([self windowsMenu] == anObject)
	{
	  [self setWindowsMenu: nil];
	}
      else if([self servicesMenu] == anObject)
	{
	  [self setServicesMenu: nil];
	}
    }

  /*
   * Make sure this object isn't in the list of objects to be made visible
   * on nib loading.
   */
  [self setObject: anObject isVisibleAtLaunch: NO];

  // some objects are given a name, some are not.  The only ones we need
  // to worry about are those that have names.
  if(name != nil)
    {
      // remove from custom class map...
      NSDebugLog(@"Delete from custom class map -> %@",name);
      [cm removeCustomClassForObject: name];
      if([anObject isKindOfClass: [NSScrollView class]] == YES)
	{
	  NSView *subview = [anObject documentView];
	  NSString *objName = [self nameForObject: subview];
	  NSDebugLog(@"Delete from custom class map -> %@",objName);
	  [cm removeCustomClassForObject: objName];
	}
      
      // remove from name table...
      [nameTable removeObjectForKey: name];
      
      // free...
      NSMapRemove(objToName, (void*)anObject);
      RELEASE(name);
    }
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

- (id) addAttributeToClass: (id)sender
{
  [classesView addAttributeToClass];
  return self;
}

- (id) remove: (id)sender
{
  id anitem;
  int i = [classesView selectedRow];
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  
  // if no selection, then return.
  if (i == -1)
    {
      return self;
    }

  anitem = [classesView itemAtRow: i];
  if ([anitem isKindOfClass: [GormOutletActionHolder class]])
    {
      id itemBeingEdited = [classesView itemBeingEdited];

      // if the class being edited is a custom class, then allow the deletion...
      if ([classManager isCustomClass: itemBeingEdited])
	{
	  NSString *name = [anitem getName];

	  if ([classesView editType] == Actions)
	    {
	      // if this action is an action on the class, not it's superclass
	      // allow the deletion...
	      if ([classManager isAction: name
			       ofClass: itemBeingEdited])
		{
		  BOOL removed = [self removeConnectionsWithLabel: name 
				       forClassNamed: itemBeingEdited
				       isAction: YES];
		  if (removed)
		    {
		      [classManager removeAction: name
				    fromClassNamed: itemBeingEdited];
		      [classesView removeItemAtRow: i];
		      [nc postNotificationName: GormDidModifyClassNotification
			  object: classManager];
		    }
		}
	    }
	  else if ([classesView editType] == Outlets)
	    {
	      // if this outlet is an outlet on the class, not it's superclass
	      // allow the deletion...
	      if ([classManager isOutlet: name
			       ofClass: itemBeingEdited])
		{
		  BOOL removed = [self removeConnectionsWithLabel: name 
				       forClassNamed: itemBeingEdited
				       isAction: NO];
		  if (removed)
		    {
		      [classManager removeOutlet: name
				    fromClassNamed: itemBeingEdited];
		      [classesView removeItemAtRow: i];
		      [nc postNotificationName: GormDidModifyClassNotification
			  object: classManager];
		    }
		}
	    }
	}
    }
  else
    {
      NSArray *subclasses = [classManager subClassesOf: anitem];
      // if the class has no subclasses, then delete.
      if ([subclasses count] == 0)
	{
	  // if the class being edited is a custom class, then allow the deletion...
	  if ([classManager isCustomClass: anitem])
	    {
	      BOOL removed = [self removeConnectionsForClassNamed: anitem];
	      if (removed)
		{
		  [classManager removeClassNamed: anitem];
		  [classesView reloadData];
		  [nc postNotificationName: GormDidModifyClassNotification
		      object: classManager];
		}
	    }
	}
      else
	{
	  NSString *message = [NSString stringWithFormat: 
	    _(@"The class %@ has subclasses which must be removed"), anitem];
	  NSRunAlertPanel(_(@"Problem removing class"), 
			  message,
			  nil, nil, nil);
	}
    }    
  return self;
}

- (id) loadClass: (id)sender
{
  NSArray	*fileTypes = [NSArray arrayWithObjects: @"h", @"H", nil];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      [classManager parseHeader: [oPanel filename]];
      return self;
    }

  return nil;
}

- (id) editClass: (id)sender
{
  [self changeCurrentClass: sender];

  return self;
}

- (id) createClassFiles: (id)sender
{
  NSSavePanel		*sp;
  int                   row = [classesView selectedRow];
  id                    className = [classesView itemAtRow: row];
  int			result;

  if ([className isKindOfClass: [GormOutletActionHolder class]])
    {
      className = [classesView itemBeingEdited];
    }
  
  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: @"m"];
  [sp setTitle: _(@"Save source file as...")];
  if (documentPath == nil)
    {
      result = [sp runModalForDirectory: NSHomeDirectory() 
		   file: [className stringByAppendingPathExtension: @"m"]];
    }
  else
    {
      result = [sp runModalForDirectory: 
		     [documentPath stringByDeletingLastPathComponent]
		   file: [className stringByAppendingPathExtension: @"m"]];
    }

  if (result == NSOKButton)
    {
      NSString *sourceName = [sp filename];
      NSString *headerName;

      [sp setRequiredFileType: @"h"];
      [sp setTitle: _(@"Save header file as...")];
      result = [sp runModalForDirectory: 
		     [sourceName stringByDeletingLastPathComponent]
		   file: 
		     [[[sourceName lastPathComponent]
			stringByDeletingPathExtension] 
		       stringByAppendingString: @".h"]];
      if (result == NSOKButton)
	{
	  headerName = [sp filename];
	  NSDebugLog(@"Saving %@", className);
	  if (![classManager makeSourceAndHeaderFilesForClass: className
			     withName: sourceName
			     and: headerName])
	    {
	      NSRunAlertPanel(_(@"Alert"), 
			      _(@"Could not create the class's file"),
			      nil, nil, nil);
	    }
	  
	  return self;
	}
    }
  return nil;
}

- (void) editor: (id<IBEditors,IBSelectionOwners>)anEditor didCloseForObject: (id)anObject
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
  if ([links count] == 1)
    {
      [connections removeObjectIdenticalTo: [links objectAtIndex: 0]];
    }

  /*
   * Add to the master list of editors for this document
   */
  [openEditors removeObjectIdenticalTo: anEditor];

  /*
   * Make sure that this editor is not the selection owner.
   */
  if ([(id<IB>)NSApp selectionOwner] == 
      anEditor)
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
      Class		eClass = NSClassFromString([anObject editorClassName]);
      id<IBEditors>	editor;
      id<IBConnectors>	link;

      editor = [[eClass alloc] initWithObject: anObject inDocument: self];
      link = [GormObjectToEditor new];
      [link setSource: anObject];
      [link setDestination: editor];
      [connections addObject: link];
      
      if(![openEditors containsObject: editor] && editor != nil)
	{
	  [openEditors addObject: editor];
	}

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
      else
	{
	  NSDebugLog(@"WARNING anEditor = editor");
	}
      [editor activate];
      RELEASE((NSObject *)editor);
      return editor;
    }
  else if ([links count] == 0)
    {
      return nil;
    }
  else
    {
      [[[links lastObject] destination] activate];
      return [[links lastObject] destination];
    }
}

- (void) endArchiving
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  id			obj;

  /*
   * Restore class versions.
   */
  [filePrefsManager restoreClassVersions];

  /*
   * Restore removed objects.
   */
  [nameTable setObject: filesOwner forKey: @"NSOwner"];
  NSMapInsert(objToName, (void*)filesOwner, (void*)@"NSOwner");

  [nameTable setObject: firstResponder forKey: @"NSFirst"];
  NSMapInsert(objToName, (void*)firstResponder, (void*)@"NSFirst");

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
      if ([[con source] isKindOfClass: [NSView class]] == NO)
	[[con destination] activate];
    }
  [savedEditors removeAllObjects];
}

- (void) closeAllEditors
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  NSMutableArray        *editors = [NSMutableArray array];

  // remove the editor connections from the connection array...
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      if ([con isKindOfClass: [GormObjectToEditor class]] == YES)
	{
	  [editors addObject: con];
	}
      else if ([con isKindOfClass: [GormEditorToParent class]] == YES)
	{
	  [editors addObject: con];
	}
    }
  [connections removeObjectsInArray: editors];
  [editors removeAllObjects];

  // Close all of the editors & get all of the objects out.
  // copy the array, since the close method calls editor:didCloseForObject:
  // and would effect the array during the execution of 
  // makeObjectsPerformSelector:.
  [editors addObjectsFromArray: openEditors];
  [editors makeObjectsPerformSelector: @selector(close)]; 
  [openEditors removeAllObjects];
  // [editors makeObjectsPerformSelector: @selector(release)];
  [editors removeAllObjects];

  // Close the editors in the document window...
  // don't worry about the "classesView" since it's not really an
  // editor.
  [objectsView close];
  [imagesView close];
  [soundsView close];
}


- (void) handleNotification: (NSNotification*)aNotification
{
  NSString *name = [aNotification name];
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  if ([name isEqual: NSWindowWillCloseNotification] == YES)
    {
      NSEnumerator	*enumerator;
      id		obj;
      
      enumerator = [nameTable objectEnumerator];
      while ((obj = [enumerator nextObject]) != nil)
	{
	  /*
	  if ([obj isKindOfClass: [NSMenu class]] == YES)
	    {
	      if ([[obj window] isVisible] == YES)
		{
		  [obj close];
		}
	    }
	    else 
	  */
	  if ([obj isKindOfClass: [NSWindow class]] == YES)
	    {
	      [obj setReleasedWhenClosed: YES];
	      [obj close];
	    }
	}

      // deactivate the document...
      [self setDocumentActive: NO];
      [self setSelectionFromEditor: nil];
      [self closeAllEditors]; // shut down all of the editors..
      [nc postNotificationName: IBWillCloseDocumentNotification object: self];
      [nc removeObserver: self]; // stop listening to all notifications.
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
	  [hidden addObject: window];
	  [window setExcludedFromWindowsMenu: YES];
	  [window orderOut: self];
	}
      if ([(id<IB>)NSApp activeDocument] == self)
	{
	  NSEnumerator	*enumerator;
	  id		obj;

	  enumerator = [nameTable objectEnumerator];
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  if ([[obj window] isVisible] == YES)
		    {
		      [hidden addObject: obj];
		      [obj close];
		    }
		}
	      else if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  if ([obj isVisible] == YES)
		    {
		      [hidden addObject: obj];
		      [obj orderOut: self];
		    }
		}
	    }
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if ([hidden count] > 0)
	{
	  NSEnumerator	*enumerator;
	  id		obj;

	  enumerator = [hidden objectEnumerator];
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  [obj display];
		}
	      else if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderFront: self];
		}
	    }
	  [hidden removeAllObjects];
	  [window setExcludedFromWindowsMenu: NO];
	}
    }
  else if ([name isEqual: IBClassNameChangedNotification] == YES)
    {
      [classesView reloadData];
      [self touch];
    }
  else if ([name isEqual: IBInspectorDidModifyObjectNotification] == YES)
    {
      [classesView reloadData];
      [self touch];
    }
  else if ([name isEqual: GormDidModifyClassNotification] == YES)
    {
      if ([classesView isEditing] == NO) 
	{
	  [classesView reloadData];
	}
    }
  else if ([name isEqual: GormDidAddClassNotification])
    {
      // go to the class which was just loaded in the classes view...
      [classesView reloadData];
      [selectionBox setContentView: classesScrollView];
    }
}

- (id) instantiateClass: (id)sender
{
  int i = [classesView selectedRow];
  
  if (i >= 0)
    {
      id object = [classesView itemAtRow: i];
      GSNibItem *item = nil;
      
      if([object isKindOfClass: [NSString class]])
	{
	  if([object isEqualToString: @"FirstResponder"])
	    return nil;

	  if([classManager isSuperclass: @"NSView" linkedToClass: object] ||
	     [object isEqual: @"NSView"])
	    {
	      Class cls;
	      NSString *className = object;
	      BOOL isCustom = [classManager isCustomClass: object];
	      id instance;

	      if(isCustom)
		{
		  className = [classManager nonCustomSuperClassOf: object];
		}

	      // instantiate the object or it's substitute...
	      cls = NSClassFromString(className);
	      if([cls respondsToSelector: @selector(allocSubstitute)])
		{
		  instance = [cls allocSubstitute];
		}
	      else
		{
		  instance = [cls alloc];
		}

	      // give it some initial dimensions...
	      if([instance respondsToSelector: @selector(initWithFrame:)])
		{
		  instance = [instance initWithFrame: NSMakeRect(10,10,380,280)];
		}
	      else
		{
		  instance = [instance init];
		}

	      // add it to the top level objects...
	      [self setName: nil forObject: instance];
	      [self attachObject: instance toParent: nil];
	      [topLevelObjects addObject: instance];
	      [objectsView addObject: instance];

	      // we want to record if it's custom or not and act appropriately...
	      if(isCustom)
		{
		  NSString *name = [self nameForObject: instance];
		  [classManager setCustomClass: object
				forObject: name];
		}

	      [selectionBox setContentView: scrollView];
	      NSLog(@"Instantiate NSView subclass %@",object);	      
	    }
	  else
	    {
	      item = [[GormObjectProxy alloc] initWithClassName: object
					      frame: NSMakeRect(0,0,0,0)];
	      
	      [self setName: nil forObject: item];
	      [self attachObject: item toParent: nil];
	      
	      [selectionBox setContentView: scrollView];
	    }
	}
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

- (BOOL) classIsSelected
{
  int i = [classesView selectedRow];
  BOOL result = NO;

  if (i >= 0 && i <= ([classesView numberOfRows] - 1))
    {
      id object = [classesView itemAtRow: i];
      if([object isKindOfClass: [NSString class]])
	{
	  result = YES;
	}
    }

  return result;
}

// The sole purpose of this method is to clean up .gorm files from older
// versions of Gorm which might have some dangling references.   This method
// should possibly added to as time goes on to make sure that it's possible 
// to repair old .gorm files.
- (void) _repairFile
{
  NSEnumerator *en = [[nameTable allKeys] objectEnumerator];
  NSString *key = nil;

  while((key = [en nextObject]) != nil)
  {
    id obj = [nameTable objectForKey: key];
    if([obj isKindOfClass: [NSMenu class]] && ![key isEqual: @"NSMenu"])
      {
	id sm = [obj supermenu];
	if(sm == nil)
	  {
	    NSArray *menus = findAll(obj);
	    NSLog(@"Found and removed a dangling menu %@, %@.",obj,[self nameForObject: obj]);
	    [self detachObjects: menus];
	    [self detachObject: obj];
	    
	    // Since the menu is a top level object, it is not retained by
	    // anything else.  When it was unarchived it was autoreleased, and
	    // the detach also does a release.  Unfortunately, this causes a
	    // crash, so this extra retain is only here to stave off the 
	    // release, so the autorelease can release the menu when it should.
	    RETAIN(obj); // extra retain to stave off autorelease...
	  }
      }

    if([obj isKindOfClass: [NSMenuItem class]])
      {
	id m = [obj menu];
	if(m == nil)
	  {
	    id sm = [obj submenu];

	    NSLog(@"Found and removed a dangling menu item %@, %@.",obj,[self nameForObject: obj]);
	    [self detachObject: obj];

	    // if there are any submenus, detach those as well.
	    if(sm != nil)
	      {
		NSArray *menus = findAll(sm);
		[self detachObjects: menus];
	      }
	  }
      }
  }
}

/*
 * NB. This assumes we have an empty document to start with - the loaded
 * document is merged in to it.
 */
- (id) loadDocument: (NSString*)aFile
{
  NS_DURING
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSMutableDictionary	*nt;
      NSMutableDictionary	*cc;
      NSData		        *data;
      NSUnarchiver		*u;
      GSNibContainer	        *c;
      NSEnumerator		*enumerator;
      id <IBConnectors>	         con;
      NSString                  *ownerClass, *key;
      NSFileManager	        *mgr = [NSFileManager defaultManager];
      BOOL                       isDir = NO;
      NSDirectoryEnumerator     *dirEnumerator;
      BOOL                       repairFile = [[NSUserDefaults standardUserDefaults] boolForKey: @"GormRepairFileOnLoad"];
      NSMenu                    *mainMenu;

      if ([mgr fileExistsAtPath: aFile isDirectory: &isDir])
	{
	  // if the data is in a directory, then load from objects.gorm 
	  if (isDir == NO)
	    {
	      NSString *lastComponent = [aFile lastPathComponent];
	      NSString *parent = [aFile stringByDeletingLastPathComponent];
	      NSString *parentExt = [parent pathExtension];
	      
	      // test if we're doing it wrong...
	      if([lastComponent isEqual: @"objects.gorm"] && 
		 [parentExt isEqual: @"gorm"])
		{
		  NSRunAlertPanel(NULL,
				  _(@"Cannot load directly from objects.gorm file, please load from the gorm package."),
				  @"OK", NULL, NULL);
		  return nil;
		}
	      
	      data = [NSData dataWithContentsOfFile: aFile];
	      NSDebugLog(@"Loaded data from file...");
	    }
	  else
	    {
	      NSString *newFileName;
	      
	      newFileName = [aFile stringByAppendingPathComponent: @"objects.gorm"];
	      data = [NSData dataWithContentsOfFile: newFileName];
	      NSDebugLog(@"Loaded data from %@...", newFileName);
	    }
	}
      else
	{
	  // no file exists...
	  data = nil;
	}
      
      // check the data...
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
      u = [[NSUnarchiver alloc] initForReadingWithData: data];
      
      // classes
      [u decodeClassName: @"GSNibContainer" 
	 asClassName: @"GormDocument"];
      [u decodeClassName: @"GSNibItem" 
	 asClassName: @"GormObjectProxy"];
      [u decodeClassName: @"GSCustomView" 
	 asClassName: @"GormCustomView"];
      [u decodeClassName: @"NSMenu" 
	 asClassName: @"GormNSMenu"];
      [u decodeClassName: @"NSWindow" 
	 asClassName: @"GormNSWindow"];
      [u decodeClassName: @"NSPanel" 
	 asClassName: @"GormNSPanel"];
      [u decodeClassName: @"NSPopUpButton" 
	 asClassName: @"GormNSPopUpButton"];
      [u decodeClassName: @"NSPopUpButtonCell"
	 asClassName: @"GormNSPopUpButtonCell"];
      [u decodeClassName: @"NSBrowser" 
	 asClassName: @"GormNSBrowser"];
      [u decodeClassName: @"NSTableView" 
	 asClassName: @"GormNSTableView"];
      [u decodeClassName: @"NSOutlineView" 
	 asClassName: @"GormNSOutlineView"];
      
      c = [u decodeObject];
      if (c == nil || [c isKindOfClass: [GSNibContainer class]] == NO)
	{
	  NSRunAlertPanel(NULL, _(@"Could not unarchive document data"), 
			  _(@"OK"), NULL, NULL);
	  return nil;
	}
      
      // retrieve the custom class data...
      cc = [[c nameTable] objectForKey: GSCustomClassMap];
      if (cc == nil)
	{
	  cc = [NSMutableDictionary dictionary]; // create an empty one.
	  [[c nameTable] setObject: cc forKey: GSCustomClassMap];
	}
      [classManager setCustomClassMap: cc];
      NSDebugLog(@"cc = %@", cc);
      NSDebugLog(@"customClasses = %@", [classManager customClassMap]);
      
      // convert from old file format...
      if (isDir == NO)
	{
	  NSString	*s;
	  
	  s = [aFile stringByDeletingPathExtension];
	  s = [s stringByAppendingPathExtension: @"classes"];
	  if (![classManager loadCustomClasses: s])
	    {
	      NSRunAlertPanel(NULL, _(@"Could not open the associated classes file.\n"
				      @"You won't be able to edit connections on custom classes"), 
			      _(@"OK"), NULL, NULL);
	    }
	}
      else
	{
	  NSString	*s;
	  
	  s = [aFile stringByAppendingPathComponent: @"data.classes"];
	  if (![classManager loadCustomClasses: s]) 
	    {
	      NSRunAlertPanel(NULL, _(@"Could not open the associated classes file.\n"
				      @"You won't be able to edit connections on custom classes"), 
			      _(@"OK"), NULL, NULL);
	    }

	  s = [aFile stringByAppendingPathComponent: @"data.info"];
	  if (![filePrefsManager loadFromFile: s])
	    {
	      NSLog(@"Loading gorm without data.info file.  Default settings will be assumed.");
	    }
	}
      
      [classesView reloadData];
      
      /*
       * In the newly loaded nib container, we change all the connectors
       * to hold the objects rather than their names (using our own dummy
       * object as the 'NSOwner'.
       */
      ownerClass = [[c nameTable] objectForKey: @"NSOwner"];
      if (ownerClass)
	[filesOwner setClassName: ownerClass];
      [[c nameTable] setObject: filesOwner forKey: @"NSOwner"];
      [[c nameTable] setObject: firstResponder forKey: @"NSFirst"];
      
      /* Iterate over the contents of nameTable and create the connections */
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
       * If the .gorm file is version 0, we need to add the top level objects
       * to the list so that they can be properly processed.
       */
      if([u versionForClassName: NSStringFromClass([GSNibContainer class])] == 0)
	{
	  id obj;
	  NSEnumerator *en = [nt objectEnumerator];

	  // get all of the GSNibItem subclasses which could be top level objects
	  while((obj = [en nextObject]) != nil)
	    {
	      if([obj isKindOfClass: [GSNibItem class]] &&
		 [obj isKindOfClass: [GSCustomView class]] == NO)
		{
		  [topLevelObjects addObject: obj];
		}
	    }
	  isOlderArchive = YES;
	}

      /*
       * Now we merge the objects from the nib container into our own data
       * structures, taking care not to overwrite our NSOwner and NSFirst.
       */
      [nt removeObjectForKey: @"NSOwner"];
      [nt removeObjectForKey: @"NSFirst"];
      [topLevelObjects addObjectsFromArray: [[c topLevelObjects] allObjects]];
      [connections addObjectsFromArray: [c connections]];
      [nameTable addEntriesFromDictionary: nt];
      [self rebuildObjToNameMapping];

      /*
       * repair the .gorm file, if needed.
       */
      if(repairFile == YES)
	{
	  [self _repairFile];
	}
      
      /*
       * set our new file name
       */
      ASSIGN(documentPath, aFile);
      [window setTitleWithRepresentedFilename: documentPath];
      
      /*
       * read in all of the sounds in the .gorm wrapper and
       * load them into the editor.
       */
      dirEnumerator = [mgr enumeratorAtPath: documentPath];
      if (dirEnumerator)
	{
	  NSString *file = nil;
	  NSArray  *fileTypes = [NSSound soundUnfilteredFileTypes];
	  while ((file = [dirEnumerator nextObject]))
	    {
	      if ([fileTypes containsObject: [file pathExtension]])
		{
		  NSString *soundPath;
		  
		  NSDebugLog(@"Add the sound %@", file);
		  soundPath = [documentPath stringByAppendingPathComponent: file];
		  [soundsView addObject: [self _createSoundPlaceHolder: soundPath]];
		}
	    }
	}
      
      /*
       * read in all of the images in the .gorm wrapper and
       * load them into the editor.
       */
      dirEnumerator = [mgr enumeratorAtPath: documentPath];
      if (dirEnumerator)
	{
	  NSString *file = nil;
	  NSArray  *fileTypes = [NSImage imageFileTypes];
	  while ((file = [dirEnumerator nextObject]))
	    {
	      if ([fileTypes containsObject: [file pathExtension]])
		{
		  NSString	*imagePath;
		  id	placeHolder;
		  
		  imagePath = [documentPath stringByAppendingPathComponent: file];
		  placeHolder = [self _createImagePlaceHolder: imagePath];
		  if (placeHolder)
		    {
		      NSDebugLog(@"Add the image %@", file);
		      [imagesView addObject: placeHolder];
		    }
		}
	    }
	}
      
      NSDebugLog(@"nameTable = %@",[c nameTable]);
      
      // awaken all elements after the load is completed.
      enumerator = [[c nameTable] keyEnumerator];
      while ((key = [enumerator nextObject]) != nil)
	{
	  id o = [[c nameTable] objectForKey: key];
	  if ([o respondsToSelector: @selector(awakeFromDocument:)])
	    {
	      [o awakeFromDocument: self];
	    }
	}

      // reposition the loaded menu appropriately...
      mainMenu = [nameTable objectForKey: @"NSMenu"];
      if(mainMenu != nil)
	{
	  NSRect frame = [window frame];
	  NSPoint origin = frame.origin;
	  NSRect menuFrame = [[mainMenu window] frame];

	  // account for the height of the menu we're loading.
	  origin.y += (frame.size.height + menuFrame.size.height + 150);
	  
	  // place the main menu appropriately...
	  [[mainMenu window] setFrameTopLeftPoint: origin];
	}

      // this is the last thing we should do...
      [nc postNotificationName: IBDidOpenDocumentNotification
	  object: self];
      
      // document opened...
      isDocumentOpen = YES;

      // release the unarchiver.. now that we're all done...
      RELEASE(u);
    }
  NS_HANDLER
    {
      NSRunAlertPanel(NULL, [NSString stringWithFormat: @"Failed to load file.  Exception: %@",[localException reason]], 
		      _(@"OK"), NULL, NULL);
      return nil; // This will cause the calling method to release the document.
    }
  NS_ENDHANDLER

  return self;
}

/*
 * Build our reverse mapping information and other initialisation
 */
- (void) rebuildObjToNameMapping
{
  NSEnumerator  *enumerator;
  NSString	*name;
  id            o;

  NSDebugLog(@"------ Rebuilding object to name mapping...");
  NSResetMapTable(objToName);
  NSMapInsert(objToName, (void*)filesOwner, (void*)@"NSOwner");
  NSMapInsert(objToName, (void*)firstResponder, (void*)@"NSFirst");
  enumerator = [[nameTable allKeys] objectEnumerator];
  while ((name = [enumerator nextObject]) != nil)
    {
      id obj = [nameTable objectForKey: name];
      
      NSDebugLog(@"%@ --> %@",name, obj);

      NSMapInsert(objToName, (void*)obj, (void*)name);
      if (([obj isKindOfClass: [NSMenu class]] && [name isEqual: @"NSMenu"]) || [obj isKindOfClass: [NSWindow class]])
	{
	  [[self openEditorForObject: obj] activate];
	}
    }

  // All of the entries in the items array are "top level items" 
  // which should be visible in the object's view. 
  enumerator = [topLevelObjects objectEnumerator];
  while((o = [enumerator nextObject]) != nil)
    {
      [objectsView addObject: o];
    }
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
  NSString      *pth = [[NSUserDefaults standardUserDefaults] 
			 objectForKey:@"OpenDir"];
  
  fileTypes = [NSArray arrayWithObjects: @"gorm", @"gmodel", nil];
  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: pth
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      NSString *filename  = [oPanel filename];
      NSString *ext       = [filename pathExtension];
      BOOL     uniqueName = [(Gorm *)NSApp documentNameIsUnique: filename];

      if(uniqueName)
	{
	  [[NSUserDefaults standardUserDefaults] setObject: [oPanel directory]
						 forKey:@"OpenDir"];
	  if ([ext isEqualToString:@"gorm"] || [ext isEqualToString:@"nib"])
	    {
	      return [self loadDocument: filename];
	    }
	  else if ([ext isEqualToString:@"gmodel"])
	    {
	      return [self openGModel: filename];
	    }
	}
      else
	{
	  // if we get this far, we didn't succeed..
	  NSRunAlertPanel(NULL,_( @"Attempted to load a model which is already opened."), 
			  _(@"OK"), NULL, NULL);
	}
    }

  return nil; /* Failed */
}

- (id<IBEditors>) openEditorForObject: (id)anObject
{
  id<IBEditors>	e = [self editorForObject: anObject create: YES];
  id<IBEditors, IBSelectionOwners> p = [self parentEditorForEditor: e];
  
  if (p != nil && p != objectsView)
    {
      [self openEditorForObject: [p editedObject]];
    }

  // prevent bringing front of menus before they've been properly sized.
  if([anObject isKindOfClass: [NSMenu class]] == NO) 
    {
      [e orderFront];
      [[e window] makeKeyAndOrderFront: self];
    }

  return e;
}

- (id<IBEditors, IBSelectionOwners>) parentEditorForEditor: (id<IBEditors>)anEditor
{
  NSArray		*links;
  GormObjectToEditor	*con;

  links = [self connectorsForSource: anEditor
			    ofClass: [GormEditorToParent class]];
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
  NSUnarchiver *u;

  data = [aPasteboard dataForType: aType];
  if (data == nil)
    {
      NSDebugLog(@"Pasteboard %@ doesn't contain data of %@", aPasteboard, aType);
      return nil;
    }
  u = AUTORELEASE([[NSUnarchiver alloc] initForReadingWithData: data]);
  [u decodeClassName: @"GSCustomView" 
     asClassName: @"GormCustomView"];
  objects = [u decodeObject];
  enumerator = [objects objectEnumerator];
  filePoint = [window mouseLocationOutsideOfEventStream];
  screenPoint = [window convertBaseToScreen: filePoint];

  /*
   * Windows and panels are a special case - for a multiple window paste,
   * the windows need to be positioned so they are not on top of each other.
   */
  if ([aType isEqualToString: IBWindowPboardType] == YES)
    {
      NSWindow	*win;

      while ((win = [enumerator nextObject]) != nil)
	{
	  [win setFrameTopLeftPoint: screenPoint];
	  screenPoint.x += 10;
	  screenPoint.y -= 10;
	}
    }
  else 
    {
      NSEnumerator *enumerator = [objects objectEnumerator];
      id	obj;
      NSRect frame;
      while ((obj = [enumerator nextObject]) != nil)
      {
	// check to see if the object has a frame.  If so, then
	// modify it.  If not, simply iterate to the next object
	if([obj respondsToSelector: @selector(frame)])
	  {
	    frame = [obj frame];
	    frame.origin.x -= 6;
	    frame.origin.y -= 6;
	    [obj setFrame: frame];
	    RETAIN(obj);
	  }
      } 
    }

  [self attachObjects: objects toParent: parent];
  [self touch];
  return objects;
}

- (void) removeConnector: (id<IBConnectors>)aConnector
{
  // issue pre notification..
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName: IBWillRemoveConnectorNotification
      object: self];
  // mark the document as changed.
  [self touch];
  // issue port notification..
  [connections removeObjectIdenticalTo: aConnector];
  [nc postNotificationName: IBDidRemoveConnectorNotification
      object: self];
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
      NSMenu	*aMenu;
      NSWindow	*aWindow;
      NSRect    winFrame = [window frame];
      NSPoint   origin = winFrame.origin;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask
                        | NSResizableWindowMask | NSMiniaturizableWindowMask;

      origin.y += (winFrame.size.height + 150);

      if ([NSMenu respondsToSelector: @selector(allocSubstitute)])
	{
	  aMenu = [[NSMenu allocSubstitute] init];
	}
      else
	{
	  aMenu = [[NSMenu alloc] init];
	}

      if ([NSWindow respondsToSelector: @selector(allocSubstitute)])
	{
	  aWindow = [[NSWindow allocSubstitute]
		      initWithContentRect: NSMakeRect(0,0,600, 400)
		      styleMask: style
		      backing: NSBackingStoreRetained
		      defer: NO];
	}
      else
	{
	  aWindow = [[NSWindow alloc]
		      initWithContentRect: NSMakeRect(0,0,600, 400)
		      styleMask: style
		      backing: NSBackingStoreRetained
		      defer: NO];
	}
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: _(@"My Window")]; 
      [self setName: @"My Window" forObject: aWindow];
      [self attachObject: aWindow toParent: nil];
      [self setObject: aWindow isVisibleAtLaunch: YES];

      [aMenu setTitle: _(@"Main Menu")];
      [aMenu addItemWithTitle: _(@"Hide") 
		       action: @selector(hide:)
		keyEquivalent: @"h"];	
      [aMenu addItemWithTitle: _(@"Quit") 
		       action: @selector(terminate:)
		keyEquivalent: @"q"];

      // the first menu attached becomes the main menu.
      [self attachObject: aMenu toParent: nil]; 
      [[aMenu window] setFrameTopLeftPoint: origin];
    }
  else if ([type isEqual: @"Inspector"] == YES)
    {
      NSWindow	*aWindow;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask;

      if ([NSWindow respondsToSelector: @selector(allocSubstitute)])
	{
	  aWindow = [[NSWindow allocSubstitute] 
		      initWithContentRect: NSMakeRect(0,0, IVW, IVH)
		      styleMask: style
		      backing: NSBackingStoreRetained
		      defer: NO];
	}
      else
	{
	  aWindow = [[NSWindow alloc] 
		      initWithContentRect: NSMakeRect(0,0, IVW, IVH)
		      styleMask: style
		      backing: NSBackingStoreRetained
		      defer: NO];
	}

      [aWindow setFrameTopLeftPoint:
		 NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: _(@"Inspector Window")];
      [self setName: @"InspectorWin" forObject: aWindow];
      [self attachObject: aWindow toParent: nil];
    }
  else if ([type isEqual: @"Palette"] == YES)
    {
      NSWindow	*aWindow;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask;

      if ([NSWindow respondsToSelector: @selector(allocSubstitute)])
	{
	  aWindow = [[NSWindow allocSubstitute] 
		      initWithContentRect: NSMakeRect(0,0,272,160)
		      styleMask: style
		      backing: NSBackingStoreRetained
		      defer: NO];
	}
      else
	{
	  aWindow = [[NSWindow alloc] 
		      initWithContentRect: NSMakeRect(0,0,272,160)
		      styleMask: style
		      backing: NSBackingStoreRetained
		      defer: NO];
	}

      [aWindow setFrameTopLeftPoint:
		 NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: _(@"Palette Window")];
      [self setName: @"PaletteWin" forObject: aWindow];
      [self attachObject: aWindow toParent: nil];
    }
}

- (void) setName: (NSString*)aName forObject: (id)object
{
  id		       oldObject;
  NSString	      *oldName;
  NSMutableDictionary *cc = [classManager customClassMap];
  NSString            *className;

  if (object == nil)
    {
      NSDebugLog(@"Attempt to set name for nil object");
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
	  if ([object isKindOfClass: [GSNibItem class]])
	    {
	      // use the actual class name for proxies
	      base = [(id)object className];
	    }
	  else
	    {
	      base = NSStringFromClass([object class]);
	    }
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
	  NSDebugLog(@"Attempt to re-use name '%@'", aName);
	  return;
	}
      oldName = [self nameForObject: object];
      if (oldName != nil)
	{
	  if ([oldName isEqual: aName] == YES)
	    {
	      return;	/* Already have this name ... nothing to do */
	    }
	  // RETAIN(object); // the next operation will attempt to release the object, we need to retain it.
	  [nameTable removeObjectForKey: oldName];
	  NSMapRemove(objToName, (void*)object);
	}
    }
  // nameCopy = [aName copy];	/* Make sure it's immutable */
  [nameTable setObject: object forKey: aName];
  RELEASE(object); // make sure that when it's removed from the table, it's released.
  NSMapInsert(objToName, (void*)object, (void*) aName); //nameCopy);
  if (oldName != nil)
    {
      [nameTable removeObjectForKey: oldName];
    }
  if ([objectsView containsObject: object] == YES)
    {
      [objectsView refreshCells];
    }

  // check the custom classes map and replace the appropriate
  // object, if a mapping exists.
  if(cc != nil)
    {
      className = [cc objectForKey: oldName];
      if(className != nil)
	{
	  [cc removeObjectForKey: oldName];
	  [cc setObject: className forKey: aName]; //nameCopy];
	}
    }
  // RELEASE(nameCopy); // release the copy of the name which we made...
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

- (void) setObject: (id)anObject isDeferred: (BOOL)flag
{
  NSMutableArray	*a = [nameTable objectForKey: @"NSDeferred"];

  if (flag == YES)
    {
      if (a == nil)
	{
	  a = [NSMutableArray new];
	  [nameTable setObject: a forKey: @"NSDeferred"];
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

- (BOOL) objectIsDeferred: (id)anObject
{
  return [[nameTable objectForKey: @"NSDeferred"] containsObject: anObject];
}

// windows / services menus...
- (void) setWindowsMenu: (NSMenu *)anObject 
{
  if(anObject != nil)
    {
      [nameTable setObject: anObject forKey: @"NSWindowsMenu"];
    }
  else
    {
      [nameTable removeObjectForKey: @"NSWindowsMenu"];
    }
}

- (NSMenu *) windowsMenu
{
  return [nameTable objectForKey: @"NSWindowsMenu"];
}

- (void) setServicesMenu: (NSMenu *)anObject
{
  if(anObject != nil)
    {
      [nameTable setObject: anObject forKey: @"NSServicesMenu"];
    }
  else
    {
      [nameTable removeObjectForKey: @"NSServicesMenu"];
    }
}

- (NSMenu *) servicesMenu
{
  return [nameTable objectForKey: @"NSServicesMenu"];
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

- (BOOL) saveAsDocument: (id)sender
{
  NSSavePanel		*sp;
  int			result;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: @"gorm"];
  result = [sp runModalForDirectory: NSHomeDirectory() file: @""];
  if (result == NSOKButton)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*path = [sp filename];

      if ([path isEqual: documentPath] == NO
	&& [mgr fileExistsAtPath: path] == YES)
	{
	  /* NSSavePanel has already asked if it's ok to replace */
	  NSString	*bPath = [path stringByAppendingString: @"~"];
	  
	  [mgr removeFileAtPath: bPath handler: nil];
	  [mgr movePath: path toPath: bPath handler: nil];
	}

      // set the path...
      ASSIGN(documentPath, path);
      [self saveGormDocument: sender];
      
      return YES;
    }
  return NO;
}

//
// Private method which iterates through the list of custom classes and instructs 
// the archiver to replace the actual object with template during the archiving 
// process.
//
- (void) _replaceObjectsWithTemplates: (NSArchiver *)archiver
{
  GormClassManager *cm = [self classManager];
  NSEnumerator *en = [[cm customClassMap] keyEnumerator];
  id key = nil;

  // loop through all objects.
  while((key = [en nextObject]) != nil)
    {
      id customClass = [cm customClassForName: key];
      id object = [self objectForName: key];
      NSString *superClass = [cm nonCustomSuperClassOf: customClass];
      id template = [GSTemplateFactory templateForObject: object
				       withClassName: customClass 
				       withSuperClassName: superClass];
      
      // if the object is deferrable, then set the flag appropriately.
      if([template respondsToSelector: @selector(setDeferFlag:)])
	{
	  [template setDeferFlag: [self objectIsDeferred: object]];
	}

      // replace the object with the template.
      [archiver replaceObject: object withObject: template];
    }
}

- (BOOL) saveGormDocument: (id)sender
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  BOOL			archiveResult;
  NSArchiver            *archiver;
  NSMutableData         *archiverData;
  NSString              *gormPath;
  NSString              *classesPath;
  NSString              *infoPath;
  NSFileManager         *mgr = [NSFileManager defaultManager];
  BOOL                  isDir;
  BOOL                  fileExists;
  int                   retval;

  if (documentPath == nil)
    {
      // if no path has been defined... define one.
      return ([self saveAsDocument: sender]);
    }

  // Warn the user about possible incompatibility.
  // TODO: Remove after the next release of GUI.
  if(isOlderArchive && [filePrefsManager isLatest])
    {
      retval = NSRunAlertPanel(_(@"Compatibility Warning"), 
			       _(@"Saving will update this gorm to the latest version, which is not compatible with GNUstep's gui 0.9.3 Release or CVS prior to Jun 28 2004."),
			       _(@"Save"),
			       _(@"Don't Save"), nil, nil);
      if (retval != NSAlertDefaultReturn)
	{
	  return NO;
	}
      else
	{
	  // we're saving anyway... set to new value.
	  isOlderArchive = NO;
	}
    }

  [nc postNotificationName: IBWillSaveDocumentNotification
		    object: self];

  [self beginArchiving];

  // set up the necessary paths...
  gormPath = [documentPath stringByAppendingPathComponent: @"objects.gorm"];
  classesPath = [documentPath stringByAppendingPathComponent: @"data.classes"];
  infoPath = [documentPath stringByAppendingPathComponent: @"data.info"];

  archiverData = [NSMutableData dataWithCapacity: 0];
  archiver = [[NSArchiver alloc] initForWritingWithMutableData: archiverData];

  /* Special gorm classes to their archive equivalents. */
  // see implementation of classForCoder for GSNibContainer.
  [archiver encodeClassName: @"GormObjectProxy" 
	    intoClassName: @"GSNibItem"];
  [archiver encodeClassName: @"GormCustomView"
	    intoClassName: @"GSCustomView"];
  [archiver encodeClassName: @"GormNSMenu"
  	    intoClassName: @"NSMenu"];
  [archiver encodeClassName: @"GormNSWindow"
	    intoClassName: @"NSWindow"];
  [archiver encodeClassName: @"GormNSPanel"
	    intoClassName: @"NSPanel"];
  [archiver encodeClassName: @"GormNSPopUpButton" 
	    intoClassName: @"NSPopUpButton"];
  [archiver encodeClassName: @"GormNSPopUpButtonCell" 
	    intoClassName: @"NSPopUpButtonCell"];
  [archiver encodeClassName: @"GormNSBrowser" 
	    intoClassName: @"NSBrowser"];
  [archiver encodeClassName: @"GormNSTableView" 
	    intoClassName: @"NSTableView"];
  [archiver encodeClassName: @"GormNSOutlineView" 
	    intoClassName: @"NSOutlineView"];

  [self _replaceObjectsWithTemplates: archiver];

  [archiver encodeRootObject: self];
  NSDebugLog(@"nameTable = %@",nameTable);

  NSDebugLog(@"customClasses = %@", [classManager customClassMap]);

  fileExists = [mgr fileExistsAtPath: documentPath isDirectory: &isDir];
  if (fileExists)
    {
      if (isDir == NO)
	{
	  NSString *saveFilePath;

	  saveFilePath = [documentPath stringByAppendingPathExtension: @"save"];
	  // move the old file to something...
	  if (![mgr movePath: documentPath toPath: saveFilePath handler: nil])
	    {
	      NSDebugLog(@"Error moving old %@ file to %@",
	      	documentPath, saveFilePath);
	    }
	  
	  // create the new directory..
	  archiveResult = [mgr createDirectoryAtPath: documentPath
	 				  attributes: nil];
	}
      else
	{
	  // set to yes since the directory is already present.
	  archiveResult = YES;
	}
    }
  else
    {
      // create the directory...
      archiveResult = [mgr createDirectoryAtPath: documentPath attributes: nil];
    }
  
  RELEASE(archiver); // We're done with the archiver here..

  if (archiveResult)
    {
      // save the data...
      archiveResult = [archiverData writeToFile: gormPath atomically: YES]; 
      if (archiveResult) 
	{
	  // save the custom classes.. and we're done...
	  archiveResult = [classManager saveToFile: classesPath];
	  
	  // save the file prefs metadata...
	  if (archiveResult)
	    {
	      archiveResult = [filePrefsManager saveToFile: infoPath];
	    }

	  // copy sounds into the new folder...
	  if (archiveResult)
	    {
	      NSArray *sounds = [soundsView objects];
	      NSArray *images = [imagesView objects];
	      id object = nil;
	      NSEnumerator *en = [sounds objectEnumerator];
	      while ((object = [en nextObject]) != nil)
		{
		  if(![object isSystemSound])
		    {
		      NSString *soundPath;
		      NSString *path = [object soundPath];
		      BOOL copied = NO;
		      
		      soundPath = [documentPath stringByAppendingPathComponent:
						  [path lastPathComponent]];
		      if(![path isEqualToString: soundPath])
			{
			  copied = [mgr copyPath: path
					toPath: soundPath
					handler: nil];
			}
		      else
			{
			  // mark as copied if paths are equal...
			  copied = YES;
			}
		      
		      if (!copied)
			{
			  NSDebugLog(@"Could not find sound at path %@", object);
			}
		    }
		}
	      
	      en = [images objectEnumerator];
	      while ((object = [en nextObject]) != nil)
		{
		  if(![object isSystemImage])
		    {
		      NSString *imagePath;
		      NSString *path = [object imagePath];
		      BOOL copied = NO;
		      
		      imagePath = [documentPath stringByAppendingPathComponent:
						  [path lastPathComponent]];
		      
		      if(![path isEqualToString: imagePath])
			{
			  copied = [mgr copyPath: path
					toPath: imagePath
					handler: nil];
			}
		      else
			{
			  // mark it as copied if paths are equal.
			  copied = YES;
			}
		      
		      if (!copied)
			{
			  NSDebugLog(@"Could not find image at path %@", object);
			}
		    }
		} 
	    }
	}
    }

  [self endArchiving];

  if (archiveResult == NO)
    {
      NSRunAlertPanel(NULL,_( @"Could not save document"), 
		      _(@"OK"), NULL, NULL);
    }
  else
    {
      [window setDocumentEdited: NO];
      [window setTitleWithRepresentedFilename: documentPath];

      [nc postNotificationName: IBDidSaveDocumentNotification
			object: self];
    }
  return YES;
}

- (void) setDocumentActive: (BOOL)flag
{
  if (flag != isActive && isDocumentOpen)
    {
      NSEnumerator	*enumerator;
      id		obj;

      enumerator = [nameTable objectEnumerator];
      if (flag == YES)
	{
	  GormDocument *document = (GormDocument*)[(id<IB>)NSApp activeDocument];

	  // set the current document active and unset the old one.
	  [document setDocumentActive: NO];
	  isActive = YES;

	  // display everything.
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      NSString *name = [document nameForObject: obj];
	      if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderFront: self];
		}
	      else if ([obj isKindOfClass: [NSMenu class]] && 
		       [name isEqual: @"NSMenu"] == YES)
		{
		  [obj display];
		}
	    }

	  //
	  // Reset the selection to the current selection held by the current
	  // selection owner of this document when the document becomes active.
	  // This allows the app to switch to the correct inspector when the new
	  // document is selected.
	  //
	  [self setSelectionFromEditor: lastEditor];
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
	      else if ([obj isKindOfClass: [NSMenu class]] == YES &&
		       [[self nameForObject: obj] isEqual: @"NSMenu"] == YES)
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
  NSDebugLog(@"setSelectionFromEditor %@", anEditor);
  lastEditor = anEditor;
  if ([(NSObject *)anEditor respondsToSelector: @selector(window)])
    {
      [[anEditor window] makeFirstResponder: (id)anEditor];
    }
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
       * Normal view objects just get link markup drawn on them.
       */
      id temp = object;
      id editor = [self editorForObject: temp create: NO];
      
      while ((temp != nil) && (editor == nil))
	{
	  temp = [temp superview];
	  editor = [self editorForObject: temp create: NO];
	}

      if (temp == nil)
	{
	  *r = [object convertRect: [object bounds] toView: nil];
	}
      else if ([editor respondsToSelector: 
			 @selector(windowAndRect:forObject:)])
	{
	  return [editor windowAndRect: r forObject: object];
	}
    }
  else if ([object isKindOfClass: [NSTableColumn class]] == YES)
    {
      NSTableView *tv = [[(NSTableColumn*)object dataCell] controlView];
      NSTableHeaderView *th =  [tv headerView];
      int index;

      if (th == nil || tv == nil)
	{
	  NSDebugLog(@"fail 1 %@ %@ %@", [(NSTableColumn*)object headerCell], th, tv);
	  *r = NSZeroRect;
	  return nil;
	}
      
      index = [[tv tableColumns] indexOfObject: object];

      if (index == NSNotFound)
	{
	  NSDebugLog(@"fail 2");
	  *r = NSZeroRect;
	  return nil;
	}
      
      *r = [th convertRect: [th headerRectOfColumn: index]
	       toView: nil];
      return [th window];
    }
  else
    {
      *r = NSZeroRect;
      return nil;
    }

  // never reached, keeps gcc happy
  return nil;
}

- (NSWindow*) window
{
  return window;
}

- (BOOL) couldCloseDocument
{
  if ([window isDocumentEdited] == YES)
    {
      NSString	*msg;
      int	result;

      if (documentPath == nil)
	{
	  msg = _(@"Document 'UNTITLED' has been modified");
	}
      else
	{
	  msg = [NSString stringWithFormat: _(@"Document '%@' has been modified"),
	    [documentPath lastPathComponent]];
	}
      result = NSRunAlertPanel(NULL, msg, _(@"Save"), _(@"Don't Save"), _(@"Cancel"));

      if (result == NSAlertDefaultReturn) 
	{ 	  
	  //Save
	  if (! [self saveGormDocument: self] )
	    {
	      return NO;
	    }
	  else
	    {
	      isDocumentOpen = NO;
	    }
	}
      else if (result == NSAlertOtherReturn)
	{
	  //Cancel
	  return NO;
	}
      else // Don't save...
	{
	  isDocumentOpen = NO;
	}
    }

  return YES;
}

- (BOOL) windowShouldClose: (id)sender
{
  return [self couldCloseDocument];
}

// convenience methods for formatting outlets/actions
+ (NSString*) identifierString: (NSString*)str
{
  NSCharacterSet	*illegal = [[NSCharacterSet characterSetWithCharactersInString:
						      @"_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"]
				     invertedSet];
  NSCharacterSet	*numeric = [NSCharacterSet characterSetWithCharactersInString:
						     @"0123456789"];
  NSRange		r;
  NSMutableString	*m;
  
  if (str == nil)
    {
      return nil;
    }
  m = [str mutableCopy];
  r = [str rangeOfCharacterFromSet: illegal];
  while (r.length > 0)
    {
      [m deleteCharactersInRange: r];
      r = [m rangeOfCharacterFromSet: illegal];
    }
  r = [str rangeOfCharacterFromSet: numeric];
  while (r.length > 0 && r.location == 0)
    {
      [m deleteCharactersInRange: r];
      r = [m rangeOfCharacterFromSet: numeric];
    }
  str = [m copy];
  RELEASE(m);
  AUTORELEASE(str);

  return str;
}

+ (NSString *)formatAction: (NSString *)action
{
  NSString *identifier;

  identifier = [[self identifierString: action] stringByAppendingString: @":"];
  return identifier;
}

+ (NSString *)formatOutlet: (NSString *)outlet
{
  NSString *identifier = [self identifierString: outlet];
  return identifier;
}

- (BOOL) removeConnectionsWithLabel: (NSString *)name
		      forClassNamed: (NSString *)className
			   isAction: (BOOL)action
{
  NSEnumerator *en = [connections objectEnumerator];
  id<IBConnectors> c = nil;
  BOOL removed = YES;

  // remove all.
  while ((c = [en nextObject]) != nil)
    {
      id proxy = nil;
      NSString *label = [c label];

      if (action)
	{
	  if (![label hasSuffix: @":"]) 
	    continue;
	  proxy = [c destination];
	}
      else
	{
	  if ([label hasSuffix: @":"]) 
	    continue;
	  proxy = [c source];
	}
      
      if ([label isEqualToString: name] && 
	 [[proxy className] isEqualToString: className])
	{
	  NSString *title;
	  NSString *msg;
	  int retval;

	  title = [NSString stringWithFormat:
	    @"Modifying %@",(action==YES?@"Action":@"Outlet")];
	  msg = [NSString stringWithFormat:
			    _(@"This will break all connections to '%@'.  Continue?"), name];
	  retval = NSRunAlertPanel(title, msg,_(@"OK"),_(@"Cancel"), nil, nil);

	  if (retval == NSAlertDefaultReturn)
	    {
	      removed = YES;
	      [self removeConnector: c];
	    }
	  else
	    {
	      removed = NO;
	    }
	}
    }

  // done...
  NSDebugLog(@"Removed references to %@ on %@", name, className);
  return removed;
}

- (BOOL) removeConnectionsForClassNamed: (NSString *)className
{
  NSEnumerator *en = [connections objectEnumerator];
  id<IBConnectors> c = nil;
  BOOL removed = YES;
  int retval = -1;
  NSString *title = [NSString stringWithFormat: _(@"Modifying Class")];
  NSString *msg;

  msg = [NSString stringWithFormat: _(@"This will break all connections to "
    @"actions/outlets to instances of class '%@'.  Continue?"), className];

  // ask the user if he/she wants to continue...
  retval = NSRunAlertPanel(title, msg,_(@"OK"),_(@"Cancel"), nil, nil);
  if (retval == NSAlertDefaultReturn)
    {
      removed = YES;
    }
  else
    {
      removed = NO;
    }

  // remove all.
  while ((c = [en nextObject]) != nil)
    {
      // check both...
      if ([[[c source] className] isEqualToString: className]
	|| [[[c destination] className] isEqualToString: className])
	{
	  [self removeConnector: c];
	}
    }
  
  // done...
  NSDebugLog(@"Removed references to actions/outlets for objects of %@",
    className);
  return removed;
}

- (BOOL) renameConnectionsForClassNamed: (NSString *)className
				 toName: (NSString *)newName
{
  NSEnumerator *en = [connections objectEnumerator];
  id<IBConnectors> c = nil;
  BOOL removed = YES;
  int retval = -1;
  NSString *title = [NSString stringWithFormat: _(@"Modifying Class")];
  NSString *msg = [NSString stringWithFormat: 
			      _(@"Change class name '%@' to '%@'.  Continue?"),
			    className, newName];

  // ask the user if he/she wants to continue...
  retval = NSRunAlertPanel(title, msg,_(@"OK"),_(@"Cancel"), nil, nil);
  if (retval == NSAlertDefaultReturn)
    {
      removed = YES;
    }
  else
    {
      removed = NO;
    }

  // remove all.
  while ((c = [en nextObject]) != nil)
    {
      id source = [c source];
      id destination = [c destination];

      // check both...
      if ([[[c source] className] isEqualToString: className])
	{
	  [source setClassName: newName];
	  NSDebugLog(@"Found matching source");
	}
      else if ([[[c destination] className] isEqualToString: className])
	{
	  [destination setClassName: newName];
	  NSDebugLog(@"Found matching destination");
	}
    }

  // Get the object from the object editor so that we can change the name
  // there too.
  
  // done...
  NSDebugLog(@"Changed references to actions/outlets for objects of %@", className);
  return removed;
}


// for debuging purpose
- (void) printAllEditors
{
  NSMutableSet	        *set = [NSMutableSet setWithCapacity: 16];
  NSEnumerator		*enumerator = [connections objectEnumerator];
  id<IBConnectors>	c;

  while ((c = [enumerator nextObject]) != nil)
    {
      if ([GormObjectToEditor class] == [c class])
	{
	  [set addObject: [c destination]];
	}
    }

  NSLog(@"all editors %@", set);
}

// sound support...
- (id) openSound: (id)sender
{
  NSArray	*fileTypes = [NSSound soundUnfilteredFileTypes]; 
  NSArray	*filenames;
  NSString	*filename;
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;
  int		i;

  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      filenames = [oPanel filenames];
      for (i=0; i<[filenames count]; i++)
      {
        filename = [filenames objectAtIndex:i];
        NSDebugLog(@"Loading sound file: %@",filenames);
        [soundsView addObject: [self _createSoundPlaceHolder: filename]];
      }
      return self;
    }

  return nil;
}

// image support...
- (id) openImage: (id)sender
{
  NSArray	*fileTypes = [NSImage imageFileTypes]; 
  NSArray	*filenames;
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  NSString	*filename;
  int		result;
  int		i;

  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      filenames = [oPanel filenames];
      for (i=0; i<[filenames count]; i++)
      {
        filename = [filenames objectAtIndex:i];
        NSDebugLog(@"Loading image file: %@",filename);
        [imagesView addObject: [self _createImagePlaceHolder: filename]];
      }
      return self;
    }

  return nil;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%s: %lx> = %@",
		   GSClassNameFromObject(self), 
		   (unsigned long)self,
		   nameTable];
}

- (id) firstResponder
{
  return firstResponder;
}

- (id) fontManager
{
  return fontManager;
}
@end

@implementation GormDocument (MenuValidation)
- (BOOL) isEditingObjects
{
  return ([selectionBox contentView] == scrollView);
}

- (BOOL) isEditingImages
{
  return ([selectionBox contentView] == imagesScrollView);
}

- (BOOL) isEditingSounds
{
  return ([selectionBox contentView] == soundsScrollView);
}

- (BOOL) isEditingClasses
{
  return ([selectionBox contentView] == classesScrollView);
}
@end

@implementation GormDocument (NSToolbarDelegate)

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
  NSToolbarItem *toolbarItem = AUTORELEASE([[NSToolbarItem alloc]
					     initWithItemIdentifier: itemIdentifier]);

  if([itemIdentifier isEqual: @"ObjectsItem"])
    {
      [toolbarItem setLabel: @"Objects"];
      [toolbarItem setImage: objectsImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(changeView:)];     
      [toolbarItem setTag: 0];
    }
  else if([itemIdentifier isEqual: @"ImagesItem"])
    {
      [toolbarItem setLabel: @"Images"];
      [toolbarItem setImage: imagesImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(changeView:)];     
      [toolbarItem setTag: 1];
    }
  else if([itemIdentifier isEqual: @"SoundsItem"])
    {
      [toolbarItem setLabel: @"Sounds"];
      [toolbarItem setImage: soundsImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(changeView:)];     
      [toolbarItem setTag: 2];
    }
  else if([itemIdentifier isEqual: @"ClassesItem"])
    {
      [toolbarItem setLabel: @"Classes"];
      [toolbarItem setImage: classesImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(changeView:)];     
      [toolbarItem setTag: 3];
    }
  else if([itemIdentifier isEqual: @"FileItem"])
    {
      [toolbarItem setLabel: @"File"];
      [toolbarItem setImage: fileImage];
      [toolbarItem setTarget: self];
      [toolbarItem setAction: @selector(changeView:)];     
      [toolbarItem setTag: 4];
    }

  return toolbarItem;
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects: @"ObjectsItem", 
		  @"ImagesItem", 
		  @"SoundsItem", 
		  @"ClassesItem", 
		  @"FileItem", 
		  nil];
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{ 
  return [NSArray arrayWithObjects: @"ObjectsItem", 
		  @"ImagesItem", 
		  @"SoundsItem", 
		  @"ClassesItem", 
		  @"FileItem",
		  nil];
}
@end
