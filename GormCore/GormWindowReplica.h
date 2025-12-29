/* GormWindowReplica.h
 *
 * Lightweight view that imitates an `NSWindow` inside the canvas.
 */
#import <AppKit/AppKit.h>

@interface GormWindowReplica : NSView

{
	NSWindow *_originalWindow;
	NSString *_title;
	NSPoint _mouseDownPoint;
	NSRect _startFrame;
}

- (id)initWithWindow: (NSWindow *)window frame: (NSRect)frameRect;
- (void)restoreOriginalWindow: (id)sender;

@end
