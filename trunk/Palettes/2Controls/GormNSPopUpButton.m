#include <GormCore/GormPrivate.h>
#include "GormNSPopUpButton.h"

Class _gormnspopupbuttonCellClass = 0;

@implementation GormNSPopUpButton
/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [GormNSPopUpButton class])
    {
      // Initial version
      [self setVersion: 1];
      [self setCellClass: [GormNSPopUpButtonCell class]];
    } 
}

+ (Class) cellClass
{
  return _gormnspopupbuttonCellClass;
}

+ (void) setCellClass: (Class)classId
{
  _gormnspopupbuttonCellClass = classId;
}

- (NSString*) editorClassName
{
  return @"GormPopUpButtonEditor";
}

- (NSString *) className
{
  return @"NSPopUpButton";
}
@end

@implementation NSPopUpButtonCell (DirtyHack)
- (id) _gormInitTextCell: (NSString *) string
{
  return [super initTextCell: string];
}
@end

@implementation GormNSPopUpButtonCell 

/* Overriden helper method */
- (void) _initMenu
{
  NSMenu *menu = [[NSMenu allocSubstitute] initWithTitle: @""];
  [self setMenu: menu];
  RELEASE(menu);
}

- (NSString *) className
{
  return @"NSPopUpButtonCell";
}

/**
 * Override this here, since themes may override it.
 * Always want to show the menu view since it's editable. 
 */
- (void) attachPopUpWithFrame: (NSRect)cellFrame
                       inView: (NSView *)controlView
{
  NSRectEdge            preferredEdge = _pbcFlags.preferredEdge;
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
  NSWindow              *cvWin = [controlView window];
  NSMenuView            *mr = [[self menu] menuRepresentation];
  int                   selectedItem;

  [nc postNotificationName: NSPopUpButtonCellWillPopUpNotification
                    object: self];

  [nc postNotificationName: NSPopUpButtonWillPopUpNotification
                    object: controlView];

  // Convert to Screen Coordinates
  cellFrame = [controlView convertRect: cellFrame toView: nil];
  cellFrame.origin = [cvWin convertBaseToScreen: cellFrame.origin];

  if (_pbcFlags.pullsDown)
    selectedItem = -1;
  else
    {
      selectedItem = [self indexOfSelectedItem];
      if (selectedItem == -1) // Test
	selectedItem = 0;
    }

  if (selectedItem > 0)
    {
      [mr setHighlightedItemIndex: selectedItem];
    }

  if ([controlView isFlipped])
    {
      if (preferredEdge == NSMinYEdge)
	{
	  preferredEdge = NSMaxYEdge;
	}
      else if (preferredEdge == NSMaxYEdge)
	{
	  preferredEdge = NSMinYEdge;
	}
    }

  // Ask the MenuView to attach the menu to this rect
  [mr setWindowFrameForAttachingToRect: cellFrame
      onScreen: [cvWin screen]
      preferredEdge: preferredEdge
      popUpSelectedItem: selectedItem];

  // Set to be above the main window
  [cvWin addChildWindow: [mr window] ordered: NSWindowAbove];

  // Last, display the window
  [[mr window] orderFrontRegardless];

  [nc addObserver: self
      selector: @selector(_handleNotification:)
      name: NSMenuDidSendActionNotification
      object: _menu];
}
@end
