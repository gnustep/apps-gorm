#import "GormNixClassMappings.h"

NSDictionary *GormNixDefaultClassMappings(void)
{
  static NSDictionary *mappings = nil;
  if (mappings == nil)
    mappings = [[NSDictionary alloc] initWithObjectsAndKeys:
      @"NSWindow", @"GormNSWindow",
      @"NSPanel", @"GormNSPanel",
      @"NSMenu", @"GormNSMenu",
      @"NSMenuView", @"GormNSMenuView",
      @"NSPopUpButton", @"GormNSPopUpButton",
      @"NSPopUpButtonCell", @"GormNSPopUpButtonCell",
      @"NSBrowser", @"GormNSBrowser",
      @"NSTableView", @"GormNSTableView",
      @"NSOutlineView", @"GormNSOutlineView",
      nil];
  return mappings;
}
