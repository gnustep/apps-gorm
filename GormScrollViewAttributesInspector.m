/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormScrollViewAttributesInspector.h"
#include <InterfaceBuilder/IBObjectAdditions.h>

@implementation NSScrollView (IBObjectAdditions)
- (NSString *) inspectorClassName
{
  return @"GormScrollViewAttributesInspector";
}
@end

@implementation GormScrollViewAttributesInspector
- init
{
  self = [super init];
  if (self != nil)
    {
      if ([NSBundle loadNibNamed: @"GormScrollViewAttributesInspector" 
		    owner: self] == NO)
	{
	  
	  NSDictionary	*table;
	  NSBundle	*bundle;
	  table = [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"];
	  bundle = [NSBundle mainBundle];
	  if ([bundle loadNibFile: @"GormScrollViewAttributesInspector"
		      externalNameTable: table
		      withZone: [self zone]] == NO)
	    {
	      NSLog(@"Could not open gorm GormScrollViewAttributesInspector");
	      NSLog(@"self %@", self);
	      return nil;
	    }
	}
    }

  return self;
}

- (void) _getValuesFromObject
{
  [color setColor: [object backgroundColor]];
  [horizontalScroll setState: [object hasHorizontalScroller]?NSOnState:NSOffState];
  [verticalScroll setState: [object hasVerticalScroller]?NSOnState:NSOffState];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject];
}

- (void) colorSelected: (id)sender
{
  /* insert your code here */
  [object setBackgroundColor: [color color]];
}


- (void) verticalSelected: (id)sender
{
  /* insert your code here */
  [object setHasVerticalScroller: ([verticalScroll state] == NSOnState)];
}


- (void) horizontalSelected: (id)sender
{
  /* insert your code here */
  [object setHasHorizontalScroller: ([horizontalScroll state] == NSOnState)];
}


- (void) borderSelected: (id)sender
{
  /* insert your code here */
  [object setBorderType: [[borderMatrix selectedCell] tag]];
}

@end
