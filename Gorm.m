/* Gorm.m
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

// for templates...
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>

NSString *IBWillBeginTestingInterfaceNotification
  = @"IBWillBeginTestingInterfaceNotification";
NSString *IBDidBeginTestingInterfaceNotification
  = @"IBDidBeginTestingInterfaceNotification";
NSString *IBWillEndTestingInterfaceNotification
  = @"IBWillEndTestingInterfaceNotification";
NSString *IBDidEndTestingInterfaceNotification
  = @"IBDidEndTestingInterfaceNotification";

NSDate	*startDate;

NSString *GormLinkPboardType = @"GormLinkPboardType";

@class	InfoPanel;

// we had this include for grouping/ungrouping selectors
#import "GormViewWithContentViewEditor.h"

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
@end

// add methods to all of the template objects for use
// in Gorm.
static NSButtonType _buttonTypeForObject( id button )
{
  NSButtonCell *cell;
  NSButtonType type;
  int highlight, stateby;

  /* We could be passed the button or the cell */
  cell = ([button isKindOfClass: [NSButton class]]) ? [button cell] : button;

  highlight = [cell highlightsBy];
  stateby = [cell showsStateBy];
  NSDebugLog(@"highlight = %d, stateby = %d",
    [cell highlightsBy],[cell showsStateBy]);
  
  type = NSMomentaryPushButton;
  if (highlight == NSChangeBackgroundCellMask)
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryLight;
      else 
	type = NSOnOffButton;
    }
  else if (highlight == (NSPushInCellMask | NSChangeGrayCellMask))
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryPushButton;
      else
	type = NSPushOnPushOffButton;
    }
  else if (highlight == (NSPushInCellMask | NSContentsCellMask))
    {
      type = NSToggleButton;
    }
  else if (highlight == NSContentsCellMask)
    {
      if (stateby == NSNoCellMask)
	type = NSMomentaryChangeButton;
      else
	type = NSToggleButton; /* Really switch or radio. What should it be? */
    }
  else
    {
      NSDebugLog(@"Ack! no button type");
    }
  return type;
}

@implementation NSWindowTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  NSLog(@"Creating the new object...");
  [super init];
  [self setBackgroundColor: [object backgroundColor]];
  [self setContentView: [object contentView]];
  [self setFrameAutosaveName: [object frameAutosaveName]];
  [self setHidesOnDeactivate: [object hidesOnDeactivate]];
  [self setInitialFirstResponder: [object initialFirstResponder]];
  [self setAutodisplay: [object isAutodisplay]];
  [self setReleasedWhenClosed: [object isReleasedWhenClosed]];
  [self _setVisible: [object isVisible]];
  [self setTitle: [object title]];
  [self setFrame: [object frame] display: NO];
  [self setClassName: name];
  [object setContentView: nil];
  [self update];
  [object update];
  // [self setDeferFlag: [[(Gorm)NSApp activeDocument] isWindowDeferred: object]];

  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end

@implementation NSViewTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  // call the super constructor
  [self initWithFrame: [object frame]];

  // set the attributes for the view
  [self setBounds: [object bounds]];

  [self setClassName: name];
  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end

@implementation NSControlTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  // call the super constructor
  [self initWithFrame: [object frame]];

  // set the attributes for the view
  [self setBounds: [object bounds]];
  
  // set the attributes for the control
  [self setDoubleValue: [object doubleValue]];
  [self setFloatValue: [object floatValue]];
  [self setIntValue: [object intValue]];
  [self setObjectValue: [object objectValue]];
  [self setStringValue: [object stringValue]];
  [self setTag: [object tag]];
  [self setFont: [object font]];
  [self setAlignment: [object alignment]];
  [self setEnabled: [object isEnabled]];
  [self setContinuous: [object isContinuous]];

  // since only some controls have delegates, we need to test...
  if([object respondsToSelector: @selector(delegate)])
      _delegate = [object delegate];

  // since only some controls have data sources, we need to test...
  if([object respondsToSelector: @selector(dataSource)])
      _dataSource = [object dataSource];

  // since only some controls have data sources, we need to test...
  if([object respondsToSelector: @selector(usesDataSource)])
      _usesDataSource = [object usesDataSource];

  [self setClassName: name];
  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end

