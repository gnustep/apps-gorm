/* Gorm.m
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2004
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
#include "GormPrefController.h"
#include "GormFontViewController.h"
#include "GormSetNameController.h"
#include "GNUstepGUI/GSNibCompatibility.h"
#include "GNUstepBase/GSObjCRuntime.h"

// for templates...
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>

NSString *GormToggleGuidelineNotification = @"GormToggleGuidelineNotification";
NSString *GormDidModifyClassNotification = @"GormDidModifyClassNotification";
NSString *GormDidAddClassNotification = @"GormDidAddClassNotification";
NSString *GormDidDeleteClassNotification = @"GormDidDeleteClassNotification";
NSString *GormWillDetachObjectFromDocumentNotification = @"GormWillDetachObjectFromDocumentNotification";
NSString *GormResizeCellNotification = @"GormResizeCellNotification";

// Define this as "NO" initially.   We only want to turn this on while loading or testing.
static BOOL _isInInterfaceBuilder = NO;

static NSImage *gormImage = nil;
static NSImage *testingImage = nil;

@class	InfoPanel;

// we had this include for grouping/ungrouping selectors
#include "GormViewWithContentViewEditor.h"

@implementation NSCell (GormAdditions)
/*
 *  this methods is directly coming from NSCell.m
 *  The only additions is [textObject setUsesFontPanel: NO]
 *  We do this because we want to have control over the font panel changes
 */
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObject
{
  [textObject setUsesFontPanel: NO];
  [textObject setTextColor: [self textColor]];
  if (_cell.contents_is_attributed_string == NO)
    {
      /* TODO: Manage scrollable attribute */
      [textObject setFont: _font];
      [textObject setAlignment: _cell.text_align];
    }
  else
    {
      /* TODO: What do we do if we are an attributed string.  
         Think about what happens when the user ends editing. 
         Allows editing text attributes... Formatter. */
    }
  [textObject setEditable: _cell.is_editable];
  [textObject setSelectable: _cell.is_selectable || _cell.is_editable];
  [textObject setRichText: _cell.is_rich_text];
  [textObject setImportsGraphics: _cell.imports_graphics];
  [textObject setSelectedRange: NSMakeRange(0, 0)];

  return textObject;
}
@end

@implementation GSNibItem (GormAdditions)
- initWithClassName: (NSString*)className frame: (NSRect)frame
{
  self = [super init];

  theClass = [className copy];
  theFrame = frame;

  return self;
}
- (NSString*) className
{
  return theClass;
}
@end

@interface NSObject (GormPrivate)
+ (void) poseAsClass: (Class)aClassObject;
@end

@implementation NSObject (GormPrivate)
+ (void) poseAsClass: (Class)aClassObject
{
  // disable poseAs: while in Gorm.
  // class_pose_as(self, aClassObject);
}
@end

@implementation GormObjectProxy
/*
 * Perhaps this would be better to have a dummy initProxyWithCoder
 * in GSNibItem class, so that we are not dependent on actual coding
 * order of the ivars ?
 */
- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: 
			  NSStringFromClass([GSNibItem class])];
  
  if (version == NSNotFound)
    {
      NSLog(@"no GSNibItem");
      version = [aCoder versionForClassName: 
			  NSStringFromClass([GormObjectProxy class])];
    }

  if (version == 0)
    {
      // do not decode super (it would try to morph into theClass ! )
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      RETAIN(theClass); // release in dealloc of GSNibItem... 
      
      return self; 
    }
  else if (version == 1)
    {
      // do not decode super (it would try to morph into theClass ! )
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      [aCoder decodeValueOfObjCType: @encode(unsigned int) 
	      at: &autoresizingMask];  
      RETAIN(theClass); // release in dealloc of GSNibItem... 
      
      return self; 
    }
  else
    {
      NSLog(@"no initWithCoder for version %d", version);
      RELEASE(self);
      return nil;
    }
}

- (NSString*) inspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (void) setClassName: (NSString *)className
{
  RELEASE(theClass);
  theClass = [className copy];
}

- (NSImage *) imageForViewer
{
  NSImage *image = [super imageForViewer];
  if([theClass isEqual: @"NSFontManager"])
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString *path = [bundle pathForImageResource: @"GormFontManager"]; 
      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}

@end

// define the class proxy...
@implementation GormClassProxy
- (id) initWithClassName: (NSString*)n
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(name, n);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(name);
  [super dealloc];
}

- (NSString*) className
{
  return name;
}

- (NSString*) inspectorClassName
{
  return @"GormClassInspector";
}

- (NSString*) classInspectorClassName
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

@implementation Gorm

