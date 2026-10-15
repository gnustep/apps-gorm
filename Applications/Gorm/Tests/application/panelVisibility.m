/* Regression coverage for panel preferences across application hiding.
 * Copyright (C) 2026 Free Software Foundation, Inc.
 * Distributed under the GNU GPL, version 3 or later.
 */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import "../../GormAppDelegate.m"
#import "../../GormLanguageViewController.m"

@interface GormAppDelegate (VisibilityTests)
- (void) applicationWillTerminate: (NSNotification *)notification;
@end

/* Use real NSPanel ordering and application notifications without loading
 * palettes, documents or the application menu. */
@interface PanelManager : NSObject
{
  NSPanel *panel;
  NSPanel *library;
}
- (NSPanel *) panel;
- (NSPanel *) libraryPanel;
- (BOOL) isLibraryVisible;
@end
@implementation PanelManager
- (id) init
{
  self = [super init];
  panel = [[NSPanel alloc] initWithContentRect: NSMakeRect(50, 50, 100, 100)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  [panel setReleasedWhenClosed: NO];
  library = [[NSPanel alloc] initWithContentRect: NSMakeRect(200, 50, 100, 100)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  [library setReleasedWhenClosed: NO];
  return self;
}
- (NSPanel *) panel { return panel; }
- (NSPanel *) libraryPanel { return library; }
- (BOOL) isLibraryVisible { return [library isVisible]; }
- (void) dealloc
{
  [panel close];
  [panel release];
  [library close];
  [library release];
  [super dealloc];
}
@end

@interface VisibilityDelegate : GormAppDelegate
@end
@implementation VisibilityDelegate
- (id) init
{
  /* The superclass initializer loads application resources. */
  _palettesManager = (id)[PanelManager new];
  _inspectorsManager = (id)[PanelManager new];
  return self;
}
@end

static BOOL waitForOrderedPanels(NSPanel *palettes, NSPanel *inspectors,
                                 NSPanel *library)
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 5.0];

  /* AppKit deactivates panels from the backend's ordered window list.
   * A window manager may publish newly mapped windows asynchronously. */
  do
    {
      NSArray *windows = GSOrderedWindows();
      if ([windows containsObject: palettes]
        && [windows containsObject: inspectors]
        && [windows containsObject: library])
        return YES;
      [[NSRunLoop currentRunLoop]
        runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
    }
  while ([deadline timeIntervalSinceNow] > 0);
  return NO;
}

static void checkVisibility(BOOL palettes, BOOL inspectors, BOOL library,
                            const char *label)
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  PASS([defaults boolForKey: @"ShowPalettes"] == palettes
    && [defaults boolForKey: @"ShowWidgetLibrary"] == library
    && [defaults boolForKey: @"ShowInspectors"] == inspectors,
    "%s", label)
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  VisibilityDelegate *delegate;
  NSPanel *palettes;
  NSPanel *inspectors;
  NSPanel *library;
  START_SET("Panel visibility preferences")
  [NSApplication sharedApplication];
  delegate = [VisibilityDelegate new];
  [NSApp setDelegate: delegate];
  palettes = [[delegate palettesManager] panel];
  inspectors = [[delegate inspectorsManager] panel];
  library = [[delegate palettesManager] libraryPanel];
  [NSApp activateIgnoringOtherApps: YES];
  [library orderFront: nil];
  [palettes orderFront: nil];
  [inspectors orderFront: nil];
  PASS(waitForOrderedPanels(palettes, inspectors, library),
    "the backend has registered all panels before deactivation")
  [NSApp deactivate];
  PASS(![palettes isVisible] && ![inspectors isVisible] && ![library isVisible],
    "deactivation temporarily orders panels out")
  [delegate applicationWillTerminate: nil];
  checkVisibility(YES, YES, YES, "inactive quit preserves open panels");

  [NSApp activateIgnoringOtherApps: YES];
  PASS([palettes isVisible] && [inspectors isVisible] && [library isVisible],
    "activation restores the panels");
  [inspectors orderOut: nil];
  [NSApp hide: nil];
  [delegate applicationWillTerminate: nil];
  checkVisibility(YES, NO, YES, "hidden quit preserves deliberate inspector closure");

  [NSApp unhide: nil];
  [NSApp activateIgnoringOtherApps: YES];
  [palettes orderOut: nil];
  [inspectors orderFront: nil];
  [delegate applicationWillTerminate: nil];
  checkVisibility(NO, YES, YES, "active quit records current panel choices");

  [library orderOut: nil];
  [delegate applicationWillTerminate: nil];
  checkVisibility(NO, YES, NO, "library closure is saved independently");

  [delegate setTestingInterface: YES];
  [inspectors orderOut: nil];
  [NSApp deactivate];
  [delegate applicationWillTerminate: nil];
  checkVisibility(NO, YES, NO, "interface testing does not overwrite preferences");
  [delegate setTestingInterface: NO];
  [NSApp setDelegate: nil];
  [delegate release];
  END_SET("Panel visibility preferences")
  [pool drain];
  return 0;
}