@implementation NSButtonTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  // call the super constructor
  [self initWithFrame: [object frame]];

  // set the attributes for the view
  [self setBounds: [object bounds]];

  // set the attributes for the control
  [self setDoubleValue: [object doubleValue]];
  [self setFloatValue: [object floatValue]];
  [self setIntValue: [object intValue]];
  [self setObjectValue: [object objectValue]];
  [self setStringValue: [object stringValue]];
  [self setTag: [object tag]];
  [self setFont: [object font]];
  [self setAlignment: [object alignment]];
  [self setEnabled: [object isEnabled]];
  [self setContinuous: [object isContinuous]];

  // set up template
  _buttonType = _buttonTypeForObject( object );
  [self setButtonType: _buttonType];
  [self setBezelStyle: [object bezelStyle]];
  [self setBordered: [object isBordered]];
  [self setAllowsMixedState: [object allowsMixedState]];
  [self setTitle: [object title]];
  [self setAlternateTitle: [object alternateTitle]];
  [self setImage: [object image]];
  [self setAlternateImage: [object alternateImage]];
  [self setImagePosition: [object imagePosition]];
  [self setKeyEquivalent: [object keyEquivalent]];

  [self setClassName: name];
  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end


@implementation NSTextTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  // call the super constructor
  [self initWithFrame: [object frame]];

  // set the attributes for the view
  [self setBounds: [object bounds]];

  // set the attributes for text
  [self setBackgroundColor: [object backgroundColor]];
  [self setDrawsBackground: [object drawsBackground]];
  [self setEditable: [object isEditable]];
  [self setSelectable: [object isSelectable]];
  [self setFieldEditor: [object isFieldEditor]];
  [self setRichText: [object isRichText]];
  [self setImportsGraphics: [object importsGraphics]];
  [self setDelegate: [object delegate]];

  [self setClassName: name];
  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end

@implementation NSTextViewTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  // call the super constructor
  [self initWithFrame: [object frame]];

  // set the attributes for the view
  [self setBounds: [object bounds]];
  [self setFrame: [object frame]];

  // set the attributes for text
  [self setBackgroundColor: [object backgroundColor]];
  [self setDrawsBackground: [object drawsBackground]];
  [self setEditable: [object isEditable]];
  [self setSelectable: [object isSelectable]];
  [self setFieldEditor: [object isFieldEditor]];
  [self setRichText: [object isRichText]];
  [self setImportsGraphics: [object importsGraphics]];
  [self setDelegate: [object delegate]];

  // text view
  [self setRulerVisible: [object isRulerVisible]];
  [self setInsertionPointColor: [object insertionPointColor]];

  [self setClassName: name];
  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end

@implementation NSMenuTemplate (GormCustomClassAdditions)
- (id) initWithObject: (id)object
	    className: (NSString *)name
{
  // copy attributes
  [self setAutoenablesItems: [object autoenablesItems]];
  [self setTitle: [object title]];

  [self setClassName: name];
  _parentClassName = NSStringFromClass([object class]);
  return self;
}
@end

@implementation NSObject (GormCustomClassAdditions)
+ (BOOL) canSubstituteForClass: (Class)aClass
{
  // only for now...
  return NO;
}
@end

// Gorm template subclasses to allow persisting and unpersisting from Gorm w/o the
// class trying to transform itself into the custom class instance.  Instead the
// class will transform itself into the appropriate parent class which Gorm knows
// about.
@implementation GormNSWindowTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  return obj; 
}
@end

@implementation GormNSViewTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  return obj;
}
@end

@implementation GormNSTextTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  return obj;
}
@end

@implementation GormNSControlTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  NSString *name = [[(Gorm *)NSApp activeDocument] nameForObject: self];
  NSLog(@"**** NAME: %@",name);
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  return obj;
}
@end

@implementation GormNSButtonTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  NSString *name = [[(Gorm *)NSApp activeDocument] nameForObject: self];
  NSLog(@"**** NAME: %@ %@",name, self);   
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  NSLog(@"********  OBJECT: %@",obj);
  return obj;
}
@end

@implementation GormNSTextViewTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  return obj;
}
@end

