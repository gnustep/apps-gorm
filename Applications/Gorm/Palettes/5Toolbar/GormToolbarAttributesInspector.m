/* Implementation of class GormToolbarAttributesInspector
   Copyright (C) 2025 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 13-11-2025

   This file is part of GNUstep.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import "GormToolbarAttributesInspector.h"
#import <GormCore/NSToolbarPrivate.h>

@implementation GormToolbarAttributesInspector

- (id) init
{
  if ([super init] == nil)
    return nil;

  if ([NSBundle loadNibNamed: @"GormToolbarAttributesInspector" owner: self] == NO)
    {
      NSLog(@"Could not load GormToolbarAttributesInspector");
      return nil;
    }

  return self;
}

- (void) awakeFromNib
{
  // Setup...
  NSLog(@"_allowedItems = %@", _allowedItems);
  NSLog(@"_defaultItems = %@", _defaultItems);

  [_allowedItems setDelegate: self];
  [_defaultItems setDelegate: self];

  [_allowedItems setDataSource: self];
  [_defaultItems setDataSource: self];

  [_allowedItems reloadData];
  [_defaultItems reloadData];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self revert: self];
}

- (IBAction) ok: (id)sender
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil)
    return;
  
  // Save identifier - note: identifier is typically set at creation and shouldn't change
  // but we'll update it if the field has changed
  NSString *newIdentifier = [_identifier stringValue];
  if (newIdentifier && ![newIdentifier isEqualToString: [toolbar identifier]])
    {
      // Identifier changes require special handling - typically can't be changed after creation
      // For now, we'll just log a warning
      NSLog(@"Warning: Toolbar identifier cannot be changed after creation");
    }
  
  // Save display mode
  if (sender == _displayMode || sender == self)
    {
      NSToolbarDisplayMode displayMode = [[_displayMode selectedItem] tag];
      [toolbar setDisplayMode: displayMode];
    }
  
  // Save size mode
  if (sender == _sizeMode || sender == self)
    {
      NSToolbarSizeMode sizeMode = [[_sizeMode selectedItem] tag];
      [toolbar setSizeMode: sizeMode];
    }
  
  // Save boolean options
  if (sender == _allowsCustomization || sender == self)
    {
      [toolbar setAllowsUserCustomization: ([_allowsCustomization state] == NSOnState)];
    }
  
  if (sender == _autosaves || sender == self)
    {
      [toolbar setAutosavesConfiguration: ([_autosaves state] == NSOnState)];
    }
  
  if (sender == _visible || sender == self)
    {
      [toolbar setVisible: ([_visible state] == NSOnState)];
    }
  
  if (sender == _showsBaselineSeparator || sender == self)
    {
      [toolbar setShowsBaselineSeparator: ([_showsBaselineSeparator state] == NSOnState)];
    }
  
  // Note: Allowed and default items are typically managed through the toolbar's delegate
  // and would require more complex handling. For now, they're display-only in the inspector.
  
  [super ok: sender];
}

- (IBAction) revert: (id)sender
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil)
    return;
    
  // Load toolbar identifier
  [_identifier setStringValue: [toolbar identifier] ? [toolbar identifier] : @""];
  
  // Load display mode
  NSToolbarDisplayMode displayMode = [toolbar displayMode];
  [_displayMode selectItemWithTag: displayMode];
  
  // Load size mode
  NSToolbarSizeMode sizeMode = [toolbar sizeMode];
  [_sizeMode selectItemWithTag: sizeMode];
  
  // Load boolean options
  [_allowsCustomization setState: [toolbar allowsUserCustomization] ? NSOnState : NSOffState];
  [_autosaves setState: [toolbar autosavesConfiguration] ? NSOnState : NSOffState];
  [_visible setState: [toolbar isVisible] ? NSOnState : NSOffState];
  [_showsBaselineSeparator setState: [toolbar showsBaselineSeparator] ? NSOnState : NSOffState];
  
  // Reload the table views for allowed and default items
  [_allowedItems reloadData];
  [_defaultItems reloadData];
  
  [super revert: sender];
}

// MARK: - NSTableView DataSource Methods

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil)
    return 0;
  
  if (tableView == _allowedItems)
    {
      NSArray *items = [toolbar allowedItemIdentifiers];
      return items ? [items count] : 0;
    }
  else if (tableView == _defaultItems)
    {
      NSArray *items = [toolbar defaultItemIdentifiers];
      return items ? [items count] : 0;
    }
  
  return 0;
}

- (id) tableView: (NSTableView *)tableView 
       objectValueForTableColumn: (NSTableColumn *)tableColumn
       row: (NSInteger)row
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil)
    return nil;
  
  if (tableView == _allowedItems)
    {
      NSArray *items = [toolbar allowedItemIdentifiers];
      if (items && row >= 0 && row < [items count])
        {
          return [items objectAtIndex: row];
        }
    }
  else if (tableView == _defaultItems)
    {
      NSArray *items = [toolbar defaultItemIdentifiers];
      if (items && row >= 0 && row < [items count])
        {
          return [items objectAtIndex: row];
        }
    }
  
  return nil;
}

- (void) tableView: (NSTableView *)tableView
    setObjectValue: (id)value
    forTableColumn: (NSTableColumn *)tableColumn
               row: (NSInteger)row
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil || value == nil)
    return;
  
  if (tableView == _allowedItems)
    {
      NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
      if (items && row >= 0 && row < [items count])
        {
          [items replaceObjectAtIndex: row withObject: value];
          [toolbar setAllowedItemIdentifiers: items];
          [self touch: self];
        }
      RELEASE(items);
    }
  else if (tableView == _defaultItems)
    {
      NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
      if (items && row >= 0 && row < [items count])
        {
          [items replaceObjectAtIndex: row withObject: value];
          [toolbar setDefaultItemIdentifiers: items];
          [self touch: self];
        }
      RELEASE(items);
    }
}

// MARK: - NSTableView Delegate Methods

- (BOOL) tableView: (NSTableView *)tableView 
       shouldEditTableColumn: (NSTableColumn *)tableColumn
       row: (NSInteger)row
{
  // Allow editing of item identifiers
  return YES;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
  // Handle selection changes if needed
  NSTableView *tableView = [notification object];
  NSInteger selectedRow = [tableView selectedRow];
  
  NSLog(@"Selected row %ld in table %@", (long)selectedRow, 
        tableView == _allowedItems ? @"allowed items" : @"default items");
}

// MARK: - Helper Methods for Managing Items

- (NSString *) stringValueForTag: (NSInteger)tag
{
  NSString *result = nil;

  /*
  APPKIT_EXPORT NSString *NSToolbarSeparatorItemIdentifier;
  APPKIT_EXPORT NSString *NSToolbarSpaceItemIdentifier;
  APPKIT_EXPORT NSString *NSToolbarFlexibleSpaceItemIdentifier;
  APPKIT_EXPORT NSString *NSToolbarShowColorsItemIdentifier;
  APPKIT_EXPORT NSString *NSToolbarShowFontsItemIdentifier;
  APPKIT_EXPORT NSString *NSToolbarCustomizeToolbarItemIdentifier;
  APPKIT_EXPORT NSString *NSToolbarPrintItemIdentifier;
  */

  if (tag == 0)
    {
      result = NSToolbarSeparatorItemIdentifier;
    }
  else if (tag == 1)
    {
      result = NSToolbarSpaceItemIdentifier;
    }
  else if (tag == 2)
    {
      result = NSToolbarFlexibleSpaceItemIdentifier;
    }
  else if (tag == 3)
    {
      result = NSToolbarShowColorsItemIdentifier;
    }
  else if (tag == 4)
    {
      result = NSToolbarShowFontsItemIdentifier;
    }
  else if (tag == 5)
    {
      result = NSToolbarCustomizeToolbarItemIdentifier;
    }
  else if (tag == 6)
    {
      result = NSToolbarPrintItemIdentifier;
    }

  return result;
}

