/* All rights reserved */


#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSLocale.h>

#import <AppKit/NSPopUpButton.h>

#import "GormLanguageViewController.h"

@implementation GormLanguageViewController

- (void) selectPreferredLanguage
{
  NSString *language = [[NSLocale preferredLanguages] objectAtIndex: 0];
  NSInteger i = [[ldict allKeys] indexOfObject: language];

  NSDebugLog(@"language = %@", language);

  // Set the default translation to the current language
  [sourceLanguage selectItemAtIndex: i];
  [targetLanguage selectItemAtIndex: i];

  // Set them since the above doesn't invoke the method that sets them.
  [self updateTargetLanguage: self];
  [self updateSourceLanguage: self];
}


- (void) viewDidLoad
{
  NSBundle *bundle = [NSBundle bundleForClass: [self class]];
  NSString *path = [bundle pathForResource: @"language-codes" ofType: @"plist"];

  [super viewDidLoad];
  if (path != nil)
    {
      [targetLanguage removeAllItems];
      [sourceLanguage removeAllItems];
      
      NSDebugLog(@"path = %@", path);
      
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

	  // Select preferred language in pop up...
	  [self selectPreferredLanguage];
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
  NSInteger i = [targetLanguage indexOfSelectedItem];
  targetLanguageIdentifier = [[ldict allKeys] objectAtIndex: i];
}

- (IBAction) updateSourceLanguage: (id)sender
{
  NSInteger i = [sourceLanguage indexOfSelectedItem];
  sourceLanguageIdentifier = [[ldict allKeys] objectAtIndex: i];
}

- (NSString *) sourceLanguageIdentifier
{
  return sourceLanguageIdentifier;
}

- (NSString *) targetLanguageIdentifier
{
  return targetLanguageIdentifier;
}

@end