- (id<IBDocuments>) activeDocument
{
  unsigned	i = [documents count];

  if (i > 0)
    {
      while (i-- > 0)
	{
	  id	doc = [documents objectAtIndex: i];

 	  if ([doc isActive] == YES)
	    {
	      return doc;
	    }
	}
    }
  return nil;
}

/* 
   NSApp
*/
- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSBundle			*bundle = [NSBundle mainBundle];
      NSString			*path;

      path = [bundle pathForImageResource: @"GormLinkImage"];
      linkImage = [[NSImage alloc] initWithContentsOfFile: path];
      path = [bundle pathForImageResource: @"GormSourceTag"];
      sourceImage = [[NSImage alloc] initWithContentsOfFile: path];
      path = [bundle pathForImageResource: @"GormTargetTag"];
      targetImage = [[NSImage alloc] initWithContentsOfFile: path];
      path = [bundle pathForImageResource: @"Gorm"];
      gormImage = [[NSImage alloc] initWithContentsOfFile: path];
      path = [bundle pathForImageResource: @"GormTesting"];
      testingImage = [[NSImage alloc] initWithContentsOfFile: path];

      documents = [NSMutableArray new];
      [nc addObserver: self
	  selector: @selector(handleNotification:)
	  name: IBSelectionChangedNotification
	  object: nil];
      [nc addObserver: self
	  selector: @selector(handleNotification:)
	  name: IBWillCloseDocumentNotification
	  object: nil];

      /*
       * Make sure the palettes manager exists, so that the editors and
       * inspectors provided in the standard palettes are available.
       */
      [self palettesManager];

      // load the interface...
      if(![NSBundle loadNibNamed: @"Gorm" owner: self])
	{
	  NSLog(@"Failed to load interface");
	  exit(-1);
	}
    }
  return self;
}


- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  RELEASE(infoPanel);
  RELEASE(inspectorsManager);
  RELEASE(palettesManager);
  RELEASE(documents);
  RELEASE(classManager);
  [super dealloc];
}


- (void) applicationDidFinishLaunching: (NSApplication*)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *a = nil;
  

  if ( [defaults boolForKey: @"ShowInspectors"] )
    {
      [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
    }
  if ( [defaults boolForKey: @"ShowPalettes"] )
    {
      [[[self palettesManager] panel] makeKeyAndOrderFront: self];
    }
  if((a = [defaults arrayForKey: @"GSAppKitUserBundles"]) != nil)
    {
      if([a count] > 0)
	{
	  NSLog(@"WARNING: Gorm has detected that you are using user bundles.  Please make certain that these are compatible with Gorm as some bundles can cause issues which may corrupt your .gorm files.");
	}
    }
  if(GSGetMethod([GSNibContainer class],@selector(awakeWithContext:),YES,YES) == NULL)
    {
      NSRunAlertPanel(_(@"Incorrect GNUstep Version"), 
		      _(@"The version of GNUstep you are using is too old for this version of Gorm, please update."),
		      _(@"OK"), nil, nil);
      [self terminate: self];
    }
}


- (void) applicationWillTerminate: (NSApplication*)sender
{
//   [[NSUserDefaults standardUserDefaults] 
//     setBool: [[[self inspectorsManager] panel] isVisible]
//     forKey: @"ShowInspectors"];
//   [[NSUserDefaults standardUserDefaults] 
//     setBool: [[[self palettesManager] panel] isVisible]
//     forKey: @"ShowPalettes"];
}

- (BOOL) applicationShouldTerminate: (NSApplication*)sender
{
  id doc;
  BOOL edited = NO;
  NSEnumerator *enumerator = [documents objectEnumerator];

  
  if (isTesting == YES)
    {
       [self endTesting: sender];
       return NO;
    }
  
  
  while (( doc = [enumerator nextObject] ) != nil )
    {
    if ([[doc window]  isDocumentEdited] == YES)
      {
	edited = YES;
	break;
      }
    }

   if (edited == YES)
     {
       int	result;
       result = NSRunAlertPanel(_(@"Quit"), 
				_(@"There are edited windows"),
				_(@"Review Unsaved"),
				_( @"Quit Anyway"),
				_(@"Cancel"));
      if (result == NSAlertDefaultReturn) 
	{ 	  
	  enumerator = [ documents objectEnumerator];
 	  while ((doc = [enumerator nextObject]) != nil)
 	    {
 	      if ( [[doc window]  isDocumentEdited] == YES)
 		{
		  if ( ! [doc couldCloseDocument] )
		    return NO;
 		}
 	    }	
	}
      else if (result == NSAlertOtherReturn) 
	return NO; 
     }
   return YES;
}
  
- (GormClassManager*) classManager
{
  id document = [self activeDocument];

  if (document != nil) return [document classManager];
  
  /* kept in the case one want access to the classManager without document */
  else if (classManager == nil)
    {
      classManager = [GormClassManager new];
    }
  return classManager;
  
}

