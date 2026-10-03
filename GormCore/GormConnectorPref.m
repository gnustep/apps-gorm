/* All rights reserved */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>

#import "GormConnectorPref.h"
#import "GormPrivate.h"

@implementation GormConnectorPref

- (id) init
{
  if((self = [super init]) != nil)
    {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSColor *aColor = GormConnectionLineColor(defaults);
      NSInteger width = GormConnectionLineWidth(defaults);

      if ( [NSBundle loadNibNamed:@"GormPrefConnectors" owner:self] == NO )
	{
	  NSLog(@"Can not load bundle GormPrefConnectors");
	  return nil;
	} 

      [colorWell setColor: aColor];
      [thicknessSlider setIntValue: width];
      [thicknessValue setIntValue: width];

      _view = RETAIN([window contentView]);
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

- (IBAction) ok: (id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if (sender == thicknessSlider)
    {
      NSInteger width = [thicknessSlider intValue];

      if (width <= 0)
        {
          width = GormConnectionLineWidth(nil);
          [thicknessSlider setIntValue: width];
        }

      [thicknessValue setIntValue: width];
      [defaults setInteger: width
		    forKey: @"ConnectorWidth"];
    }
  else if (sender == colorWell)
    {
      NSColor *color = [[colorWell color]
                        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];

      [defaults setObject: colorToDict(color)
		   forKey: @"ConnectorColor"];
    }
}

- (IBAction) reset: (id)sender
{
  NSColor *aColor = GormConnectionLineColor(nil);

  [thicknessSlider setIntValue: GormConnectionLineWidth(nil)];
  [colorWell setColor: aColor];

  [self ok: thicknessSlider];
  [self ok: colorWell];
}

@end
