#include "GormGeneralPref.h"

#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSMatrix.h>


static NSString *SHOWPALETTES=@"ShowPalettes";
static NSString *SHOWINSPECTOR=@"ShowInspectors";
static NSString *BACKUPFILE=@"BackupFile";
static NSString *ARCTYPE=@"ArchiveType";


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
    NSString *arcType = [defaults stringForKey: ARCTYPE];
 
    [inspectorButton setState: [defaults integerForKey: SHOWINSPECTOR]];
    [palettesButton setState: [defaults integerForKey: SHOWPALETTES]];
    [backupButton setState: [defaults integerForKey: BACKUPFILE]];

    
    if([arcType isEqual: @"Typed"])
      {
	[archiveMatrix setState: NSOnState atRow: 0 column: 0];
	[archiveMatrix setState: NSOffState atRow: 1 column: 0];
	[archiveMatrix setState: NSOffState atRow: 2 column: 0];
      }
    else if([arcType isEqual: @"Keyed"])
      {
	[archiveMatrix setState: NSOffState atRow: 0 column: 0];
	[archiveMatrix setState: NSOnState atRow: 1 column: 0];
	[archiveMatrix setState: NSOffState atRow: 2 column: 0];
      }
    else if([arcType isEqual: @"Both"])
      {
	[archiveMatrix setState: NSOffState atRow: 0 column: 0];
	[archiveMatrix setState: NSOffState atRow: 1 column: 0];
	[archiveMatrix setState: NSOnState atRow: 2 column: 0];
      }

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
  else
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
  else
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
  else
    {
      NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
      [defaults setInteger:[backupButton state] forKey:BACKUPFILE];
      [defaults synchronize];
    }
}

- (void) archiveAction: (id)sender
{
  if (sender != archiveMatrix) 
    return;
  else
    {
      NSUserDefaults *defaults =  [NSUserDefaults standardUserDefaults];
      if([[archiveMatrix cellAtRow: 0 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Typed" forKey: ARCTYPE];
	}
      else if([[archiveMatrix cellAtRow: 1 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Keyed" forKey: ARCTYPE];
	}
      else if([[archiveMatrix cellAtRow: 2 column: 0] state] == NSOnState)
	{
	  [defaults setObject: @"Both" forKey: ARCTYPE];
	}
      [defaults synchronize];
    }
}
@end