- (id) connectDestination
{
  return connectDestination;
}

- (id) connectSource
{
  return connectSource;
}

- (void) displayConnectionBetween: (id)source
			      and: (id)destination
{
  NSWindow	*window;
  NSRect	rect;
  

  if (source != connectSource)
    {
      if (connectSource != nil)
	{
	  window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
				    forObject: connectSource];
	  if (window != nil)
	    {
	      NSView	*view = [[window contentView] superview];
 
	      rect.origin.x --;
	      rect.size.width ++;
	      
	      rect.size.height ++;

	      [window disableFlushWindow];
	      [view displayRect: rect];
	      
	      [window enableFlushWindow];
	      [window flushWindow];
	    }
	}
      connectSource = source;
    }
  if (destination != connectDestination)
    {
      if (connectDestination != nil)
	{
	  window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
				    forObject: connectDestination];
	  if (window != nil)
	    {
	      NSView	*view = [[window contentView] superview];

	      /*
	       * Erase image from old location.
	       */
	      rect.origin.x --;
	      rect.size.width ++;
	      rect.size.height ++;

	      [view lockFocus];
	      [view displayRect: rect];
	      [view unlockFocus];
	      [window flushWindow];
	    }
	}
      connectDestination = destination;
    }
  if (connectSource != nil)
    {
      window = [(GormDocument *)[self activeDocument] windowAndRect: &rect forObject: connectSource];
      if (window != nil)
	{
	  NSView	*view = [[window contentView] superview];
	  NSRect        imageRect = rect;

	  imageRect.origin.x++;
	  //rect.size.width--;
	  //rect.size.height--;
	  [view lockFocus];
	  [[NSColor greenColor] set];
	  NSFrameRectWithWidth(rect, 1);
	  
	  [sourceImage compositeToPoint: imageRect.origin
			      operation: NSCompositeSourceOver];
	  [view unlockFocus];
	  [window flushWindow];
	}
    }
  if (connectDestination != nil && connectDestination == connectSource)
    {
      window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
				forObject: connectDestination];
      if (window != nil)
	{
	  NSView	*view = [[window contentView] superview];
	  NSRect        imageRect = rect;

	  imageRect.origin.x += 3;
	  imageRect.origin.y += 2;
	  // rect.size.width -= 5;
	  // rect.size.height -= 5;
	  [view lockFocus];
	  [[NSColor purpleColor] set];
	  NSFrameRectWithWidth(rect, 1);
	  
	  imageRect.origin.x += [targetImage size].width;
	  [targetImage compositeToPoint: imageRect.origin
			      operation: NSCompositeSourceOver];
	  [view unlockFocus];
	  [window flushWindow];
	}
    }
  else if (connectDestination != nil)
    {
      window = [(GormDocument *)[self activeDocument] windowAndRect: &rect
				forObject: connectDestination];
      if (window != nil)
	{
	  NSView	*view = [[window contentView] superview];
	  NSRect        imageRect = rect;

	  imageRect.origin.x++;
	  // rect.size.width--;
	  // rect.size.height--;
	  [view lockFocus];
	  [[NSColor purpleColor] set];
	  NSFrameRectWithWidth(rect, 1);
	  
	  [targetImage compositeToPoint: imageRect.origin
			      operation: NSCompositeSourceOver];
	  [view unlockFocus];
	  [window flushWindow];
	}
    }
}

/** Info Menu Actions */

- (void) preferencesPanel: (id) sender
{
  if(! preferencesController)
    {
      preferencesController =  [[GormPrefController alloc] initWithWindowNibName:@"GormPreferences"];
    }

  [[preferencesController window] makeKeyAndOrderFront:nil];
}

/** Document Menu Actions */

- (void) open: (id) sender
{
  GormDocument	*doc = AUTORELEASE([GormDocument new]);

  [documents addObject: doc];
  if ([doc openDocument: sender] == nil)
    {
      [doc closeAllEditors];
      [documents removeObjectIdenticalTo: doc];
      doc = nil;
    }
  else
    {
      [[doc window] makeKeyAndOrderFront: self];
    }
}

- (void) newGormDocument : (id) sender 
{
  id doc = AUTORELEASE([GormDocument new]);
  [documents addObject: doc];
  switch ([sender tag]) 
    {
    case 0:
      [doc setupDefaults: @"Application"];
      break;
    case 1:
      [doc setupDefaults: @"Empty"];
      break;
    case 2:
      [doc setupDefaults: @"Inspector"];
      break;
    case 3:
      [doc setupDefaults: @"Palette"];
      break;

    default: 
      printf("unknow newGormDocument tag");
    }
  if (NSEqualPoints(cascadePoint, NSZeroPoint))
    {	
      NSRect frame = [[doc window] frame];
      cascadePoint = NSMakePoint(frame.origin.x, NSMaxY(frame));
    }
  cascadePoint = [[doc window] cascadeTopLeftFromPoint:cascadePoint];
  [[doc window] makeKeyAndOrderFront: self];
}

