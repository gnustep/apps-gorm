#include "GormGeneralPref.h"

#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>


static NSString *SHOWPALETTES=@"ShowPalettes";
static NSString *SHOWINSPECTOR=@"ShowInspectors";
static NSString *BACKUPFILE=@"BackupFile";



@implementation GormGeneralPref

- (id) init
{
  _view = nil;

  self = [super init];
  
  if ( ! [NSBundle loadNibNamed:@"GormPrefGeneral" owner:self] )
    {
      NSLog(@"Can not load bundle GormPrefGeneral");
      return nil;
    }

  _view =  [[window contentView] retain];

  //Defaults
  {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [inspectorButton setState: [defaults integerForKey: SHOWINSPECTOR]];
    [palettesButton setState:[ defaults integerForKey: SHOWPALETTES]];
    [backupButton setState:[ defaults integerForKey: BACKUPFILE]];
  }

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_view);
  [super dealloc];
}

- (NSView *) view 
{
  return _view;
}

/* IBActions */
- (void) palettesAction: (id)sender
{
  if (sender != palettesButton) 
    return;
  {
    NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[palettesButton state] forKey:SHOWPALETTES];
    [defaults synchronize];
  }
}


- (void) inspectorAction: (id)sender
{
  if (sender != inspectorButton) 
    return;
  {
    NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[inspectorButton state] forKey:SHOWINSPECTOR];
    [defaults synchronize];
  }
}


- (void) backupAction: (id)sender
{
  if (sender != backupButton) 
    return;
  {
    NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[backupButton state] forKey:BACKUPFILE];
    [defaults synchronize];
  }
}

@end
