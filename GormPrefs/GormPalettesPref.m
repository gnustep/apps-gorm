#include <GormCore/GormPrivate.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibLoading.h>
#include "GormPalettesPref.h"

@class NSTableView;

// data source...
@interface PaletteDataSource : NSObject
@end

@implementation PaletteDataSource
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *list = [defaults objectForKey: @"UserPalettes"];
  return [list count];
}

- (id)          tableView: (NSTableView *)tv
objectValueForTableColumn: (NSTableColumn *)tc
	              row: (int)rowIndex
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *list = [defaults objectForKey: @"UserPalettes"];
  id value = nil;
  if([list count] > 0)
    {
      value = [[list objectAtIndex: rowIndex] lastPathComponent];
    }
  return value;
}
@end


@implementation GormPalettesPref
- (id) init
{
  _view = nil;

  self = [super init];
  
  if ( ! [NSBundle loadNibNamed:@"GormPrefPalettes" owner:self] )
    {
      NSLog(@"Can not load bundle GormPrefPalettes");
      return nil;
    }
  
  _view =  [[window contentView] retain];
  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_view);
  [super dealloc];
}


-(NSView *) view
{
  return _view;
}

- (void) addAction: (id)sender
{
  [[(id<Gorm>)NSApp palettesManager] openPalette: self];
  [table reloadData];
}


- (void) removeAction: (id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *list = [defaults objectForKey: @"UserPalettes"];
  int row = [table selectedRow];

  if(row >= 0)
    {
      NSString *stringValue = [list objectAtIndex: row];
      
      if(stringValue != nil)
	{
	  [list removeObject: stringValue];
	  [defaults setObject: list forKey: @"UserPalettes"];
	  [table reloadData];
	}
    }
}

- (BOOL)    tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)aTableColumn
		  row: (int)rowIndex
{
  BOOL result = NO;
  return result;
}

- (BOOL) tableView: (NSTableView *)tv
   shouldSelectRow: (int)rowIndex
{
  BOOL result = YES;
  return result;
}

@end
