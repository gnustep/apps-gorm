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

// for templates...
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>

NSDate	*startDate;
NSString *GormToggleGuidelineNotification = @"GormToggleGuidelineNotification";
NSString *GormDidModifyClassNotification = @"GormDidModifyClassNotification";
NSString *GormDidAddClassNotification = @"GormDidAddClassNotification";
NSString *GormDidDeleteClassNotification = @"GormDidDeleteClassNotification";
NSString *GormWillDetachObjectFromDocumentNotification = @"GormWillDetachObjectFromDocumentNotification";
NSString *GormResizeCellNotification = @"GormResizeCellNotification";

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
      /* FIXME/TODO.  What do we do if we are an attributed string.  
         Think about what happens when the user ends editing. 
         Allows editing text attributes... Formatter... TODO. */
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
      //NSLog(@"Decoding proxy : %@", theClass);
      RETAIN(theClass); 
      
      return self; 
    }
  else if (version == 1)
    {
      // do not decode super (it would try to morph into theClass ! )
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      [aCoder decodeValueOfObjCType: @encode(unsigned int) 
	      at: &autoresizingMask];  
      //NSLog(@"Decoding proxy : %@", theClass);
      RETAIN(theClass); 
      
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
       result = NSRunAlertPanel(NULL, _(@"There are edited windows"),
				_(@"Review Unsaved"),_( @"Quit Anyway"), _(@"Cancel"));
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


/***********************************************************************/
/***********************   Info Menu Actions****************************/
/***********************************************************************/

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
	  window = [[self activeDocument] windowAndRect: &rect
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
	  window = [[self activeDocument] windowAndRect: &rect
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
      window = [[self activeDocument] windowAndRect: &rect forObject: connectSource];
      if (window != nil)
	{
	  NSView	*view = [[window contentView] superview];
	  
	  rect.origin.x++;
	  rect.size.width--;
	  rect.size.height--;
	  [view lockFocus];
	  [[NSColor greenColor] set];
	  NSFrameRectWithWidth(rect, 2);
	  
	  [sourceImage compositeToPoint: rect.origin
			      operation: NSCompositeSourceOver];
	  [view unlockFocus];
	  [window flushWindow];
	}
    }
  if (connectDestination != nil && connectDestination == connectSource)
    {
      window = [[self activeDocument] windowAndRect: &rect
				     forObject: connectDestination];
      if (window != nil)
	{
	  NSView	*view = [[window contentView] superview];

	  rect.origin.x += 3;
	  rect.origin.y += 2;
	  rect.size.width -= 5;
	  rect.size.height -= 5;
	  [view lockFocus];
	  [[NSColor purpleColor] set];
	  NSFrameRectWithWidth(rect, 2);
	  
	  rect.origin.x += [targetImage size].width;
	  [targetImage compositeToPoint: rect.origin
			      operation: NSCompositeSourceOver];
	  [view unlockFocus];
	  [window flushWindow];
	}
    }
  else if (connectDestination != nil)
    {
      window = [[self activeDocument] windowAndRect: &rect
				      forObject: connectDestination];
      if (window != nil)
	{
	  NSView	*view = [[window contentView] superview];

	  rect.origin.x++;
	  rect.size.width--;
	  rect.size.height--;
	  [view lockFocus];
	  [[NSColor purpleColor] set];
	  NSFrameRectWithWidth(rect, 2);
	  
	  [targetImage compositeToPoint: rect.origin
			      operation: NSCompositeSourceOver];
	  [view unlockFocus];
	  [window flushWindow];
	}
    }
}



/***********************************************************************/
/*********************** Info Menu Actions  ****************************/
/***********************************************************************/

- (void) infoPanel: (id) sender
{
  NSMutableDictionary *dict;
  
  dict = [NSMutableDictionary dictionaryWithCapacity: 8];
  [dict setObject: @"Gorm" 
     forKey: @"ApplicationName"];
  [dict setObject: @"[GNUstep | Graphical] Object Relationship Modeller"
     forKey: @"ApplicationDescription"];
  [dict setObject: @"Gorm 0.7.6 (Alpha)" 
     forKey: @"ApplicationRelease"];
  [dict setObject: @"0.7.6 Apr 14 2004" 
     forKey: @"FullVersionID"];
  [dict setObject: [NSArray arrayWithObjects: @"Gregory John Casamento <greg_casamento@yahoo.com>",
			 @"Richard Frith-Macdonald <rfm@gnu.org>",
			 @"Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>",
			 nil]
     forKey: @"Authors"];
  [dict setObject: @"Copyright (C) 1999, 2000, 2001, 2002, 2003 Free Software Foundation, Inc."
     forKey: @"Copyright"];
  [dict setObject: @"Released under the GNU General Public License 2.0"
     forKey: @"CopyrightDescription"];
  
  [self orderFrontStandardInfoPanelWithOptions: dict];
}


- (void) preferencesPanel: (id) sender
{
  if(! preferencesController)
    {
      preferencesController =  [[GormPrefController alloc] initWithWindowNibName:@"GormPreferences"];
    }

  [[preferencesController window] makeKeyAndOrderFront:nil];
}


/***********************************************************************/
/***********************  Document Menu Actions*************************/
/***********************************************************************/
- (void) open: (id) sender
{
  GormDocument	*doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
  if ([doc openDocument: sender] == nil)
    {
      [documents removeObjectIdenticalTo: doc];
      doc = nil;
    }
  else
    {
      // NSDictionary *nameTable = [doc nameTable];
      // NSEnumerator *enumerator = [nameTable keyEnumerator];
      // NSString *key = nil;

      // order everything front.
      [[doc window] makeKeyAndOrderFront: self];

      /*
      // the load is completed, awaken all of the elements.
      while ((key = [enumerator nextObject]) != nil)
	{
	  id o = [nameTable objectForKey: key];
	  if ([o respondsToSelector: @selector(awakeFromDocument:)])
	    {
	      [o awakeFromDocument: doc];
	    }
	}
      */
    }
}


//include Modules Menu
- (void) newGormDocument : (id) sender 
{
  id doc = [GormDocument new];
  [documents addObject: doc];
  RELEASE(doc);
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
      [[doc window] makeKeyAndOrderFront: self];
    }
}

