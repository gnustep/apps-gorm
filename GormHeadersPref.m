#include "GormHeadersPref.h"

#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSOpenPanel.h>

@implementation GormHeadersPref


- (id) init
{
  _view = nil;

  self = [super init];
  
  if ( ! [NSBundle loadNibNamed:@"GormPrefHeaders" owner:self] )
    {
      NSLog(@"Can not load bundle GormPrefHeaders");
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
  NSArray	*fileTypes = [NSArray arrayWithObjects: @"h", @"H", nil];
  NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
  int		result;

  [openPanel setAllowsMultipleSelection: YES];
  [openPanel setCanChooseFiles: YES];
  [openPanel setCanChooseDirectories: NO];
  result = [openPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      [headers addObjectsFromArray: [openPanel filenames]];
      [browser reloadColumn: 0];
    }
}


- (void) removeAction: (id)sender
{
  NSCell *cell = [browser selectedCellInColumn: 0];

  if(cell != nil)
    {
      NSString *stringValue = [NSString stringWithString: [cell stringValue]];
      [headers removeObject: stringValue];
      [browser reloadColumn: 0];
      NSLog(@"Header removed");
    }
}


- (void) preloadAction: (id)sender
{
  if (sender != preloadButton) 
    return;
  
  {
    NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[preloadButton state] forKey:@"BACKUPFILE"];
    [defaults synchronize];
    if ( [preloadButton state] ==  NSOnState )
      {
	[addButton setEnabled:YES];
	[removeButton setEnabled: YES];
      }
    else
      {
	[addButton setEnabled:NO];
	[removeButton setEnabled:NO];
      }
  }


}

@end
