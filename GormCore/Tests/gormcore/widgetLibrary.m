/* Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <InterfaceBuilder/InterfaceBuilder.h>
#import <GormCore/GormDocument.h>
#import <GormCore/GormWidgetLibrary.h>

/* A small custom palette exercises both ordinary views and associated objects. */
@interface LibraryTestPalette : IBPalette
@end
@implementation LibraryTestPalette
- (id) init
{
  originalWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 250, 120)
    styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];
  [originalWindow setReleasedWhenClosed: NO];
  [originalWindow setTitle: @"Test Controls"];
  NSButton *button = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 90, 25)]);
  [button setTitle: @"Example Button"];
  [[originalWindow contentView] addSubview: button];
  NSButton *proxy = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(0, 40, 90, 25)]);
  [proxy setTitle: @"Number"];
  [[originalWindow contentView] addSubview: proxy];
  [self associateObject: AUTORELEASE([NSNumberFormatter new])
                  type: IBFormatterPboardType with: proxy];
  return self;
}
- (void) dealloc
{
  RELEASE(originalWindow);
  [super dealloc];
}
@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  START_SET("Widget library")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    SKIP("A graphical GNUstep backend is required (run under Xvfb)")
  NS_ENDHANDLER

  LibraryTestPalette *palette = [LibraryTestPalette new];
  GormWidgetLibrary *library = [GormWidgetLibrary new];
  NSArray *prototypes = [[[palette originalWindow] contentView] subviews];
  NSView *prototype = [prototypes objectAtIndex: 0];
  NSRect originalFrame = [prototype frame];
  [library addPalette: palette];
  NSPanel *panel = [library panel];
  NSArray *entries = [library valueForKey: @"entries"];
  NSScrollView *scroll = [library valueForKey: @"scrollView"];
  NSSearchField *search = [library valueForKey: @"searchField"];
  NSArray *rows = [[scroll documentView] subviews];
  PASS([entries count] == 2 && [rows count] == 2,
       "every palette prototype gets a library entry")
  PASS([[entries objectAtIndex: 0] valueForKey: @"object"] == prototype,
       "ordinary widgets retain the palette prototype for insertion")
  PASS([[[entries objectAtIndex: 1] valueForKey: @"object"] isKindOfClass: [NSNumberFormatter class]]
    && [[[entries objectAtIndex: 1] valueForKey: @"type"] isEqual: IBFormatterPboardType],
       "associated objects preserve their actual object and drag type")
  NSView *preview = [[[rows objectAtIndex: 0] subviews] objectAtIndex: 0];
  PASS(preview != prototype && [preview isKindOfClass: [NSButton class]],
       "the example is a separate, real widget")
  PASS([prototype superview] == [[palette originalWindow] contentView]
       && NSEqualRects([prototype frame], originalFrame),
       "opening the library leaves the original palette intact")

  [search setStringValue: @"EXAMPLE BUTTON"];
  [search sendAction: [search action] to: [search target]];
  PASS([[[scroll documentView] subviews] count] == 1,
       "search matches titles case-insensitively")
  [search setStringValue: @"validate"];
  [search sendAction: [search action] to: [search target]];
  PASS([[[scroll documentView] subviews] count] == 1,
       "search also matches descriptions")
  [search setStringValue: @"no such widget"];
  [search sendAction: [search action] to: [search target]];
  PASS([[[[scroll documentView] subviews] objectAtIndex: 0] isKindOfClass: [NSTextField class]],
       "an unmatched query displays an empty-state message")
  [search setStringValue: @"Test Controls"];
  [search sendAction: [search action] to: [search target]];
  PASS([[[scroll documentView] subviews] count] == 2,
       "search matches palette categories")

  GormDocument *document = [GormDocument new];
  NSPasteboard *pb = [NSPasteboard pasteboardWithUniqueName];
  id entry = [entries objectAtIndex: 0];
  PASS([document copyObject: [entry valueForKey: @"object"]
                      type: [entry valueForKey: @"type"] toPasteboard: pb],
       "library prototypes serialize through Gorm's document copy path")
  NSArray *copies = [NSUnarchiver unarchiveObjectWithData: [pb dataForType: IBViewPboardType]];
  PASS([[copies objectAtIndex: 0] isKindOfClass: [NSButton class]]
       && [copies objectAtIndex: 0] != prototype,
       "a drop receives a fresh widget, not the library row or its description")
  entry = [entries objectAtIndex: 1];
  [document copyObject: [entry valueForKey: @"object"]
                  type: [entry valueForKey: @"type"] toPasteboard: pb];
  copies = [NSUnarchiver unarchiveObjectWithData: [pb dataForType: IBFormatterPboardType]];
  PASS([[copies objectAtIndex: 0] isKindOfClass: [NSNumberFormatter class]],
       "formatter drops copy the formatter rather than its preview button")
  [pb releaseGlobally];
  RELEASE(document);

  [panel orderFront: nil];
  [[NSNotificationCenter defaultCenter] postNotificationName: IBWillBeginTestingInterfaceNotification object: nil];
  PASS(![panel isVisible], "the library hides while testing the interface")
  [[NSNotificationCenter defaultCenter] postNotificationName: IBWillEndTestingInterfaceNotification object: nil];
  PASS([panel isVisible], "the library reappears after testing")
  [library addPalette: palette];
  PASS([[[scroll documentView] subviews] count] == 4,
       "loading another palette refreshes an open library")
  [panel close];
  PASS([library panel] == panel, "closing the library preserves its panel for reopening")
  RELEASE(library);
  RELEASE(palette);
  END_SET("Widget library")
  [pool drain];
  return 0;
}
