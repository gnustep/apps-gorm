/* GormLanguageViewController.h
 *
 * Copyright (C) 2023 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	2023
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef GormLanguageViewController_H_INCLUDE
#define GormLanguageViewController_H_INCLUDE

#import <AppKit/NSViewController.h>

@class NSDictionary, NSString;

/**
 * GormLanguageViewController manages the language selection UI used for
 * translation features. It tracks the current source and target language
 * identifiers and updates them in response to user input.
 */
@interface GormLanguageViewController : NSViewController
{
  IBOutlet id targetLanguage;
  IBOutlet id sourceLanguage;

  NSString *sourceLanguageIdentifier;
  NSString *targetLanguageIdentifier;
  
  NSDictionary *ldict;
}

/**
 * Update the target language based on the sender’s current selection.
 */
- (IBAction) updateTargetLanguage: (id)sender;
/**
 * Update the source language based on the sender’s current selection.
 */
- (IBAction) updateSourceLanguage: (id)sender;

/**
 * The currently selected source language identifier.
 */
- (NSString *) sourceLanguageIdentifier;
/**
 * The currently selected target language identifier.
 */
- (NSString *) targetLanguageIdentifier;


@end

#endif // GormLanguageViewController_H_INCLUDE
