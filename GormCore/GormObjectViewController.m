/* All rights reserved */

#import "GormObjectViewController.h"
#import "GormDocument.h"
#import "GormObjectEditor.h"

@implementation GormObjectViewController

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
      _document = nil;
      _iconView = nil;
      _outlineView = nil;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_document);
  RELEASE(_iconView);
  RELEASE(_outlineView);

  [super dealloc];
}

- (GormDocument *) document
{
  return _document;
}

- (void) setDocument: (GormDocument *)document
{
  ASSIGN(_document, document);
}

- (id) iconView
{
  return _iconView;
}

- (void) setIconView: (id)iconView
{
  ASSIGN(_iconView, iconView);
}

- (id) outlineView
{
  return _outlineView;
}

- (void) setOutlineView: (id)outlineView
{
  ASSIGN(_outlineView, outlineView);
}

- (IBAction) iconView: (id)sender
{
  NSDebugLog(@"Called %@", NSStringFromSelector(_cmd));
  [self resetDisplayView: _iconView];
}

- (IBAction) outlineView: (id)sender
{
  NSDebugLog(@"Called %@", NSStringFromSelector(_cmd));
  [_document deactivateEditors];
  [[_outlineView documentView] reloadData];
  [_document reactivateEditors];
  [self resetDisplayView: _outlineView];
}

- (void) resetDisplayView: (NSView *)view
{
  [displayView setContentView: view];
  NSDebugLog(@"displayView = %@", view);
}

@end
