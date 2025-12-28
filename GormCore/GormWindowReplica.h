/* GormWindowReplica.h
 *
 * Lightweight view that imitates an `NSWindow` inside the canvas.
 */
#import <AppKit/AppKit.h>

@interface GormWindowReplica : NSView

- (id)initWithWindow: (NSWindow *)window frame: (NSRect)frameRect;
- (void)restoreOriginalWindow: (id)sender;

@end
