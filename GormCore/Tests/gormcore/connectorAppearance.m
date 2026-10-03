/* Regression coverage for connector preferences and segment geometry. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import <GormCore/GormPrivate.h>
#import <GormCore/GormConnectorPref.h>
#import <GormCore/GormAbstractDelegate.h>
#include <math.h>

@interface GormAbstractDelegate (ConnectorTesting)
- (BOOL) _setConnectionLineSegmentFrom: (NSPoint)start
                                  to: (NSPoint)end
                               index: (NSUInteger)index;
- (NSWindow *) _connectionLineWindowAtIndex: (NSUInteger)index;
- (void) _hideConnectionLine;
- (void) _updateConnectionLine;
@end

/* Read the actual window backing store, without painting the view ourselves. */
static BOOL
segmentHasColor(NSWindow *window, NSColor *expected)
{
  NSView *view = [window contentView];
  NSBitmapImageRep *rep;
  NSColor *actual;
  BOOL matches;

  [view lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: [view bounds]];
  [view unlockFocus];
  actual = [[rep colorAtX: [rep pixelsWide] / 2
                       y: [rep pixelsHigh] / 2]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  expected = [expected colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  matches = actual != nil && expected != nil
    && fabs([actual redComponent] - [expected redComponent]) < 0.02
    && fabs([actual greenComponent] - [expected greenComponent]) < 0.02
    && fabs([actual blueComponent] - [expected blueComponent]) < 0.02;
  [rep release];
  return matches;
}

@interface ConnectorTestDelegate : GormAbstractDelegate
- (void) showConnectionFrom: (NSPoint)source to: (NSPoint)destination;
@end
@implementation ConnectorTestDelegate
- (BOOL) isInTool
{
  return YES;
}
- (NSPoint) _connectionLinePointForObject: (id)object
{
  return [object pointValue];
}
- (void) showConnectionFrom: (NSPoint)source to: (NSPoint)destination
{
  _connectSource = [NSValue valueWithPoint: source];
  _connectDestination = [NSValue valueWithPoint: destination];
  [self _updateConnectionLine];
}
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *searchList = [[defaults searchList] copy];
  NSMutableDictionary *values = [NSMutableDictionary dictionary];
  NSString *domain = [[NSProcessInfo processInfo] processName];
  NSDictionary *savedDomain = [[defaults persistentDomainForName: domain] copy];
  GormConnectorPref *prefs;
  ConnectorTestDelegate *delegate;
  NSWindow *segment;
  NSWindow *vertical;
  NSSlider *slider;
  NSColorWell *well;
  NSColor *chosen = [NSColor colorWithCalibratedRed: 0.25 green: 0.5
                                             blue: 0.75 alpha: 1.0];
  NSRect frame;

  START_SET("Connector appearance")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    SKIP("A graphical GNUstep backend is required (run under Xvfb)")
  NS_ENDHANDLER

  [values setObject: [NSArray arrayWithObject: @"English"] forKey: @"NSLanguages"];
  [defaults setVolatileDomain: values forName: @"GormConnectorTests"];
  [defaults setSearchList: [NSArray arrayWithObject: @"GormConnectorTests"]];
  PASS(GormConnectionLineWidth(defaults) == 2.0,
       "missing connector width uses the reset width")
  PASS([GormConnectionLineColor(defaults) isEqual:
          [NSColor redColor]],
       "missing connector color uses red")

  [values setObject: [NSNumber numberWithInt: -3] forKey: @"ConnectorWidth"];
  [defaults removeVolatileDomainForName: @"GormConnectorTests"];
  [defaults setVolatileDomain: values forName: @"GormConnectorTests"];
  PASS(GormConnectionLineWidth(defaults) == 2.0,
       "negative widths cannot create invalid segment frames")
  [values setObject: [NSNumber numberWithInt: 0] forKey: @"ConnectorWidth"];
  [defaults removeVolatileDomainForName: @"GormConnectorTests"];
  [defaults setVolatileDomain: values forName: @"GormConnectorTests"];
  PASS(GormConnectionLineWidth(defaults) == 2.0,
       "zero width cannot hide the connector")

  [values setObject: [NSNumber numberWithInt: 4] forKey: @"ConnectorWidth"];
  [values setObject: colorToDict(chosen) forKey: @"ConnectorColor"];
  [defaults removeVolatileDomainForName: @"GormConnectorTests"];
  [defaults setVolatileDomain: values forName: @"GormConnectorTests"];
  PASS(GormConnectionLineWidth(defaults) == 4.0 &&
       [GormConnectionLineColor(defaults) isEqual: chosen],
       "saved connector color and width are read without caching")

  NSLog(@"Connector framework: %@", [[NSBundle bundleForClass: [GormConnectorPref class]] bundlePath]);
  prefs = [GormConnectorPref new];
  slider = [prefs valueForKey: @"thicknessSlider"];
  well = [prefs valueForKey: @"colorWell"];
  PASS(prefs != nil && [prefs view] != nil && slider != nil && well != nil &&
       [prefs valueForKey: @"thicknessValue"] != nil,
       "the connector archive loads and connects its view and controls")
  PASS([slider intValue] == 4 && [[well color] isEqual: chosen] &&
       [[prefs valueForKey: @"thicknessValue"] intValue] == 4,
       "the preferences pane displays the saved appearance")
  PASS([slider target] == prefs && [NSStringFromSelector([slider action]) isEqual: @"ok:"] &&
       [well target] == prefs && [NSStringFromSelector([well action]) isEqual: @"ok:"],
       "the archived controls invoke the preferences action")

  delegate = [ConnectorTestDelegate new];
  vertical = [delegate _connectionLineWindowAtIndex: 1];
  PASS([vertical windowNumber] == 0,
       "segment windows defer native creation until their frame is set")
  [delegate _setConnectionLineSegmentFrom: NSMakePoint(20, 30)
                                      to: NSMakePoint(80, 30) index: 0];
  segment = [delegate _connectionLineWindowAtIndex: 0];
  frame = [segment frame];
  PASS(NSEqualRects(frame, NSMakeRect(20, 28, 60, 4)),
       "horizontal segments use the saved width and remain centered")
  PASS([segment isVisible] && segmentHasColor(segment, chosen),
       "the newly shown segment displays the chosen color")
  [segment display];
  [segment flushWindow];
  PASS(segmentHasColor(segment, chosen),
       "a normal window redraw preserves the connector color")
  [delegate _setConnectionLineSegmentFrom: NSMakePoint(80, 90)
                                      to: NSMakePoint(80, 30) index: 0];
  PASS(NSEqualRects([segment frame], NSMakeRect(78, 30, 4, 60)),
       "reversed vertical segments use the saved width and remain centered")
  [segment display];
  [segment flushWindow];
  PASS([segment isVisible] && segmentHasColor(segment, chosen),
       "resizing and redrawing a segment preserves its visible color")
  [delegate _hideConnectionLine];
  PASS(![segment isVisible], "hiding connections orders the segment out")
  [delegate _setConnectionLineSegmentFrom: NSMakePoint(80, 90)
                                      to: NSMakePoint(80, 30) index: 0];
  [segment display];
  [segment flushWindow];
  PASS([segment isVisible] && segmentHasColor(segment, chosen),
       "a hidden segment reappears in the chosen color at the same frame")
  PASS(![delegate _setConnectionLineSegmentFrom: NSMakePoint(20, 30)
                                           to: NSMakePoint(20, 30) index: 1],
       "coincident endpoints do not create a segment")

  [values setObject: [NSNumber numberWithBool: YES] forKey: @"DrawConnectionLine"];
  [defaults removeVolatileDomainForName: @"GormConnectorTests"];
  [defaults setVolatileDomain: values forName: @"GormConnectorTests"];
  [delegate showConnectionFrom: NSMakePoint(200, 300) to: NSMakePoint(400, 500)];
  vertical = [delegate _connectionLineWindowAtIndex: 1];
  PASS([segment isVisible] && [vertical isVisible]
       && NSEqualRects([vertical frame], NSMakeRect(398, 300, 4, 200))
       && segmentHasColor(segment, chosen) && segmentHasColor(vertical, chosen),
       "a diagonal connection shows both horizontal and vertical segments")

  {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 0.2];
    NSEvent *event;
    while ((event = [NSApp nextEventMatchingMask: NSAnyEventMask
                                      untilDate: deadline
                                         inMode: NSEventTrackingRunLoopMode
                                        dequeue: YES]) != nil)
      {
        [NSApp sendEvent: event];
        if ([deadline timeIntervalSinceNow] <= 0)
          break;
      }
  }
  PASS([vertical isVisible] && segmentHasColor(vertical, chosen),
       "the vertical segment survives window events during drag tracking")

  /* Exercise the real actions without retaining changes to user defaults. */
  [slider setIntValue: 3];
  [NSApp sendAction: [slider action] to: [slider target] from: slider];
  PASS([[[defaults persistentDomainForName: domain]
           objectForKey: @"ConnectorWidth"] integerValue] == 3 &&
       [[prefs valueForKey: @"thicknessValue"] intValue] == 3,
       "moving the slider saves the width and updates its label")
  [well setColor: [NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1]];
  [NSApp sendAction: [well action] to: [well target] from: well];
  PASS([[colorFromDict([[defaults persistentDomainForName: domain]
                        objectForKey: @"ConnectorColor"])
          colorUsingColorSpaceName: NSCalibratedRGBColorSpace] redComponent] == 1,
       "the color well action saves its chosen color")
  [prefs reset: nil];
  PASS([slider intValue] == 2 &&
       [[prefs valueForKey: @"thicknessValue"] intValue] == 2 &&
       [[[defaults persistentDomainForName: domain]
          objectForKey: @"ConnectorWidth"] integerValue] == 2 &&
       [[well color] isEqual: GormConnectionLineColor(nil)],
       "reset restores the factory width and color in controls and defaults")
  [values removeObjectForKey: @"ConnectorWidth"];
  [values removeObjectForKey: @"ConnectorColor"];
  [defaults removeVolatileDomainForName: @"GormConnectorTests"];
  [defaults setVolatileDomain: values forName: @"GormConnectorTests"];
  [delegate _setConnectionLineSegmentFrom: NSMakePoint(20, 30)
                                      to: NSMakePoint(80, 30) index: 0];
  PASS(NSEqualRects([segment frame], NSMakeRect(20, 29, 60, 2)),
       "an existing segment picks up the fallback width on its next update")
  [segment display];
  [segment flushWindow];
  PASS(segmentHasColor(segment, GormConnectionLineColor(nil)),
       "an existing segment redraws with the changed connector color")
  if (savedDomain != nil)
    [defaults setPersistentDomain: savedDomain forName: domain];
  else
    [defaults removePersistentDomainForName: domain];
  [savedDomain release];
  [delegate release];
  [prefs release];
  [defaults setSearchList: searchList];
  [defaults removeVolatileDomainForName: @"GormConnectorTests"];
  [searchList release];
  END_SET("Connector appearance")
  [pool drain];
  return 0;
}
