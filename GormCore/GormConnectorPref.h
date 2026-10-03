/* All rights reserved */

#ifndef INCLUDED_GormConnectorPref_H
#define INCLUDED_GormConnectorPref_H

#import <AppKit/AppKit.h>

@interface GormConnectorPref : NSObject
{
  IBOutlet id thicknessSlider;
  IBOutlet id window;
  IBOutlet id _view;
  IBOutlet id colorWell;
  IBOutlet id thicknessValue;
}

- (NSView *) view;

- (IBAction) ok: (id)sender;
- (IBAction) reset: (id)sender;

@end

#endif // INCLUDED_GormConnectorPref_H
