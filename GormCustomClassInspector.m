/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormCustomClassInspector.h"
#include "GormPrivate.h"
#include "GormClassManager.h"

@implementation GormCustomClassInspector
+ (void) initialize
{
  if (self == [GormCustomClassInspector class])
    {
      // TBD
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSDictionary  *table = nil;
      NSBundle	*bundle = nil;
      _classManager = nil;
      _currentSelection = nil;
      _currentSelectionClassName = nil;

      if (![NSBundle loadNibNamed: @"GormCustomClassInspector"
		     owner: self])
	{
	  NSLog(@"Could not open gorm GormCustomClassInspector");
	  NSLog(@"self %@", self);
	  return nil;
	}
      else
	{
	  [[NSNotificationCenter defaultCenter] 
	    addObserver: self
	    selector: @selector(handleNotification:)
	    name: IBSelectionChangedNotification
	    object: nil];
	}
    }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) _setCurrentSelectionClassName: (id)anobject
{
  NSString *prefix = nil, *substring = nil;

  ASSIGN(_currentSelectionClassName, NSStringFromClass([anobject class]));
  prefix = [_currentSelectionClassName substringToIndex: 4];
  if([prefix isEqualToString: @"Gorm"])
    {
      substring = [_currentSelectionClassName substringFromIndex: 4];
      ASSIGN(_currentSelectionClassName, substring);
    }
  NSLog(@"%@",_currentSelectionClassName);
}

- (void) handleNotification: (NSNotification*)aNotification
{
  id editor = [aNotification object];

  if([editor respondsToSelector: @selector(document)])
    {
      id doc = [editor document];
      NSArray *selections = [editor selection];
      
      if([selections count] == 1)
	{
	  _classManager = [doc classManager];
	  _currentSelection = [selections objectAtIndex: 0];
	  [self _setCurrentSelectionClassName: _currentSelection];
	  [browser reloadColumn: 0];
	}
      else
	{
	  _currentSelection = nil;
	  NSLog(@"Invalid selection");
	}
    }
}

- (void) awakeFromNib
{
  [browser setTarget: self];
  [browser setAction: @selector(select:)];
}

- (void) select: (id)sender
{
  /* insert your code here */
  NSLog(@"Selected");
}

- (NSArray *)_additionalSubclasses
{
  NSArray *result = nil;
  if([_currentSelectionClassName isEqualToString: @"NSTextField"])
    {
      result = [NSArray arrayWithObject: @"NSSecureTextField"];
    }
  else if([_currentSelectionClassName isEqualToString: @"NSWindow"])
    {
      result = [NSArray arrayWithObject: @"NSPanel"];
    }
  return result;
}

// Browser delegate

- (BOOL) browser: (NSBrowser*)sender 
       selectRow: (int)row 
	inColumn: (int)column
{
  return YES;
}

- (void)    browser: (NSBrowser *)sender 
createRowsForColumn: (int)column
	   inMatrix: (NSMatrix *)matrix
{
  NSMutableArray  *classes = [NSMutableArray arrayWithObject: _currentSelectionClassName];
  NSEnumerator          *e = nil;
  NSString          *class = nil;
  NSBrowserCell      *cell = nil;
  int i = 0;

  [classes addObjectsFromArray: [_classManager allCustomSubclassesOf: _currentSelectionClassName]];
  [classes addObjectsFromArray: [self _additionalSubclasses]];
  e = [classes objectEnumerator];
  while((class = [e nextObject]) != nil)
    {
      [matrix insertRow: i withCells: nil];
      cell = [matrix cellAtRow: i column: 0];
      [cell setLeaf: YES];
      i++;
      [cell setStringValue: class];
    }
}

- (NSString*) browser: (NSBrowser*)sender 
	titleOfColumn: (int)column
{
  NSLog(@"Delegate called");
  return @"Class";
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
}

- (BOOL) browser: (NSBrowser *)sender 
   isColumnValid: (int)column
{
  return YES;
}
@end

