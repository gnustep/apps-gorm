#include "GormPrefController.h"
#include "GormGeneralPref.h"
#include "GormHeadersPref.h"
#include "GormShelfPref.h"

#include <AppKit/NSBox.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>

@implementation GormPrefController

- (void) awakeFromNib
{
  _generalView = [[GormGeneralPref alloc] init];
  _headersView = [[GormHeadersPref alloc] init];
  _shelfView   = [[GormShelfPref alloc] init];

  [prefBox setContentView:[_generalView view]];

  [[self window] setFrameUsingName: @"Preferences"];
  [[self window] setFrameAutosaveName: @"Preferences"];
}


- (void) popupAction: (id)sender
{
  if ( sender != popup )
    return;

  {
    int tag = [[sender selectedItem] tag];
    switch(tag)
      {
      case 0: 
	[prefBox setContentView: [_generalView view]];
	break;	
      case 1:
	[prefBox setContentView: [_headersView view]];
	break;
      case 2:
	[prefBox setContentView: [_shelfView view]];
	break;
      default:
	NSLog(@"Ouch Default : - (void) popupAction: (id)sender");
	break;
      }
  }
}

@end
