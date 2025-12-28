/* GormCanvasWindow.h
 *
 * Lightweight canvas mode window showing document objects.
 */
#import <AppKit/AppKit.h>

@class GormDocument;

@interface GormCanvasWindow : NSWindow

- (id)initWithDocument:(GormDocument *)doc;

@end