- (void) save: (id)sender
{
  [(GormDocument *)[self activeDocument] saveGormDocument: sender];
}

- (void) saveAs: (id)sender
{
  [(GormDocument *)[self activeDocument] saveAsDocument: sender];
}


- (void) saveAll: (id)sender
{
  NSEnumerator	*enumerator = [documents objectEnumerator];
  id		doc;

  while ((doc = [enumerator nextObject]) != nil)
    {
      if ([[doc window] isDocumentEdited] == YES)
	{
	  if (! [doc saveGormDocument: sender] )
	    NSLog(@"can not save %@",doc);
	}
    }
}


- (void) revertToSaved: (id)sender
{
  id	doc = [(GormDocument *)[self activeDocument] revertDocument: sender];

  if (doc != nil)
    {
      [documents addObject: doc];
      // RELEASE(doc);
      [[doc window] makeKeyAndOrderFront: self];
    }
}

- (void) close: (id)sender
{
  GormDocument  *document = (GormDocument *)[self activeDocument];
  NSWindow	*window = [document window];

  [window performClose: self];
}

- (void) debug: (id) sender
{
  [[self activeDocument] performSelector: @selector(printAllEditors)];
}

- (void) loadSound: (id) sender
{
  [(GormDocument *)[self activeDocument] openSound: sender];
}

- (void) loadImage: (id) sender
{
  [(GormDocument *)[self activeDocument] openImage: sender];
}

- (void) testInterface: (id)sender
{
  if (isTesting == YES)
    {
      return;
    }
  else
    {
      NS_DURING
	{
	  NSUserDefaults	*defaults;
	  NSNotificationCenter	*notifCenter = [NSNotificationCenter defaultCenter];
	  GormDocument		*activeDoc = (GormDocument*)[self activeDocument];
	  NSData		*data;
	  NSArchiver            *archiver;
	  NSEnumerator          *en;
	  id                    obj;

	  // which windows were open when testing started...
	  testingWindows = [[NSMutableArray alloc] init]; 
	  en = [[self windows] objectEnumerator];
	  while((obj = [en nextObject]) != nil)
	    {
	      if([obj isVisible])
		{
		  [testingWindows addObject: obj];
		}
	    }

	  isTesting = YES; // set here, so that beginArchiving and endArchiving do not use templates.
	  [self setApplicationIconImage: testingImage];
	  archiver = [[NSArchiver alloc] init];
	  [activeDoc beginArchiving];
	  [archiver encodeClassName: @"GormCustomView" 
		    intoClassName: @"GormTestCustomView"];
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
	  /*
	  [archiver encodeClassName: @"GormNSBrowser" 
		    intoClassName: @"NSBrowser"];
	  [archiver encodeClassName: @"GormNSTableView" 
		    intoClassName: @"NSTableView"];
	  [archiver encodeClassName: @"GormNSOutlineView" 
		    intoClassName: @"NSOutlineView"];
	  */
	  [GSClassSwapper setIsInInterfaceBuilder: YES]; // do not allow custom classes during testing.
	  [archiver encodeRootObject: activeDoc];
	  data = RETAIN([archiver archiverData]); // Released below... 
	  [activeDoc endArchiving];
	  RELEASE(archiver);
	  [GSClassSwapper setIsInInterfaceBuilder: NO]; // beginal allowing custom classes...
	  
	  [notifCenter postNotificationName: IBWillBeginTestingInterfaceNotification
		       object: self];
	  
	  if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	    {
	      [selectionOwner makeSelectionVisible: NO];
	    }
	  
	  defaults = [NSUserDefaults standardUserDefaults];
	  menuLocations = [[defaults objectForKey: @"NSMenuLocations"] copy];
	  [defaults removeObjectForKey: @"NSMenuLocations"];
	  servicesMenu = [self servicesMenu];
	  
	  testContainer = [NSUnarchiver unarchiveObjectWithData: data];
	  if (testContainer != nil)
	    {
	      NSMutableDictionary *nameTable = [testContainer nameTable];
	      [nameTable removeObjectForKey: @"NSServicesMenu"];
	      [nameTable removeObjectForKey: @"NSWindowsMenu"];
	      [testContainer awakeWithContext: nil];
	      RETAIN(testContainer); // released in endTesting:
	    }
	  
	  /*
	   * If the NIB didn't have a main menu, create one,
	   * otherwise, ensure that 'quit' ends testing mode.
	   */
	  if ([self mainMenu] == mainMenu)
	    {
	      NSMenu	*testMenu;
	      
	      testMenu = [[NSMenu alloc] initWithTitle: _(@"Test Menu (Gorm)")];
	      [testMenu addItemWithTitle: _(@"Quit Test") 
			action: @selector(deferredEndTesting:)
			keyEquivalent: @"q"];	
	      [self setMainMenu: testMenu]; // released, when the menu is reset in endTesting.
	    }
	  else
	    {
	      NSMenu	*testMenu = [self mainMenu];
	      id	 item;
	      NSString  *newTitle = [[testMenu title] stringByAppendingString: @" (Gorm)"];

	      // set the menu up so that it's easy to tell we're testing and how to quit.
	      [testMenu setTitle: newTitle];
	      item = [testMenu itemWithTitle: _(@"Quit")];
	      if (item != nil)
		{
		  [item setTitle: _(@"Quit Test")];
		  [item setAction: @selector(deferredEndTesting:)];
		}
	      else
		{
		  [testMenu addItemWithTitle: _(@"Quit Test") 
			    action: @selector(deferredEndTesting:)
			    keyEquivalent: @"q"];	
		}
	    }

	  // so we don't get the warning...
	  [self setServicesMenu: nil]; 

	  // display the current main menu...
	  [[self mainMenu] display];

	  [notifCenter postNotificationName: IBDidBeginTestingInterfaceNotification
		       object: self];
	  
	  RELEASE(data);
	}
      NS_HANDLER
	{
	  // reset the application after the error.
	  NSLog(@"Error while testing interface: %@", 
		[localException reason]);
	  NSRunAlertPanel(_(@"An Error Occurred"), 
			  [NSString stringWithFormat: 
				      @"Problem testing interface.  Make sure connections are to appropriate objects.  Exception: %@",
				    [localException reason]], 
			  _(@"OK"), nil, nil);
	  [self endTesting: self];
	}
      NS_ENDHANDLER;
    }
}