@implementation GormNSMenuTemplate
- awakeAfterUsingCoder: (NSCoder *)coder
{
  id obj = nil;
  [self setClassName: _parentClassName];
  obj = RETAIN([self instantiateObject: coder]);
  return obj;
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
  return [self classInspectorClassName];
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

- (void) applicationDidFinishLaunching: (NSApplication*)sender
{
  if ( [[NSUserDefaults standardUserDefaults] boolForKey: @"ShowInspectors"] )
    {
      [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
    }
  if ( [[NSUserDefaults standardUserDefaults] boolForKey: @"ShowPalettes"] )
    {
      [[[self palettesManager] panel] makeKeyAndOrderFront: self];
    }
}


- (void) applicationWillTerminate: (NSApplication*)sender
{
  [[NSUserDefaults standardUserDefaults] 
    setBool: [[[self inspectorsManager] panel] isVisible]
    forKey: @"ShowInspectors"];
  [[NSUserDefaults standardUserDefaults] 
    setBool: [[[self palettesManager] panel] isVisible]
    forKey: @"ShowPalettes"];
}

- (BOOL) applicationShouldTerminate: (NSApplication*)sender
{
  NSEnumerator	*enumerator = [[self windows] objectEnumerator];
  NSWindow	*win;
  BOOL		edited = NO;

  if (isTesting == YES)
    {
      [self endTesting: sender];
      return NO;
    }

  while ((win = [enumerator nextObject]) != nil)
    {
      if ([win isDocumentEdited] == YES)
	{
	  edited = YES;
	}
    }
  if (edited == YES)
    {
      int	result;

      result = NSRunAlertPanel(NULL, @"There are edited windows",
	@"Review Unsaved", @"Cancel", @"Quit Anyway");
      if (result == NSAlertAlternateReturn)
	{
	  return NO;
	}
      else if (result != NSAlertOtherReturn)
	{
	  enumerator = [[self windows] objectEnumerator];
	  while ((win = [enumerator nextObject]) != nil)
	    {
	      if ([win isDocumentEdited] == YES)
		{
		  [win performClose: self];
		}
	    }
	}
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

- (id) close: (id)sender
{
  NSWindow	*window = [(id)[self activeDocument] window];

  [window setReleasedWhenClosed: YES];
  [window performClose: self];
  return nil;
}

- (id) copy: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(copySelection)] == NO)
    return nil;
  [selectionOwner copySelection];
  return self;
}

- (id) connectDestination
{
  return connectDestination;
}

- (id) connectSource
{
  return connectSource;
}

- (id) createSubclass: (id)sender
{
  return [(id)[self activeDocument] createSubclass: sender];
}

- (id) cut: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(copySelection)] == NO
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return nil;
  [selectionOwner copySelection];
  [selectionOwner deleteSelection];
  return self;
}

- (id) groupSelectionInSplitView: (id)sender
{
  if ([[selectionOwner selection] count] < 2
      || [selectionOwner respondsToSelector: @selector(groupSelectionInSplitView)] == NO)
    return nil;
  [(id)selectionOwner groupSelectionInSplitView];
  return self;
}

- (id) groupSelectionInBox: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInBox)] == NO)
    return nil;
  [(id)selectionOwner groupSelectionInBox];
  return self;
}

- (id) groupSelectionInScrollView: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(groupSelectionInScrollView)] == NO)
    return nil;
  [(id)selectionOwner groupSelectionInScrollView];
  return self;
}

- (id) ungroup: (id)sender
{
  NSLog(@"ungroup: selectionOwner %@", selectionOwner);
  if ([selectionOwner respondsToSelector: @selector(ungroup)] == NO)
    return nil;
  [(id)selectionOwner ungroup];
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
  //  [super dealloc];
}

- (id) delete: (id)sender
{
  if ([[selectionOwner selection] count] == 0
    || [selectionOwner respondsToSelector: @selector(deleteSelection)] == NO)
    return nil;
  [selectionOwner deleteSelection];
  return self;
}

