/* Copyright (C) 2026 Free Software Foundation, Inc.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

/* Configuration matters even when two prototypes have the same class. */
static void checkControlVariants(id<IBPaletteDescriptions> palette)
{
  NSButton *button = AUTORELEASE([NSButton new]);
  NSMutableSet *descriptions = [NSMutableSet set];
  NSTextField *field = AUTORELEASE([NSTextField new]);
  NSPopUpButton *popup = AUTORELEASE([NSPopUpButton new]);
  NSString *first;

  [button setButtonType: NSMomentaryPushInButton];
  [descriptions addObject: [palette descriptionForObject: button]];
  [button setButtonType: NSSwitchButton];
  [descriptions addObject: [palette descriptionForObject: button]];
  [button setButtonType: NSRadioButton];
  [descriptions addObject: [palette descriptionForObject: button]];
  PASS([descriptions count] == 3,
    "command buttons, checkboxes, and radio buttons have distinct descriptions")

  [field setEditable: YES];
  first = [palette descriptionForObject: field];
  [field setEditable: NO];
  PASS(![first isEqual: [palette descriptionForObject: field]],
    "editable fields and read-only labels have distinct descriptions")
  [popup setPullsDown: NO];
  first = [palette descriptionForObject: popup];
  [popup setPullsDown: YES];
  PASS(![first isEqual: [palette descriptionForObject: popup]],
    "pop-up choices and pull-down commands have distinct descriptions")
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSArray *names = [NSArray arrayWithObjects: @"0Menus", @"1Windows",
    @"2Controls", @"3Containers", @"4Data", @"5Toolbar", @"6Formatters", nil];
  NSUInteger i;

  START_SET("Descriptions for built-in palette objects")
  [NSApplication sharedApplication];
  for (i = 0; i < [names count]; i++)
    {
      NSString *name = [names objectAtIndex: i];
      NSString *path = [NSString stringWithFormat: @"../../%@/%@.palette", name, name];
      NSBundle *bundle;
      NSDictionary *info;
      IBPalette *palette;
      NSArray *views;
      NSMutableSet *details = [NSMutableSet set];
      NSUInteger j;

      bundle = [NSBundle bundleWithPath: path];
      info = [NSDictionary dictionaryWithContentsOfFile:
        [bundle pathForResource: @"palette" ofType: @"table"]];
      palette = [[[bundle classNamed: [info objectForKey: @"Class"]] alloc] init];
      PASS(palette != nil, "%s palette loads from the build tree", [name UTF8String])
      [palette finishInstantiate];
      views = [[[palette originalWindow] contentView] subviews];
      PASS([views count] > 0, "%s has prototypes", [name UTF8String])
      for (j = 0; j < [views count]; j++)
        {
          id object = [IBPalette objectForView: [views objectAtIndex: j]];
          NSString *detail = [(id<IBPaletteDescriptions>)palette descriptionForObject: object];
          PASS([detail length] > 0, "%s prototype %lu (%s) has a description",
            [name UTF8String], (unsigned long)j, [NSStringFromClass([object class]) UTF8String])
          if (detail != nil)
            [details addObject: detail];
        }
      if ([name isEqual: @"2Controls"])
        checkControlVariants((id<IBPaletteDescriptions>)palette);
      /* These palettes have a distinct purpose for every supplied prototype. */
      if (![name isEqual: @"2Controls"])
        PASS([details count] == [views count],
          "%s prototypes have distinct descriptions", [name UTF8String])
      PASS([(id<IBPaletteDescriptions>)palette descriptionForObject: nil] == nil,
        "%s ignores nil", [name UTF8String])
      PASS([(id<IBPaletteDescriptions>)palette descriptionForObject: @"unrelated"] == nil,
        "%s ignores unrelated objects", [name UTF8String])
    }
  END_SET("Descriptions for built-in palette objects")
  RELEASE(pool);
  return 0;
}
