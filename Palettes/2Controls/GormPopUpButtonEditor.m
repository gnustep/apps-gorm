#include <AppKit/AppKit.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/GormControlEditor.h>
#include <GormCore/GormViewWithSubviewsEditor.h>

#define _EO ((NSPopUpButton *)_editedObject)

@class GormNSPopUpButtonCell;

Class _gormnspopupbuttonCellClass = 0;
@interface GormNSPopUpButton : NSPopUpButton
@end

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

@interface GormNSPopUpButtonCell : NSPopUpButtonCell
{
}
@end

@interface NSPopUpButtonCell (DirtyHack)
- (id) _gormInitTextCell: (NSString *) string;
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
    selectedItem = [self indexOfSelectedItem];

  if (selectedItem > 0)
    {
      [mr setHighlightedItemIndex: selectedItem];
    }

  // Ask the MenuView to attach the menu to this rect
  [mr setWindowFrameForAttachingToRect: cellFrame
      onScreen: [cvWin screen]
      preferredEdge: _pbcFlags.preferredEdge
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

@interface GormPopUpButtonEditor : GormControlEditor
{
}
@end

@implementation GormPopUpButtonEditor
- (void) mouseDown: (NSEvent *)theEvent
{
  // double-clicked -> let's edit
  if (([theEvent clickCount] == 2) && [parent isOpened])
    {
      [[_EO cell]
	attachPopUpWithFrame: [_EO bounds]
	inView: _editedObject];
      NSDebugLog(@"attach down");
      [[document openEditorForObject: [[_EO cell] menu]] activate];
    }
  else
    {
      [super mouseDown: theEvent];
    }  
}
@end
