/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormFontViewController.h"

@implementation GormFontViewController

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // load the gui...
      if (![NSBundle loadNibNamed: @"GormFontView"
		     owner: self])
	{
	  NSLog(@"Could not open gorm GormFontView");
	  return nil;
	}
      [[NSFontManager sharedFontManager] setDelegate: self];
    }
  return self;
}

- (void) selectFont: (id)sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *font = nil;

  switch([fontSelector indexOfSelectedItem])
    {
    case 0: // selected font
      font = [fontManager selectedFont];
      break;
    case 1: // bold system font
      font = [NSFont boldSystemFontOfSize: 0];
      break;
    case 2: // system font
      font = [NSFont systemFontOfSize: 0];
      break;
    case 3: // user fixed font
      font = [NSFont userFixedPitchFontOfSize: 0];
      break;
    case 4: // user font
      font = [NSFont userFontOfSize: 0];
      break;
    case 5: // title bar font
      font = [NSFont titleBarFontOfSize: 0];
      break;
    case 6: // menu font
      font = [NSFont menuFontOfSize: 0];
      break;
    case 7: // message font
      font = [NSFont messageFontOfSize: 0];
      break;
    case 8: // palette font
      font = [NSFont paletteFontOfSize: 0];
      break;
    case 9: // tooltops font
      font = [NSFont toolTipsFontOfSize: 0];
      break;
    case 10: // control content font
      font = [NSFont controlContentFontOfSize: 0];
      break;
    case 11:
      font = [NSFont labelFontOfSize: 0];
      break;
    default:
      font = nil;
      break;
    }

  if(font != nil)
    {
      [fontManager setSelectedFont: font isMultiple: NO];
    }
}

- (id) view
{
  return view;
}

/*
- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) becomeFirstResponder
{
  return YES;
}

// delegate methods
- (void) changeFont: (id)sender
{
  NSLog(@"change");
  [fontSelector selectItem: 0];
}
*/

@end
