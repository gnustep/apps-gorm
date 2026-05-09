/* All rights reserved */

#import "GormViewAttributesInspector.h"


@implementation NSView (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormViewAttributesInspector";
}
@end

@implementation GormViewAttributesInspector

- init
{
  self = [super init];
  if (self != nil)
    {
      NSBundle *bundle = [NSBundle bundleForClass: [self class]];
      
      if ([bundle loadNibNamed: @"GormViewAttributesInspector" 
			 owner: self
	       topLevelObjects: NULL] == NO)
	{
	  NSLog(@"Could not open gorm GormViewAttributesInspector");
	  NSLog(@"self %@", self);
	  return nil;
	}
    }

  return self;
}

- (IBAction) ok: (id)sender
{
  if (object == nil)
    {
      return;
    }
  else
    {
      NSRect frame = [object frame];

      if (sender == xpos)
	{
	  frame.origin.x = [xpos floatValue];
	}
      else if (sender == ypos)
	{
	  frame.origin.y = [ypos floatValue];
	}
      else if (sender == width)
	{
	  frame.size.width = [xpos floatValue];
	}
      else if (sender == height)
	{
	  frame.size.height = [xpos floatValue];
	}
      else if (sender == theClass)
	{
	  // non-editable...
	}
      else if (sender == identifier)
	{
	  if ([object respondsToSelector: @selector(setIdentifier:)])
	    {
	      [object performSelector: @selector(setIdentifier:)
			   withObject: [identifier stringValue]];
	    }
	}
      else if (sender == tag)
	{
	  [object setTag: [tag integerValue]];
	}

      // reset the frame...
      [object setFrame: frame];
      [object setNeedsDisplay: YES];

      id sv = [object superview];
      [sv setNeedsDisplay: YES];
    }
}

- (IBAction) revert: (id)sender
{
  if (object == nil)
    {
      return;
    }
  else
    {
      NSRect frame = [object frame];
      NSString *className = NSStringFromClass([object class]);

      [theClass setStringValue: className];

      if ([object respondsToSelector: @selector(identifier)])
	{
	  id ident = [object performSelector: @selector(identifier)];
	  [identifier setEditable: YES];
	  [identifier setStringValue: ident];
	}
      else
	{
	  [identifier setEditable: NO];
	  [identifier setStringValue: @"N/A"];
	}

      // Set properties
      [flipped setState: ([object isFlipped] == YES) ? NSOnState : NSOffState];
      [opaque setState: ([object isOpaque] == YES) ? NSOnState : NSOffState];

      // Set the frame information...
      [xpos setFloatValue: frame.origin.x];
      [ypos setFloatValue: frame.origin.y];
      [width setFloatValue: frame.size.width];
      [height setFloatValue: frame.size.height];

      [tag setIntegerValue: [object tag]];
    }
}

/* delegate for tag and Forms */
- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  [self ok: [aNotification object]];
}

@end