- (void) close: (id)sender
{
  NSWindow	*window = [(GormDocument *)[self activeDocument] window];

  [window setReleasedWhenClosed: YES];
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
	  NSUserDefaults		*defaults;
	  NSNotificationCenter	*notifCenter = [NSNotificationCenter defaultCenter];
	  GormDocument		*activDoc = (GormDocument*)[self activeDocument];
	  NSData			*data;
	  NSArchiver                *archiver;
	  
	  
	  isTesting = YES; // set here, so that beginArchiving and endArchiving do not use templates.
	  archiver = [[NSArchiver alloc] init];
	  [activDoc beginArchiving];
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
	  [archiver encodeClassName: @"GormNSBrowser" 
		    intoClassName: @"NSBrowser"];
	  [archiver encodeClassName: @"GormNSTableView" 
		    intoClassName: @"NSTableView"];
	  [archiver encodeClassName: @"GormNSOutlineView" 
		    intoClassName: @"NSOutlineView"];
	  [archiver encodeRootObject: activDoc];
	  data = RETAIN([archiver archiverData]);
	  [activDoc endArchiving];
	  RELEASE(archiver);
	  
	  [notifCenter postNotificationName: IBWillBeginTestingInterfaceNotification
		       object: self];
	  
	  if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	    {
	      [selectionOwner makeSelectionVisible: NO];
	    }
	  
	  defaults = [NSUserDefaults standardUserDefaults];
	  menuLocations = [[defaults objectForKey: @"NSMenuLocations"] copy];
	  [defaults removeObjectForKey: @"NSMenuLocations"];
	  
	  testContainer = [NSUnarchiver unarchiveObjectWithData: data];
	  if (testContainer != nil)
	    {
	      [testContainer awakeWithContext: nil
			     topLevelItems: nil];
	      RETAIN(testContainer);
	    }
	  
	  /*
	   * If the NIB didn't have a main menu, create one,
	   * otherwise, ensure that 'quit' ends testing mode.
	   */
	  if ([self mainMenu] == mainMenu)
	    {
	      NSMenu	*testMenu;
	      
	      testMenu = [[NSMenu alloc] initWithTitle: _(@"Test")];
	      [testMenu addItemWithTitle: _(@"Quit") 
			action: @selector(deferredEndTesting:)
			keyEquivalent: @"q"];	
	      [self setMainMenu: testMenu];
	      RELEASE(testMenu);
	    }
	  else
	    {
	      NSMenu	*testMenu = [self mainMenu];
	      id		item;
	      
	      item = [testMenu itemWithTitle: _(@"Quit")];
	      if (item != nil)
		{
		  [item setAction: @selector(deferredEndTesting:)];
		}
	      else
		{
		  [testMenu addItemWithTitle: _(@"Quit") 
			    action: @selector(deferredEndTesting:)
			    keyEquivalent: @"q"];	
		}
	    }
	  
	  [notifCenter postNotificationName: IBDidBeginTestingInterfaceNotification
		       object: self];
	  
	  RELEASE(data);
	}
      NS_HANDLER
	{
	  // reset the application after the error.
	  NSLog(@"Error while testing interface: %@", 
		[localException reason]);
	  [self endTesting: self];
	}
      NS_ENDHANDLER;
    }
}


