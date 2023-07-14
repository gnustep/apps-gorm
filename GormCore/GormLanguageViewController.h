/* All rights reserved */

#ifndef GormLanguageController_H_INCLUDE
#define GormLanguageController_H_INCLUDE

#import <AppKit/NSViewController.h>
#import <AppKit/NSPopUpButton.h>

@interface GormLanguageViewController : NSViewController
{
  IBOutlet NSPopUpButton *sourceLanguage;
  IBOutlet NSPopUpButton *targetLanguage;
}

@end

#endif  // GormLanguageController_H_INCLUDE
