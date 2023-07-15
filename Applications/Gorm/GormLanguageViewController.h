/* All rights reserved */

#ifndef GormLanguageViewController_H_INCLUDE
#define GormLanguageViewController_H_INCLUDE

#import <AppKit/NSViewController.h>

@class NSDictionary, NSString;

@interface GormLanguageViewController : NSViewController
{
  IBOutlet id targetLanguage;
  IBOutlet id sourceLanguage;

  NSString *sourceLanguageIdentifier;
  NSString *targetLanguageIdentifier;
  
  NSDictionary *ldict;
}

- (IBAction) updateTargetLanguage: (id)sender;
- (IBAction) updateSourceLanguage: (id)sender;

- (NSString *) sourceLanguageIdentifier;
- (NSString *) targetLanguageIdentifier;


@end

#endif // GormLanguageViewController_H_INCLUDE