/***********************************************************************/
/***********************   Edit Menu Actions*****************************/
/***********************************************************************/

- (void) copy: (id)sender
{
  if ([[selectionOwner selection] count] == 0
      || [selectionOwner respondsToSelector: @selector(copySelection)] == NO)
    return;
  
  [(GormGenericEditor *)selectionOwner copySelection];
}


- (void) cut: (id)sender
{
  if ([[selectionOwner selection] count] == 0
      || [selectionOwner respondsToSelector: @selector(copySelection)] == NO
      || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner copySelection];
  [(GormGenericEditor *)selectionOwner deleteSelection];
}

- (void) paste: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(pasteInSelection)] == NO)
    return;

  [(GormGenericEditor *)selectionOwner pasteInSelection];
}


- (void) delete: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return;
  [(GormGenericEditor *)selectionOwner deleteSelection];
}

- (void) selectAllItems: (id)sender
{
  /* FIXME */
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

/***********************************************************************/
/***********************   Group Action  *******************************/
/***********************************************************************/

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



/***********************************************************************/
/***********************   Classes Action  *******************************/
/***********************************************************************/

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

/*
- (id) editClass: (id)sender
{
  [self inspector: self];
  return [(id)[self activeDocument] editClass: sender];
}
*/


/***********************************************************************/
/***********************   Classes Action  *******************************/
/***********************************************************************/

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

      // prevent saving of this, if the menuLocations have not previously been set.
      if(menuLocations != nil)
	{
	  defaults = [NSUserDefaults standardUserDefaults];
	  [defaults setObject: menuLocations forKey: @"NSMenuLocations"];
	  DESTROY(menuLocations);
	}

      [self setMainMenu: mainMenu];

      isTesting = NO;

      if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	{
	  [selectionOwner makeSelectionVisible: YES];
	}
      [nc postNotificationName: IBDidEndTestingInterfaceNotification
			object: self];
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
  NSDebugLog(@"StartupTime %f", [startDate timeIntervalSinceNow]);
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
      RETAIN(obj);
      [documents removeObjectIdenticalTo: obj];
      AUTORELEASE(obj);
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
      inspectorsManager = [GormInspectorsManager new];
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
  GormDocument	*doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
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
}