- (void) displayConnectionBetween: (id)source and: (id)destination
{
  NSWindow	*w;
  NSRect	r;
  

  if (source != connectSource)
    {
      if (connectSource != nil)
	{
	  w = [[self activeDocument] windowAndRect: &r
					 forObject: connectSource];
	  if (w != nil)
	    {
	      NSView	*wv = [[w contentView] superview];
 
	      r.origin.x --;
	      r.size.width ++;
	      
	      r.size.height ++;

	      [w disableFlushWindow];
	      [wv displayRect: r];
	      
	      [w enableFlushWindow];
	      [w flushWindow];
	    }
	}
      connectSource = source;
    }
  if (destination != connectDestination)
    {
      if (connectDestination != nil)
	{
	  w = [[self activeDocument] windowAndRect: &r
					 forObject: connectDestination];
	  if (w != nil)
	    {
	      NSView	*wv = [[w contentView] superview];

	      /*
	       * Erase image from old location.
	       */
	      r.origin.x --;
	      r.size.width ++;
	      r.size.height ++;

	      [wv lockFocus];
	      [wv displayRect: r];
	      [wv unlockFocus];
	      [w flushWindow];
	    }
	}
      connectDestination = destination;
    }
  if (connectSource != nil)
    {
      w = [[self activeDocument] windowAndRect: &r forObject: connectSource];
      if (w != nil)
	{
	  NSView	*wv = [[w contentView] superview];
	  
	  r.origin.x++;
	  r.size.width--;
	  r.size.height--;
	  [wv lockFocus];
	  [[NSColor greenColor] set];
	  NSFrameRectWithWidth(r, 2);
	  
	  [sourceImage compositeToPoint: r.origin
			      operation: NSCompositeSourceOver];
	  [wv unlockFocus];
	  [w flushWindow];
	}
    }
  if (connectDestination != nil && connectDestination == connectSource)
    {
      w = [[self activeDocument] windowAndRect: &r
				     forObject: connectDestination];
      if (w != nil)
	{
	  NSView	*wv = [[w contentView] superview];

	  r.origin.x += 3;
	  r.origin.y += 2;
	  r.size.width -= 5;
	  r.size.height -= 5;
	  [wv lockFocus];
	  [[NSColor purpleColor] set];
	  NSFrameRectWithWidth(r, 2);
	  
	  r.origin.x += [targetImage size].width;
	  [targetImage compositeToPoint: r.origin
			      operation: NSCompositeSourceOver];
	  [wv unlockFocus];
	  [w flushWindow];
	}
    }
  else if (connectDestination != nil)
    {
      w = [[self activeDocument] windowAndRect: &r
				     forObject: connectDestination];
      if (w != nil)
	{
	  NSView	*wv = [[w contentView] superview];

	  r.origin.x++;
	  r.size.width--;
	  r.size.height--;
	  [wv lockFocus];
	  [[NSColor purpleColor] set];
	  NSFrameRectWithWidth(r, 2);
	  
	  [targetImage compositeToPoint: r.origin
			      operation: NSCompositeSourceOver];
	  [wv unlockFocus];
	  [w flushWindow];
	}
    }
}

- (id) loadClass: (id)sender
{
  // Call the current document and create the class 
  // descibed by the header
  return [(id)[self activeDocument] loadClass: sender];
}

- (id) addAttributeToClass: (id)sender
{  
  return [(id)[self activeDocument] addAttributeToClass: sender];
}

- (id) remove: (id)sender
{  
  return [(id)[self activeDocument] remove: sender];
}

- (id) editClass: (id)sender
{
  [self inspector: self];
  return [(id)[self activeDocument] editClass: sender];
}

- (id) createClassFiles: (id)sender
{
  return [(id)[self activeDocument] createClassFiles: sender];
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
      NSUserDefaults		*defs;
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

      defs = [NSUserDefaults standardUserDefaults];
      [defs setObject: menuLocations forKey: @"NSMenuLocations"];
      DESTROY(menuLocations);
      [self setMainMenu: mainMenu];

      DESTROY(testContainer);

      isTesting = NO;

      if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	{
	  [(id<IBEditors>)selectionOwner makeSelectionVisible: YES];
	}
      [nc postNotificationName: IBDidEndTestingInterfaceNotification
			object: self];
      RELEASE(pool);
      return self;
    }
}

