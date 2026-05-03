/* GormAppDelegate.m
 *
 * Copyright (C) 2023 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg.casamento@gmail.com>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111
 * USA.
 */

#ifndef GormAppDelegate_H_INCLUDE
#define GormAppDelegate_H_INCLUDE

#import <AppKit/NSSavePanel.h>

#import <GormCore/GormCore.h>
#import <GormCore/GormPrefs.h>

#import <GNUstepBase/GSObjCRuntime.h>

@class NSDictionary;
@class NSImage;
@class NSMenu;
@class NSMutableArray;
@class NSSet;
@class GormLanguageViewController;

/**
 * GormAppDelegate wires application-level actions for Gorm: opening the
 * preferences panel, clipboard commands, showing inspectors and palettes,
 * importing images and sounds, grouping/ungrouping views, class-related
 * utilities, translation workflows (XLIFF/strings), and printing.
 */
@interface GormAppDelegate : GormAbstractDelegate <NSOpenSavePanelDelegate>
{
  @private
    GormLanguageViewController *_vc;
}

// preferences
/**
 * Show the Preferences panel.
 */
- (IBAction) preferencesPanel: (id) sender;

// Cut/Paste operations
/**
 * Copy the current selection to the pasteboard.
 */
- (IBAction) copy: (id)sender;
/**
 * Cut the current selection to the pasteboard.
 */
- (IBAction) cut: (id)sender;
/**
 * Paste objects from the pasteboard into the active document.
 */
- (IBAction) paste: (id)sender;
/**
 * Delete the current selection.
 */
- (IBAction) delete: (id)sender;
/**
 * Select all items in the active context.
 */
- (IBAction) selectAllItems: (id)sender;

// palettes/inspectors.
/**
 * Show or focus the Inspectors window.
 */
- (IBAction) inspector: (id) sender;
/**
 * Show or toggle the Palettes window.
 */
- (IBAction) palettes: (id) sender;
/**
 * Loads a palette bundle from the specified file system path. The palette bundle contains UI components and resources that can be used in interface design.
 */
- (IBAction) loadPalette: (id) sender;

// sound & images
/**
 * Import a sound resource into the current document.
 */
- (IBAction) loadSound: (id) sender;
/**
 * Import an image resource into the current document.
 */
- (IBAction) loadImage: (id) sender;

// grouping/layout
/**
 * Group the current selection inside a new split view.
 */
- (IBAction) groupSelectionInSplitView: (id)sender;
/**
 * Group the current selection inside a new box.
 */
- (IBAction) groupSelectionInBox: (id)sender;
/**
 * Group the current selection inside a new scroll view.
 */
- (IBAction) groupSelectionInScrollView: (id)sender;
/**
 * Ungroup the selected container and promote its subviews.
 */
- (IBAction) ungroup: (id)sender;

// Classes actions
/**
 * Create a new subclass and register it within the document.
 */
- (IBAction) createSubclass: (id)sender;
/**
 * Load an existing class into the document’s class manager.
 */
- (IBAction) loadClass: (id)sender;
/**
 * Generate interface and implementation files for selected classes.
 */
- (IBAction) createClassFiles: (id)sender;
/**
 * Instantiate an object of a selected class and add it to the document.
 */
- (IBAction) instantiateClass: (id)sender;
/**
 * Adds an object to the collection.
 */
- (IBAction) addAttributeToClass: (id)sender;
/**
 * Remove the selected item (class, attribute, or resource).
 */
- (IBAction) remove: (id)sender;

// Palettes Actions...
/**
 * Show or focus the Inspectors window.
 */
- (IBAction) inspector: (id) sender;
/**
 * Show or toggle the Palettes window.
 */
- (IBAction) palettes: (id) sender;
/**
 * Loads a palette bundle from the specified file system path. The palette bundle contains UI components and resources that can be used in interface design.
 */
- (IBAction) loadPalette: (id) sender;

// Translation
/**
 * Import translations from an XLIFF file into the current document.
 */
- (IBAction) importXLIFFDocument: (id)sender;
/**
 * Export translatable strings to an XLIFF file for translation.
 */
- (IBAction) exportXLIFFDocument: (id)sender;
/**
 * Apply translations using the current language settings.
 */
- (IBAction) translate: (id)sender;
/**
 * Export localizable strings for the current document.
 */
- (IBAction) exportStrings: (id)sender;

// Print
/**
 * Print the current document or selection.
 */
- (IBAction) print: (id)sender;

@end

#endif // GormAppDelegate_H_INCLUDE
