#include <AppKit/AppKit.h>
#include "GormPrivate.h"
#include "GormControlEditor.h"
#include "GormViewWithSubviewsEditor.h"

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

- (id) initTextCell: (NSString*) stringValue
          pullsDown: (BOOL) pullDown
{
  [super _gormInitTextCell: stringValue];


  _pbcFlags.pullsDown = pullDown;
  _pbcFlags.usesItemFromMenu = YES;
  _pbcFlags.altersStateOfSelectedItem = YES;

  if ([stringValue length] > 0)
    {
      [self addItemWithTitle: stringValue]; 
    }

  _menu = [(id)[NSMenu allocSubstitute] initWithTitle: @""];
  [_menu _setOwnedByPopUp: self];

  return self;
}

- (NSString *) className
{
  return @"NSPopUpButtonCell";
}
@end
//  @interface GormPopUpNSMenu : NSMenu
//  - (BOOL)canBecomeMainWindow
//  {
//    return YES;
//  }
//  - (BOOL)canBecomeKeyWindow
//  {
//    return YES;
//  }

//  - (void) sendEvent: (NSEvent*)theEvent
//  {
//    NSEventType   type;

//    type = [theEvent type];
//    if (type == NSLeftMouseDown)
//      {
//        NSLog(@"here");
//        if (_f.is_main == YES)
//  	{
//  	  NSLog(@"already main %@", [NSApp mainWindow]);
//  	}
//        [self makeMainWindow];
//        [self makeKeyWindow];
//      }

//    [super sendEvent: theEvent];
//  }
//  @end

//  @implementation GormPopUpNSMenu
//  @end

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