- (void) finishLaunching
{
  NSMenu		*aMenu;
  NSMenu		*modulesMenu;
  NSMenu		*windowsMenu;
  NSMenuItem		*menuItem;
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
	  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];

	  [defs registerDefaults: dict];
	}
    }

  mainMenu = [[NSMenu alloc] initWithTitle: @"Gorm"];

  /*
   * Set up info menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Info Panel..." 
		   action: @selector(infoPanel:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Preferences..." 
		   action: NULL
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Help..." 
		   action: NULL 
	    keyEquivalent: @"?"];
  menuItem = [mainMenu addItemWithTitle: @"Info" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  /*
   * Set up document menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Open..." 
		   action: @selector(open:) 
	    keyEquivalent: @"o"];
  [aMenu addItemWithTitle: @"New Application" 
		   action: @selector(newApplication:)
	    keyEquivalent: @"n"];
  modulesMenu = [NSMenu new];
  [modulesMenu addItemWithTitle: @"New Empty" 
			 action: @selector(newEmpty:) 
		  keyEquivalent: @"N"];
  [modulesMenu addItemWithTitle: @"New Inspector" 
			 action: @selector(newInspector:) 
		  keyEquivalent: @""];
  [modulesMenu addItemWithTitle: @"New Palette" 
			 action: @selector(newPalette:) 
		  keyEquivalent: @""];
  menuItem = [aMenu addItemWithTitle: @"New Module" 
			      action: NULL 
		       keyEquivalent: @""];
  [aMenu setSubmenu: modulesMenu forItem: menuItem];
  RELEASE(modulesMenu);
  [aMenu addItemWithTitle: @"Save" 
		   action: @selector(save:) 
	    keyEquivalent: @"s"];
  [aMenu addItemWithTitle: @"Save As..." 
		   action: @selector(saveAs:) 
	    keyEquivalent: @"S"];
  [aMenu addItemWithTitle: @"Save All" 
		   action: @selector(saveAll:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Revert to Saved" 
		   action: @selector(revertToSaved:) 
	    keyEquivalent: @"u"];
  [aMenu addItemWithTitle: @"Test Interface"
		   action: @selector(testInterface:) 
	    keyEquivalent: @"r"];
  [aMenu addItemWithTitle: @"Miniaturize"
		   action: @selector(miniaturize:) 
	    keyEquivalent: @"m"];
  [aMenu addItemWithTitle: @"Close"
		   action: @selector(close:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Debug"
		   action: @selector(debug:) 
	    keyEquivalent: @""];
  menuItem = [mainMenu addItemWithTitle: @"Document" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);





  /*
   * Set up edit menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Cut" 
		   action: @selector(cut:) 
	    keyEquivalent: @"x"];
  [aMenu addItemWithTitle: @"Copy" 
		   action: @selector(copy:) 
	    keyEquivalent: @"c"];
  [aMenu addItemWithTitle: @"Paste" 
		   action: @selector(paste:) 
	    keyEquivalent: @"v"];
  [aMenu addItemWithTitle: @"Delete" 
		   action: @selector(delete:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Select All" 
		   action: @selector(selectAllItems:) 
	    keyEquivalent: @"a"];
  [aMenu addItemWithTitle: @"Set Name..." 
		   action: @selector(setName:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Group in splitview" 
		   action: @selector(groupSelectionInSplitView:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Group in box" 
		   action: @selector(groupSelectionInBox:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Group in scrollview" 
		   action: @selector(groupSelectionInScrollView:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Ungroup" 
		   action: @selector(ungroup:) 
	    keyEquivalent: @""];
  [[aMenu addItemWithTitle: @"Font Panel" 
	  action: @selector(orderFrontFontPanel:) 
	  keyEquivalent: @"f"] setTarget: [NSFontManager sharedFontManager]];
  menuItem = [mainMenu addItemWithTitle: @"Edit" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);


  /*
   * Set up classes menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Create Subclass..." 
	 action: @selector(createSubclass:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Load Class..." 
		   action: @selector(loadClass:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Edit Class..." 
		   action: @selector(editClass:) 
	    keyEquivalent: @""];  
  [aMenu addItemWithTitle: @"Create Class's Files..." 
		   action: @selector(createClassFiles:) 
	    keyEquivalent: @""];  
  [aMenu addItemWithTitle: @"Instantiate" 
		   action: @selector(instantiateClass:) 
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Add Outlet/Action..."
	           action: @selector(addAttributeToClass:)
	    keyEquivalent: @""];
  [aMenu addItemWithTitle: @"Remove..."
	           action: @selector(remove:)
	    keyEquivalent: @""];
  menuItem = [mainMenu addItemWithTitle: @"Classes" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  classMenu = aMenu;
  RELEASE(aMenu);

  /*
   * Set up tools menu.
   */
  aMenu = [NSMenu new];
  [aMenu addItemWithTitle: @"Inspector..." 
		   action: @selector(inspector:) 
	    keyEquivalent: @"i"];
  [aMenu addItemWithTitle: @"Palettes..." 
		   action: @selector(palettes:) 
	    keyEquivalent: @"p"];
  [aMenu addItemWithTitle: @"Load Palette..." 
		   action: @selector(loadPalette:) 
	    keyEquivalent: @""];
  menuItem = [mainMenu addItemWithTitle: @"Tools" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);


  /*
   * Set up Windows menu
   */
  windowsMenu = [NSMenu new];
  [windowsMenu addItemWithTitle: @"Arrange"
			 action: @selector(arrangeInFront:)
		  keyEquivalent: @""];
  [windowsMenu addItemWithTitle: @"Miniaturize"
			 action: @selector(performMiniaturize:)
		  keyEquivalent: @"m"];
  [windowsMenu addItemWithTitle: @"Close"
			 action: @selector(performClose:)
		  keyEquivalent: @"w"];
  menuItem = [mainMenu addItemWithTitle: @"Windows" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: windowsMenu forItem: menuItem];
  RELEASE(windowsMenu);

  /*
   * Set up Services menu
   */
  aMenu = [NSMenu new];
  menuItem = [mainMenu addItemWithTitle: @"Services" 
				 action: NULL 
			  keyEquivalent: @""];
  [mainMenu setSubmenu: aMenu forItem: menuItem];
  RELEASE(aMenu);

  [mainMenu addItemWithTitle: @"Hide" 
		      action: @selector(hide:)
	       keyEquivalent: @"h"];	

  [mainMenu addItemWithTitle: @"Quit" 
		      action: @selector(terminate:)
	       keyEquivalent: @"q"];	


  [self setMainMenu: mainMenu];
  [self setWindowsMenu: windowsMenu];
  //  [mainMenu display];
  [self setDelegate: self];
  [super finishLaunching];