- (IBAction) addAllowedItem: (id)sender
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil)
    return;
  
  NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
  if (items == nil)
    {
      items = [[NSMutableArray alloc] init];
    }
  
  // Add a placeholder item identifier
  NSInteger tag = [[_defaultButton selectedItem] tag];
  NSString *identifier = [self stringValueForTag: tag];

  if ([items containsObject: identifier] == NO)
    {
      [items addObject: identifier];
      [toolbar setAllowedItemIdentifiers: items];
      RELEASE(items);
    }
  
  [_allowedItems reloadData];
  [self touch: self];
}

- (IBAction) removeAllowedItem: (id)sender
{
  NSToolbar *toolbar = (NSToolbar *)object;
  NSInteger selectedRow = [_allowedItems selectedRow];
  
  if (toolbar == nil || selectedRow < 0)
    return;
  
  NSMutableArray *items = [[toolbar allowedItemIdentifiers] mutableCopy];
  if (items && selectedRow < [items count])
    {
      [items removeObjectAtIndex: selectedRow];
      [toolbar setAllowedItemIdentifiers: items];
      RELEASE(items);
      
      [_allowedItems reloadData];
      [self touch: self];
    }
}

- (IBAction) addDefaultItem: (id)sender
{
  NSToolbar *toolbar = (NSToolbar *)object;
  
  if (toolbar == nil)
    return;
  
  NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
  if (items == nil)
    {
      items = [[NSMutableArray alloc] init];
    }
  
  // Add a placeholder item identifier
  NSInteger tag = [[_defaultButton selectedItem] tag];
  NSString *identifier = [self stringValueForTag: tag];

  if ([items containsObject: identifier] == NO)
    {
      [items addObject: identifier];
      [toolbar setDefaultItemIdentifiers: items];
      RELEASE(items);
    }
  
  [_defaultItems reloadData];
  [self touch: self];
}

- (IBAction) removeDefaultItem: (id)sender
{
  NSToolbar *toolbar = (NSToolbar *)object;
  NSInteger selectedRow = [_defaultItems selectedRow];
  
  if (toolbar == nil || selectedRow < 0)
    return;
  
  NSMutableArray *items = [[toolbar defaultItemIdentifiers] mutableCopy];
  if (items && selectedRow < [items count])
    {
      [items removeObjectAtIndex: selectedRow];
      [toolbar setDefaultItemIdentifiers: items];
      RELEASE(items);
      
      [_defaultItems reloadData];
      [self touch: self];
    }
}

@end
