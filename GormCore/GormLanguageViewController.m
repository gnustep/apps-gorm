/* All rights reserved */


#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSPopUpButton.h>

#import "GormLanguageViewController.h"

@implementation GormLanguageViewController

- (void) viewDidLoad
{
  NSString *path = [[self nibBundle] pathForResource: @"language-codes" ofType: @"plist"];
  
  [super viewDidLoad];

  ldict = [[NSDictionary alloc] initWithContentsOfFile: path];
  if (ldict != nil)
    {
      NSEnumerator *en = [ldict keyEnumerator];
      id k = nil;
      
      while ((k = [en nextObject]) != nil)
	{
	  NSString *v = [ldict objectForKey: k];
	  NSString *itemTitle = [NSString stringWithFormat: @"%@ (%@)", k, v];
	  
	  [targetLanguage addItemWithTitle: itemTitle];
	  [sourceLanguage addItemWithTitle: itemTitle];
	}
    }
}

- (void) dealloc
{
  RELEASE(ldict);
  [super dealloc];
}

- (IBAction) updateTargetLanguage: (id)sender
{
  // Nothing yet...
}

- (IBAction) updateSourceLanguage: (id)sender
{
  // Nothing yet...
}

- (NSString *) sourceLanguageIdentifier
{
  NSInteger i = [sourceLanguage indexOfSelectedItem];
  return [[ldict allKeys] objectAtIndex: i];
}

- (NSString *) targetLanguageIdentifier
{
  NSInteger i = [sourceLanguage indexOfSelectedItem];
  return [[ldict allKeys] objectAtIndex: i];
}

@end
