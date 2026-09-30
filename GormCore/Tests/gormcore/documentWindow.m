/* Regression coverage for the document window's archived custom class. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import <GormCore/GormDocumentWindow.h>

@interface DocumentWindowOwner : NSObject
{
@public
  NSWindow *_window;
  NSBox *selectionBox;
  NSView *filePrefsView;
  GormFilePrefsManager *filePrefsManager;
}
@end
@implementation DocumentWindowOwner
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  START_SET("Document window archive")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    SKIP("A graphical GNUstep backend is required (run under Xvfb)")
  NS_ENDHANDLER

  DocumentWindowOwner *owner = [DocumentWindowOwner new];
  NSBundle *bundle = [NSBundle bundleForClass: [GormDocument class]];
  NSNib *nib = [[NSNib alloc] initWithNibNamed: @"GormDocument" bundle: bundle];
  NSArray *objects = nil;
  BOOL loaded = [nib instantiateNibWithOwner: owner topLevelObjects: &objects];
  PASS(loaded, "the document interface loads with its remaining outlets")
  PASS([owner->_window isKindOfClass: [GormDocumentWindow class]],
       "the document window retains its custom class after archive edits")
  PASS([owner->_window respondsToSelector: @selector(setDocument:)],
       "the window supports document initialization")
  PASS(owner->selectionBox != nil && owner->filePrefsView != nil &&
       owner->filePrefsManager != nil,
       "document content and file preferences outlets remain connected")
  [owner->_window orderFront: nil];
  PASS([owner->_window isVisible], "the document window can be shown")
  [owner->_window orderOut: nil];
  [nib release];
  [owner release];
  END_SET("Document window archive")
  [pool drain];
  return 0;
}