/** Edit Menu Actions */

- (void) copy: (id)sender
{
  if ([[selectionOwner selection] count] == 0
      || [selectionOwner respondsToSelector: @selector(copySelection)] == NO)
    return;
  
  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner copySelection];
}


- (void) cut: (id)sender
{
  if ([[selectionOwner selection] count] == 0
      || [selectionOwner respondsToSelector: @selector(copySelection)] == NO
      || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner copySelection];
  [(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (void) paste: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(pasteInSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner pasteInSelection];
}


- (void) delete: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;

  if([self isConnecting])
    {
      [self stopConnecting];
    }

  [(id<IBSelectionOwners,IBEditors>)selectionOwner deleteSelection];
}

- (void) selectAllItems: (id)sender
{
  /* TODO: Select all items in the current selection owner. */
  return;
}

- (void) setName: (id)sender
{
  GormSetNameController *panel;
  int		returnPanel;
  NSTextField	*textField;
  NSArray	*selectionArray = [selectionOwner selection];
  id		obj = [selectionArray objectAtIndex: 0];
  NSString	*name;

  if([(GormDocument *)[self activeDocument] isTopLevelObject: obj])
    {
      panel = [GormSetNameController new];
      returnPanel = [panel runAsModal];
      textField = [panel textField];
      
      if (returnPanel == NSAlertDefaultReturn)
	{
	  name = [[textField stringValue] stringByTrimmingSpaces];
	  if (name != nil && [name isEqual: @""] == NO)
	    {
	      [[self activeDocument] setName: name forObject: obj];
	    }
	}
      RELEASE(panel);
    }
}

- (void) guideline: (id) sender
{
  [[NSNotificationCenter defaultCenter] postNotificationName: GormToggleGuidelineNotification
 					object:nil];
  if ( [guideLineMenuItem tag] == 0 ) 
    {
      [guideLineMenuItem setTitle:_(@"Enable GuideLine")];
      [guideLineMenuItem setTag:1];
    }
  else if ( [guideLineMenuItem tag] == 1)
    {
      [guideLineMenuItem setTitle:_(@"Disable GuideLine")];
      [guideLineMenuItem setTag:0];
    }
}


- (void) orderFrontFontPanel: (id) sender
{
  NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
  GormFontViewController *gfvc = 
    [GormFontViewController sharedGormFontViewController];
  [fontPanel setAccessoryView: [gfvc view]];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

/** Grouping */

- (void) groupSelectionInSplitView: (id)sender
{
  if ([[selectionOwner selection] count] < 2
      || [selectionOwner respondsToSelector: @selector(groupSelectionInSplitView)] == NO)
    return;

  [(GormGenericEditor *)selectionOwner groupSelectionInSplitView];
}

- (void) groupSelectionInBox: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInBox)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner groupSelectionInBox];
}

