/* All rights reserved */

#ifndef GormObjectViewController_H_INCLUDE
#define GormObjectViewController_H_INCLUDE

#import <AppKit/AppKit.h>

@interface GormObjectViewController : NSViewController
{
  IBOutlet id displayView;
  IBOutlet id iconButton;
  IBOutlet id outlineButton;
}

- (IBAction) iconView: (id)sender;
- (IBAction) outlineView: (id)sender;

@end

#endif // GormObjectViewController_H_INCLUDE