NSLog(@"StartupTime %f", [startDate timeIntervalSinceNow]);
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

- (id) infoPanel: (id) sender
{
  NSMutableDictionary *d;

  d = [NSMutableDictionary dictionaryWithCapacity: 8];
  [d setObject: @"Gorm" forKey: @"ApplicationName"];
  [d setObject: @"GNUstep Graphical Object Relationship Modeller"
	forKey: @"ApplicationDescription"];
  [d setObject: @"Gorm 0.2" forKey: @"ApplicationRelease"];
  [d setObject: @"0.2 Jul 2002" forKey: @"FullVersionID"];
  [d setObject: [NSArray arrayWithObjects: 
		  @"Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>",
		  @"Gregory John Casamento <greg_casamento@yahoo.com>",
		  @"Richard Frith-Macdonald <rfm@gnu.org>",
		  nil]
	forKey: @"Authors"];
  //  [d setObject: @"See http://www.gnustep.org" forKey: @"URL"];
  [d setObject: @"Copyright (C) 1999, 2000, 2001, 2002 Free Software Foundation, Inc."
	forKey: @"Copyright"];
  [d setObject: @"Released under the GNU General Public License 2.0"
	forKey: @"CopyrightDescription"];
  
  [self orderFrontStandardInfoPanelWithOptions: d];
  return self;
}

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
    }
  return self;
}

- (id) inspector: (id) sender
{
  [[[self inspectorsManager] panel] makeKeyAndOrderFront: self];
  return self;
}

- (GormInspectorsManager*) inspectorsManager
{
  if (inspectorsManager == nil)
    {
      inspectorsManager = [GormInspectorsManager new];
    }
  return inspectorsManager;
}