- (void) groupSelectionInScrollView: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInScrollView)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner groupSelectionInScrollView];
}

- (void) ungroup: (id)sender
{
  NSLog(@"ungroup: selectionOwner %@", selectionOwner);
  if ([selectionOwner respondsToSelector: @selector(ungroup)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner ungroup];
}

/** Classes actions */

- (void) createSubclass: (id)sender
{
  [(GormDocument *)[self activeDocument] createSubclass: sender];
}

- (void) loadClass: (id)sender
{
  // Call the current document and create the class 
  // descibed by the header
  [(GormDocument *)[self activeDocument] loadClass: sender];
}

- (void) createClassFiles: (id)sender
{
  [(GormDocument *)[self activeDocument] createClassFiles: sender];
}

- (void) instantiateClass: (id)sender
{
   [(GormDocument *)[self activeDocument] instantiateClass: sender];
}

- (void) addAttributeToClass: (id)sender
{  
  [(GormDocument *)[self activeDocument] addAttributeToClass: sender];
}

- (void) remove: (id)sender
{  
  [(GormDocument *)[self activeDocument] remove: sender];
}

/** Palettes Actions... */

- (void) inspector: (id) sender
{
  [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
}

- (void) palettes: (id) sender
{
  [[[self palettesManager] panel] makeKeyAndOrderFront: self];
}

- (void) loadPalette: (id) sender
{
  [[self palettesManager] openPalette: sender];
}

/** Testing methods... */

- (void) deferredEndTesting: (id) sender
{
  [[NSRunLoop currentRunLoop]
    performSelector: @selector(endTesting:)
    target: self
    argument: nil
    order: 5000
    modes: [NSArray arrayWithObjects:
		      NSDefaultRunLoopMode,
		    NSModalPanelRunLoopMode,
		    NSEventTrackingRunLoopMode, nil]];
}

- (id) endTesting: (id)sender
{
  if (isTesting == NO)
    {
      return nil;
    }
  else
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSUserDefaults		*defaults;
      NSEnumerator		*e;
      id			val;

      CREATE_AUTORELEASE_POOL(pool);

      [nc postNotificationName: IBWillEndTestingInterfaceNotification
			object: self];

      /*
       * Make sure windows will go away when the container is destroyed.
       */
      e = [[testContainer nameTable] objectEnumerator];
      while ((val = [e nextObject]) != nil)
	{
	  if ([val isKindOfClass: [NSWindow class]] == YES)
	    {
	      [val close];
	    }
	}

      /*
       * Make sure any peripheral windows: font panels, etc. which are brought
       * up by the interface being tested are also closed.
       */
      e = [[self windows] objectEnumerator];
      while ((val = [e nextObject]) != nil)
	{
	  if ([testingWindows containsObject: val] == NO && 
	      [val isKindOfClass: [NSWindow class]] &&
	      [val isVisible])
	    {
	      [val orderOut: self];
	    }
	}

      // prevent saving of this, if the menuLocations have not previously been set.
      if(menuLocations != nil)
	{
	  defaults = [NSUserDefaults standardUserDefaults];
	  [defaults setObject: menuLocations forKey: @"NSMenuLocations"];
	  DESTROY(menuLocations);
	}

      [self setMainMenu: mainMenu];
      [self setApplicationIconImage: gormImage];

      NS_DURING
	{
	  [self setServicesMenu: servicesMenu];
	}
      NS_HANDLER
	{
	  NSDebugLog(@"Exception while setting services menu");
	}
      NS_ENDHANDLER

      [mainMenu display]; // bring it to the front...

      isTesting = NO;

      if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	{
	  [selectionOwner makeSelectionVisible: YES];
	}
      [nc postNotificationName: IBDidEndTestingInterfaceNotification
			object: self];
      

      DESTROY(testingWindows);

      RELEASE(pool);

      return self;
    }
}

- (void) finishLaunching
{
  NSBundle		*bundle;
  NSString		*path;

  /*
   * establish registration domain defaults from file.
   */
  bundle = [NSBundle mainBundle];
  path = [bundle pathForResource: @"Defaults" ofType: @"plist"];
  if (path != nil)
    {
      NSDictionary	*dict;

      dict = [NSDictionary dictionaryWithContentsOfFile: path];
      if (dict != nil)
	{
	  NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];

	  [defaults registerDefaults: dict];
	}
    }

  [self setDelegate: self];
  [super finishLaunching];
}

