/* All rights reserved */

#import "GormObjectViewController.h"
#import "GormDocument.h"

@implementation GormObjectViewController

- (GormDocument *) document
{
  return _document;
}

- (void) setDocument: (GormDocument *)document
{
  ASSIGN(_document, document);
}

- (IBAction) iconView: (id)sender
{
  NSLog(@"Called %@", NSStringFromSelector(_cmd));
}

- (IBAction) outlineView: (id)sender
{
  NSLog(@"Called %@", NSStringFromSelector(_cmd));
}

- (void) resetDisplayView: (NSView *)view
{
  [displayView setContentView: view];
  NSLog(@"displayView = %@", view);
}

@end
