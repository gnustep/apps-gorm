#include "GormPrefController.h"
#include "GormGeneralPref.h"
#include "GormHeadersPref.h"
#include "GormShelfPref.h"
#include "GormColorsPref.h"
#include "GormPalettesPref.h"

#include <AppKit/NSBox.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>

@implementation GormPrefController

- (void) awakeFromNib
{
  _generalView  = [[GormGeneralPref alloc] init];
  _headersView  = [[GormHeadersPref alloc] init];
  _shelfView    = [[GormShelfPref alloc] init];
  _colorsView   = [[GormColorsPref alloc] init];
  _palettesView = [[GormPalettesPref alloc] init];
  [prefBox setContentView:[_generalView view]];

  [[self window] setFrameUsingName: @"Preferences"];
  [[self window] setFrameAutosaveName: @"Preferences"];
  [[self window] center];
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
      case 3:
	[prefBox setContentView: [_colorsView view]];
	break;
      case 4:
	[prefBox setContentView: [_palettesView view]];
	break;
      default:
	NSLog(@"Error Default (GormPrefController.m) : - (void) popupAction: (id)sender, no match for tag %d",tag);
	break;
      }
  }
}

- (void) dealloc
{
  RELEASE(_generalView);
  RELEASE(_headersView);
  RELEASE(_shelfView);
  RELEASE(_colorsView);
  RELEASE(_palettesView);
  [super dealloc];
}
@end
