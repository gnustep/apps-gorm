/* All rights reserved */

#ifndef GormObjectViewController_H_INCLUDE
#define GormObjectViewController_H_INCLUDE

#import <AppKit/AppKit.h>

@class GormDocument;

@interface GormObjectViewController : NSViewController
{
  IBOutlet id displayView;
  IBOutlet id iconButton;
  IBOutlet id outlineButton;
  
  // Document
  GormDocument *_document;
}

- (GormDocument *) document;
- (void) setDocument: (GormDocument *)document;

- (void) resetDisplayView: (NSView *)view;

- (IBAction) iconView: (id)sender;
- (IBAction) outlineView: (id)sender;

@end

#endif // GormObjectViewController_H_INCLUDE
