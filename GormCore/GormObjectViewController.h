/* All rights reserved */

#ifndef GormObjectViewController_H_INCLUDE
#define GormObjectViewController_H_INCLUDE

#import <AppKit/AppKit.h>

@class GormDocument;

/**
 * GormObjectViewController manages the Objects view in Gorm. It coordinates the
 * icon and outline representations, switches the displayed view, and forwards
 * editor actions to the underlying document/editor.
 */
@interface GormObjectViewController : NSViewController
{
  IBOutlet id displayView;
  IBOutlet id iconButton;
  IBOutlet id outlineButton;
  IBOutlet id editorButton;
  
  // Document
  GormDocument *_document;
  id _iconView;
  id _outlineView;

  // Editor flag
  BOOL _editor;
}

/**
 * Returns the document associated with this controller.
 */
- (GormDocument *) document;
/**
 * Sets the document associated with this controller.
 */
- (void) setDocument: (GormDocument *)document;

/**
 * Returns the view used for displaying objects in an icon/grid layout.
 */
- (id) iconView;
/**
 * Sets the view used for the icon/grid layout.
 */
- (void) setIconView: (id)iconView;

/**
 * Returns the view used for displaying objects in an outline/tree layout.
 */
- (id) outlineView;
/**
 * Sets the view used for the outline/tree layout.
 */
- (void) setOutlineView: (id)outlineView;

/**
 * Returns YES if the controller is in "editor" mode; NO otherwise.
 */
- (BOOL) editor;
/**
 * Sets whether the controller is in "editor" mode.
 */
- (void) setEditor: (BOOL)f;

/**
 * Replaces the displayed subview with the specified view and updates UI state.
 */
- (void) resetDisplayView: (NSView *)view;
/**
 * Reloads the outline view to reflect changes in the object list.
 */
- (void) reloadOutlineView;

/**
 * Action: switch the display to the icon/grid view.
 */
- (IBAction) iconView: (id)sender;
/**
 * Action: switch the display to the outline/tree view.
 */
- (IBAction) outlineView: (id)sender;
/**
 * Action: toggle or invoke the editor associated with the current selection.
 */
- (IBAction) editorButton: (id)sender;

@end

#endif // GormObjectViewController_H_INCLUDE
