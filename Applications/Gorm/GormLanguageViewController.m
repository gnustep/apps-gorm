/* All rights reserved */


#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSPopUpButton.h>

#import "GormLanguageViewController.h"

@implementation GormLanguageViewController

- (void) viewDidLoad
{
  NSBundle *bundle = [NSBundle bundleForClass: [self class]];
  NSString *path = [bundle pathForResource: @"language-codes" ofType: @"plist"];

  [super viewDidLoad];
  if (path != nil)
    {
      [targetLanguage removeAllItems];
      [sourceLanguage removeAllItems];
      
      NSLog(@"path = %@", path);
      
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
  else
    {
      NSLog(@"Unable to load language codes");
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