- (id) instantiateClass: (id)sender
{
  return [(id)[self activeDocument] instantiateClass: sender];
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

- (id) loadPalette: (id) sender
{
  return [[self palettesManager] openPalette: sender];
}

- (void) debug: (id) sender
{
  [[self activeDocument] performSelector: @selector(printAllEditors)];
}

- (id) miniaturize: (id)sender
{
  NSWindow	*window = [(id)[self activeDocument] window];

  [window miniaturize: self];
  return nil;
}

- (id) newApplication: (id) sender
{
  id		doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
  [doc setupDefaults: @"Application"];
  [[doc window] makeKeyAndOrderFront: self];
  return doc;
}

- (id) newEmpty: (id) sender
{
  id		doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
  [doc setupDefaults: @"Empty"];
  [[doc window] makeKeyAndOrderFront: self];
  return doc;
}

- (id) newInspector: (id) sender
{
  id		doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
  [doc setupDefaults: @"Inspector"];
  [[doc window] makeKeyAndOrderFront: self];
  return doc;
}

- (id) newPalette: (id) sender
{
  id		doc = [GormDocument new];

  [documents addObject: doc];
  RELEASE(doc);
  [doc setupDefaults: @"Palette"];
  [[doc window] makeKeyAndOrderFront: self];
  return doc;
}

- (id) open: (id) sender
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
      [[doc window] makeKeyAndOrderFront: self];
    }
  return doc;
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
      [[doc window] makeKeyAndOrderFront: self];
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

- (id) palettes: (id) sender
{
  [[[self palettesManager] panel] makeKeyAndOrderFront: self];
  return self;
}

- (id) paste: (id)sender
{
  if ([selectionOwner respondsToSelector: @selector(pasteInSelection)] == NO)
    return nil;
  [selectionOwner pasteInSelection];
  return self;
}

- (id) revertToSaved: (id)sender
{
  id	doc = [(id)[self activeDocument] revertDocument: sender];

  if (doc != nil)
    {
      [documents addObject: doc];
      [[doc window] makeKeyAndOrderFront: self];
    }
  return nil;
}

- (id) save: (id)sender
{
  return [(id)[self activeDocument] saveDocument: sender];
}

- (id) saveAll: (id)sender
{
  NSEnumerator	*e = [documents objectEnumerator];
  id		doc;

  while ((doc = [e nextObject]) != nil)
    {
      if ([[doc window] isDocumentEdited] == YES)
	{
	  [doc saveDocument: sender];
	}
    }
  return self;
}

- (id) saveAs: (id)sender
{
  return [(id)[self activeDocument] saveAsDocument: sender];
}

- (id) selectAllItems: (id)sender
{
  /* FIXME */
  return nil;
}

- (id<IBSelectionOwners>) selectionOwner
{
  return selectionOwner;
}

- (id) selectedObject
{
  return [[selectionOwner selection] lastObject];
} 