- (void) handleNotification: (NSNotification*)notification
{
  NSString	*name = [notification name];
  id		obj = [notification object];

  if ([name isEqual: IBSelectionChangedNotification])
    {
      /*
       * If we are connecting - stop it - a change in selection must mean
       * that the connection process has ended.
       */
      if ([self isConnecting] == YES)
	{
	  [self stopConnecting];
	}
      [selectionOwner makeSelectionVisible: NO];
      selectionOwner = obj;
      [[self inspectorsManager] updateSelection];
    }
  else if ([name isEqual: IBWillCloseDocumentNotification])
    {
      [documents removeObjectIdenticalTo: obj];
    }
}

- (void) awakeFromNib
{
  // set the menu...
  mainMenu = (NSMenu *)gormMenu;
  //for cascadePoint
  cascadePoint = NSZeroPoint;
}


- (GormInspectorsManager*) inspectorsManager
{
  if (inspectorsManager == nil)
    {
      inspectorsManager = (GormInspectorsManager *)[GormInspectorsManager sharedInspectorManager];
    }
  return inspectorsManager;
}


- (BOOL) isConnecting
{
  return isConnecting;
}

- (BOOL) isTestingInterface
{
  return isTesting;
}

- (NSImage*) linkImage
{
  return linkImage;
}


- (id) miniaturize: (id)sender
{
  NSWindow	*window = [(GormDocument *)[self activeDocument] window];

  [window miniaturize: self];
  return nil;
}



- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
  GormDocument	*doc = AUTORELEASE([GormDocument new]);

  [documents addObject: doc];
  if ([doc loadDocument: fileName] == nil)
    {
      [documents removeObjectIdenticalTo: doc];
      doc = nil;
    }
  else
    {
      [[doc window] orderFrontRegardless];
      [[doc window] makeKeyWindow];
    }
  
  return (doc != nil);
}

- (GormPalettesManager*) palettesManager
{
  if (palettesManager == nil)
    {
      palettesManager = [GormPalettesManager new];
    }
  return palettesManager;
}

- (id<IBSelectionOwners>) selectionOwner
{
  return (id<IBSelectionOwners>)selectionOwner;
}

- (id) selectedObject
{
  return [[selectionOwner selection] lastObject];
} 


- (void) startConnecting
{
  if (isConnecting == YES)
    {
      return;
    }
  if (connectDestination == nil || connectSource == nil)
    {
      return;
    }
  if ([[self activeDocument] containsObject: connectDestination] == NO)
    {
      NSLog(@"Oops - connectDestination not in active document");
      return;
    }
  if ([[self activeDocument] containsObject: connectSource] == NO)
    {
      NSLog(@"Oops - connectSource not in active document");
      return;
    }
  isConnecting = YES;
  [[self inspectorsManager] updateSelection];
}

- (void) stopConnecting
{
  [self displayConnectionBetween: nil and: nil];
  isConnecting = NO;
  connectSource = nil;
  connectDestination = nil;
}