- (BOOL) validateMenuItem: (NSMenuItem*)item
{
  GormDocument	*active = (GormDocument*)[self activeDocument];
  SEL		action = [item action];
  GormClassManager *cm = [active classManager];

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
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return [selectionOwner respondsToSelector: @selector(copySelection)];
    }
  else if (sel_eq(action, @selector(cut:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return ([selectionOwner respondsToSelector: @selector(copySelection)]
	&& [selectionOwner respondsToSelector: @selector(deleteSelection)]);
    }
  else if (sel_eq(action, @selector(delete:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return [selectionOwner respondsToSelector: @selector(deleteSelection)];
    }
  else if (sel_eq(action, @selector(paste:)))
    {
      return [selectionOwner respondsToSelector: @selector(pasteInSelection)];
    }
  else if (sel_eq(action, @selector(setName:)))
    {
      NSArray	*s = [selectionOwner selection];
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

      
      if(sel_eq(action, @selector(addAttributeToClass:)) ||
	 sel_eq(action, @selector(createClassFiles:)) || 
	 sel_eq(action, @selector(remove:)))
	{
	  NSArray *s = [selectionOwner selection];
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
	}
      if(sel_eq(action, @selector(instantiateClass:)))
	{
	  NSArray *s = [selectionOwner selection];
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
	  if(name != nil)
	    {
	      id cm = [self classManager];
	      // there are some classes which can't be instantiated directly
	      // in Gorm.
	      if([cm isSuperclass: @"NSApplication" linkedToClass: name] || 
		 [name isEqualToString: @"NSApplication"])
		{
		  return NO;
		}
	      if([cm isSuperclass: @"NSCell" linkedToClass: name] || 
		 [name isEqualToString: @"NSCell"])
		{
		  return NO;
		}
	      else if([name isEqualToString: @"NSDocument"])
		{
		  return NO;
		}
	      else if([name isEqualToString: @"NSDocumentController"])
		{
		  return NO;
		}
	      else if([name isEqualToString: @"NSFontManager"])
		{
		  return NO;
		}
	      else if([name isEqualToString: @"NSHelpManager"])
		{
		  return NO;
		}
	      else if([name isEqualToString: @"NSImage"])
		{
		  return NO;
		}
	      else if([cm isSuperclass: @"NSMenuItem" linkedToClass: name] || 
		      [name isEqualToString: @"NSMenuItem"])
		{
		  return NO;
		}
	      else if([name isEqualToString: @"NSResponder"])
		{
		  return NO;
		}
	      else if([cm isSuperclass: @"NSSound" linkedToClass: name] || 
		      [name isEqualToString: @"NSSound"])
		{
		  return NO;
		}
	      else if([cm isSuperclass: @"NSTableColumn" linkedToClass: name] || 
		      [name isEqualToString: @"NSTableColumn"])
		{
		  return NO;
		}
	      else if([cm isSuperclass: @"NSTableViewItem" linkedToClass: name] || 
		      [name isEqualToString: @"NSTableViewItem"])
		{
		  return NO;
		}
	      else if([cm isSuperclass: @"NSWindow" linkedToClass: name] || 
		      [name isEqualToString: @"NSWindow"])
		{
		  return NO;
		}
	      else if([cm isSuperclass: @"FirstResponder" linkedToClass: name] || 
		      [name isEqualToString: @"FirstResponder"])
		{
		  // special case, FirstResponder.
		  return NO;
		}

	      NSDebugLog(@"Selection is %@",name);
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
  id document = [self activeDocument];
  id window = [document window];

  [super unhide: sender];
  [(GormDocument *)document setDocumentActive: NO];
  [(GormDocument *)document setDocumentActive: YES];
  [window orderFront: sender];
}
@end

// custom class additions...
@interface GSClassSwapper (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end

@implementation GSClassSwapper (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
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

// main...
int 
main(int argc, const char **argv)
{ 
  startDate = [[NSDate alloc] init];
  return NSApplicationMain(argc, argv);
}