- (id) setName: (id)sender
{
  NSPanel	*p;
  int		r;
  NSTextField	*t;
  NSArray	*s = [selectionOwner selection];
  id		o = [s objectAtIndex: 0];
  NSString	*n;

  p = NSGetAlertPanel(@"Set Name", @"Name: ", @"OK", @"Cancel", nil);
  t = [[NSTextField alloc] initWithFrame: NSMakeRect(60,46,240,20)];
  [[p contentView] addSubview: t];
  [p makeFirstResponder: t];
  [p makeKeyAndOrderFront: self];
  [t performClick: self];
  r = [(id)p runModal];
  if (r == NSAlertDefaultReturn)
    {
      n = [[t stringValue] stringByTrimmingSpaces];
      if (n != nil && [n isEqual: @""] == NO)
	{
	  [[self activeDocument] setName: n forObject: o];
	}
    }
  [t removeFromSuperview];
  RELEASE(t);
  NSReleaseAlertPanel(p);
  return self;
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

- (id) testInterface: (id)sender
{
  if (isTesting == YES)
    {
      return nil;
    }
  else
    {
      NSUserDefaults		*defs;
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      GormDocument		*a = (GormDocument*)[self activeDocument];
      NSData			*d;
      NSArchiver                *archiver;

      archiver = [[NSArchiver alloc] init];
      [a beginArchiving];
      [archiver encodeClassName: @"GormNSWindow" 
		intoClassName: @"NSWindow"];
      [archiver encodeClassName: @"GormNSMenu" 
		intoClassName: @"NSMenu"];
      [archiver encodeClassName: @"GormNSPopUpButton" 
		intoClassName: @"NSPopUpButton"];
      [archiver encodeClassName: @"GormNSPopUpButtonCell" 
		intoClassName: @"NSPopUpButtonCell"];
      [archiver encodeClassName: @"GormCustomView" 
		intoClassName: @"GormTestCustomView"];
      [archiver encodeRootObject: a];
      d = RETAIN([archiver archiverData]);
      [a endArchiving];
      RELEASE(archiver);
      
      [nc postNotificationName: IBWillBeginTestingInterfaceNotification
			object: self];

      isTesting = YES;

      if ([selectionOwner conformsToProtocol: @protocol(IBEditors)] == YES)
	{
	  [(id<IBEditors>)selectionOwner makeSelectionVisible: NO];
	}

      defs = [NSUserDefaults standardUserDefaults];
      menuLocations = [[defs objectForKey: @"NSMenuLocations"] copy];
      [defs removeObjectForKey: @"NSMenuLocations"];

      testContainer = [NSUnarchiver unarchiveObjectWithData: d];
      if (testContainer != nil)
	{
	  [testContainer awakeWithContext: nil];
	  RETAIN(testContainer);
	}

      /*
       * If the NIB didn't have a main menu, create one,
       * otherwise, ensure that 'quit' ends testing mode.
       */
      if ([self mainMenu] == mainMenu)
	{
          NSMenu	*testMenu;

	  testMenu = [[NSMenu alloc] initWithTitle: @"Test"];
	  [testMenu addItemWithTitle: @"Quit" 
			      action: @selector(deferredEndTesting:)
		       keyEquivalent: @"q"];	
	  [self setMainMenu: testMenu];
	  RELEASE(testMenu);
	}
      else
	{
          NSMenu	*testMenu = [self mainMenu];
	  NSMenuItem	*item;

	  item = [testMenu itemWithTitle: @"Quit"];
	  if (item != nil)
	    {
	      [item setAction: @selector(deferredEndTesting:)];
	    }
	  else
	    {
	      [testMenu addItemWithTitle: @"Quit" 
				  action: @selector(deferredEndTesting:)
			   keyEquivalent: @"q"];	
	    }
	}

      [nc postNotificationName: IBDidBeginTestingInterfaceNotification
			object: self];

      RELEASE(d);
      return self;
    }
}

- (BOOL) validateMenuItem: (NSMenuItem*)item
{
  GormDocument	*active = (GormDocument*)[self activeDocument];
  SEL		action = [item action];

  if (sel_eq(action, @selector(close:))
    || sel_eq(action, @selector(miniaturize:))
    || sel_eq(action, @selector(save:))
    || sel_eq(action, @selector(saveAs:))
    || sel_eq(action, @selector(saveAll:)))
    {
      if (active == nil)
	return NO;
    }

  if (sel_eq(action, @selector(revertToSaved:)))
    {
      if (active == nil || [active documentPath] == nil
	|| [[active window] isDocumentEdited] == NO)
	return NO;
    }

  if (sel_eq(action, @selector(testInterface:)))
    {
      if (active == nil)
	return NO;
    }

  if (sel_eq(action, @selector(copy:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return [selectionOwner respondsToSelector: @selector(copySelection)];
    }

  if (sel_eq(action, @selector(cut:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return ([selectionOwner respondsToSelector: @selector(copySelection)]
	&& [selectionOwner respondsToSelector: @selector(deleteSelection)]);
    }

  if (sel_eq(action, @selector(delete:)))
    {
      if ([[selectionOwner selection] count] == 0)
	return NO;
      return [selectionOwner respondsToSelector: @selector(deleteSelection)];
    }

  if (sel_eq(action, @selector(paste:)))
    {
      return [selectionOwner respondsToSelector: @selector(pasteInSelection)];
    }

  if (sel_eq(action, @selector(setName:)))
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
	|| [n isEqual: @"NSFont"])
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
@end

int 
main(int argc, const char **argv)
{ 
  extern BOOL NSImageDoesCaching;

  NSImageDoesCaching = YES;
  //[NSObject enableDoubleReleaseCheck: YES];
  
  //  [GormPosingView poseAsClass: [NSView class]];

  startDate = [[NSDate alloc] init];
  NSApplicationMain(argc, argv);

  return 0;
}