- (BOOL) validateMenuItem: (NSMenuItem*)item
{
  GormDocument	*active = (GormDocument*)[self activeDocument];
  SEL		action = [item action];
  GormClassManager *cm = [active classManager];
  NSArray	*s = [selectionOwner selection];

  // temporarily disabling this functionality....
  /*
  if (sel_eq(action, @selector(loadClass:)))
    {
      return NO;
    }
  */

  if (sel_eq(action, @selector(close:))
    || sel_eq(action, @selector(miniaturize:))
    || sel_eq(action, @selector(save:))
    || sel_eq(action, @selector(saveAs:))
    || sel_eq(action, @selector(saveAll:)))
    {
      if (active == nil)
	return NO;
    }
  else if (sel_eq(action, @selector(revertToSaved:)))
    {
      if (active == nil || [active documentPath] == nil
	|| [[active window] isDocumentEdited] == NO)
	return NO;
    }
  else if (sel_eq(action, @selector(testInterface:)))
    {
      if (active == nil)
	return NO;
    }
  else if (sel_eq(action, @selector(copy:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	    o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return [selectionOwner respondsToSelector: @selector(copySelection)];
    }
  else if (sel_eq(action, @selector(cut:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	    o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return ([selectionOwner respondsToSelector: @selector(copySelection)]
	&& [selectionOwner respondsToSelector: @selector(deleteSelection)]);
    }
  else if (sel_eq(action, @selector(delete:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	    o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return [selectionOwner respondsToSelector: @selector(deleteSelection)];
    }
  else if (sel_eq(action, @selector(paste:)))
    {
      if ([s count] == 0)
	return NO;
      else
	{
	  id	o = [s objectAtIndex: 0];
	  NSString *n = [active nameForObject: o];
	  if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"])
	    {
	      return NO;
	    }
	}

      return [selectionOwner respondsToSelector: @selector(pasteInSelection)];
    }
  else if (sel_eq(action, @selector(setName:)))
    {
      NSString	*n;
      id	o;

      if ([s count] == 0)
	{
	  return NO;
	}
      if ([s count] > 1)
	{
	  return NO;
	}
      o = [s objectAtIndex: 0];
      n = [active nameForObject: o];

      if ([n isEqual: @"NSOwner"] || [n isEqual: @"NSFirst"]
	|| [n isEqual: @"NSFont"] || [n isEqual: @"NSMenu"])
	{
	  return NO;
	}
      else if(![active isTopLevelObject: o])
	{
	  return NO;
	}
    }
  else if(sel_eq(action, @selector(createSubclass:)) ||
	  sel_eq(action, @selector(loadClass:)) ||
	  sel_eq(action, @selector(createClassFiles:)) ||
	  sel_eq(action, @selector(instantiateClass:)) ||
	  sel_eq(action, @selector(addAttributeToClass:)) ||
	  sel_eq(action, @selector(remove:)))
    {
      if(active == nil)
	{
	  return NO;
	}

      if(![active isEditingClasses])
	{
	  return NO;
	}

      if(sel_eq(action, @selector(createSubclass:)))
	{
	  NSArray *s = [selectionOwner selection];
	  id o = nil;
	  NSString *name = nil;

	  if([s count] == 0 || [s count] > 1)
	    return NO;
	  
	  o = [s objectAtIndex: 0];
	  name = [o className];

	  if([active classIsSelected] == NO)
	    {
	      return NO;
	    }
	  
	  if([name isEqual: @"FirstResponder"])
	    return NO;
	}
      
      if(sel_eq(action, @selector(createClassFiles:)) || 
	 sel_eq(action, @selector(remove:)))
	{
	  id o = nil;
	  NSString *name = nil;

	  if ([s count] == 0)
	    {
	      return NO;
	    }
	  if ([s count] > 1)
	    {
	      return NO;
	    }

	  o = [s objectAtIndex: 0];
	  name = [o className];
	  if(![cm isCustomClass: name])
	    {
	      return NO;
	    }

	  // if([name isEqual: @"FirstResponder"])
	  //   return NO;
	}

      if(sel_eq(action, @selector(instantiateClass:)))
	{
	  id o = nil;
	  NSString *name = nil;

	  if ([s count] == 0)
	    {
	      return NO;
	    }
	  if ([s count] > 1)
	    {
	      return NO;
	    }
	  
	  if([active classIsSelected] == NO)
	    {
	      return NO;
	    }
	  
	  o = [s objectAtIndex: 0];
	  name = [o className];
	  if(name != nil)
	    {
	      id cm = [self classManager];
	      return [cm canInstantiateClassNamed: name];
	    }
	}
    }
  else if(sel_eq(action, @selector(loadSound:)) ||
	  sel_eq(action, @selector(loadImage:)) ||
	  sel_eq(action, @selector(debug:)))
    {
      if(active == nil)
	{
	  return NO;
	}
    }

  return YES;
}

- (NSMenu*) classMenu
{
  return classMenu;
}

- (void) unhide: (id)sender
{
  [super unhide: sender];
  if(!isTesting)
    {
      id document = [self activeDocument];
      id window = [document window];
      [(GormDocument *)document setDocumentActive: NO];
      [(GormDocument *)document setDocumentActive: YES];
      [window orderFront: sender];
      [[self mainMenu] display];
    }
}

- (BOOL) documentNameIsUnique: (NSString *)filename
{
  NSEnumerator *en = [documents objectEnumerator];
  id document;
  BOOL unique = YES;

  while((document = [en nextObject]) != nil)
    {
      NSString *docPath = [document documentPath];
      if([docPath isEqual: filename])
	{
	  unique = NO;
	  break;
	}
    }
  
  return unique;
}
@end

// custom class additions...
@implementation GSClassSwapper (GormCustomClassAdditions)
+ (void) setIsInInterfaceBuilder: (BOOL)flag
{
  _isInInterfaceBuilder = flag;
}

- (BOOL) isInInterfaceBuilder
{
  return _isInInterfaceBuilder;
}
@end

// these are temporary until the deprecated templates are removed...
////////////////////////////////////////////////////////
// DEPRECATED TEMPLATES                               //
////////////////////////////////////////////////////////
@interface NSWindowTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSWindowTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSTextTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSTextTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSTextViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSTextViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSMenuTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSMenuTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSControlTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSControlTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSButtonTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSButtonTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end
////////////////////////////////////////////////////////
// END OF DEPRECATED TEMPLATES                        //
////////////////////////////////////////////////////////


