#include "GormGuidelinePref.h"
#include <GormCore/GormFunctions.h>

#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSColor.h>

@implementation GormGuidelinePref
- (id) init
{
  if((self = [super init]) != nil)
    {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      int spacing = [defaults integerForKey: @"GuideSpacing"];
      
      if ( ! [NSBundle loadNibNamed:@"GormPrefGuideline" owner:self] )
	{
	  NSLog(@"Can not load bundle GormPrefGuideline");
	  return nil;
	}

      [spacingSlider setIntValue: spacing];
      [currentSpacing setIntValue: spacing];
      [halfSpacing setIntValue: spacing/2];
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
  if(sender == spacingSlider)
    {
      int spacing = [spacingSlider intValue]; 
      [currentSpacing setIntValue: spacing];
      [halfSpacing setIntValue: spacing/2];
      [defaults setInteger: spacing forKey: @"GuideSpacing"];
    }
}

- (void) reset: (id)sender
{
  [spacingSlider setIntValue: 10];
  [self ok: spacingSlider];
}
@end
