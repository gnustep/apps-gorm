#include "GormColorsPref.h"
#include "GormFunctions.h"

#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSColor.h>

@implementation GormColorsPref
- (id) init
{
  _view = nil;

  self = [super init];
  if(self != nil)
    {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSColor *aColor = colorFromDict([defaults objectForKey: @"GuideColor"]);
      
      // default the color to something, if nothing is returned.
      if(aColor == nil)
	{
	  aColor = [NSColor redColor];
	}

      if ( ! [NSBundle loadNibNamed:@"GormPrefColors" owner:self] )
	{
	  NSLog(@"Can not load bundle GormPrefColors");
	  return nil;
	}

      [color setColor: aColor];
    
    _view =  [[window contentView] retain];
    }
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

- (void) ok: (id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject: colorToDict([color color]) forKey: @"GuideColor"];
}
@end
