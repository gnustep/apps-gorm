/* inspectors - Various inspectors for data elements

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Laurent Julliard <laurent@julliard-online.org>
   Date: Nov 2001
   
   This file is part of GNUstep.
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "../../GormPrivate.h"

/* This macro makes sure that the string contains a value, even if @"" */
#define VSTR(str) ({id _str = str; (_str) ? _str : @"";})


/*----------------------------------------------------------------------------
 * NSComboBox
 */

@implementation	NSComboBox (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormComboBoxAttributesInspector";
}

@end

@interface GormComboBoxAttributesInspector : IBInspector
{
  id alignmentMatrix;
  id backgroundColorWell;
  id itemBrowser;
  id itemField;
  id optionMatrix;
  id textColorWell;
  id visibleItemsForm;
}
@end

@implementation GormComboBoxAttributesInspector

- (void) _setValuesFromControl: control
{

  if (control == backgroundColorWell)
    {
      [object setBackgroundColor: [control color]];
    }
  else if (control == textColorWell)
    {
      [object setTextColor: [control color]];
    }
  else if (control == alignmentMatrix)
    {
      [object setAlignment: (NSTextAlignment)[[control selectedCell] tag]];
    }
  else if (control == optionMatrix)
    {
      BOOL flag;

      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES :NO;
      [object setEditable: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES :NO;
      [object setSelectable: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES :NO;
      [[object cell] setUsesDataSource: flag];
    }
  else if (control == visibleItemsForm)
    {
      [object setNumberOfVisibleItems: [[control cellAtIndex: 0] intValue]];
    }
  else if (control == itemBrowser)
    {
      // To be done
    }
  else if (control == itemField)
    {
      // To be done
    }
  
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    }

  [backgroundColorWell setColor: [anObject backgroundColor]];
  [textColorWell setColor: [anObject textColor]];
    
  [alignmentMatrix selectCellWithTag: [anObject alignment]];

  [optionMatrix deselectAllCells];
  if ([anObject isEditable])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject isSelectable])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject usesDataSource])
    [optionMatrix selectCellAtRow: 2 column: 0];

  [[visibleItemsForm cellAtIndex: 0] setIntValue: [anObject numberOfVisibleItems]];

}

- (void) dealloc
{
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormComboBoxInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormComboBoxInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end


/*----------------------------------------------------------------------------
 * NSImageView
 */

@implementation	NSImageView (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormImageViewAttributesInspector";
}

@end

@interface GormImageViewAttributesInspector : IBInspector
{
  id iconField;
  id borderMatrix;
  id alignmentMatrix;
  id scalingMatrix;
  id editableSwitch;
}
@end

@implementation GormImageViewAttributesInspector

- (void) _setValuesFromControl: control
{
  if (control == iconField)
    {
      [object setImage: [NSImage imageNamed: VSTR([control stringValue])] ];
    }
  else  if (control == borderMatrix)
    {
      [object setImageFrameStyle: [[control selectedCell] tag]];
    }
  else if (control == alignmentMatrix)
    {
      [object setImageAlignment: [[control selectedCell] tag]];
    }
  else if (control == scalingMatrix)
    {
      [object setImageScaling: [[control selectedCell] tag]];
    }
  else if (control == editableSwitch)
    {
      [object setEditable: ([control state] == NSOnState)];
    }
  
}

- (void) _getValuesFromObject: anObject
{
  if (anObject != object)
    {
      return;
    }

  // If this is still the original image as in the Palette then clean it
  if ( [ [[anObject image] name] isEqualToString: @"Sunday_seurat.tiff"] )
        [anObject setImage: nil];
 
  [iconField setStringValue: VSTR([[anObject image] name])];
  [borderMatrix selectCellWithTag: [anObject imageFrameStyle]];
  [alignmentMatrix selectCellWithTag: [anObject imageAlignment]];
  [scalingMatrix selectCellWithTag: [anObject imageScaling]];
  [editableSwitch setState: [anObject isEditable]];
}

- (void) dealloc
{
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormImageViewInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormImageViewInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end

/*----------------------------------------------------------------------------
 * NSTextView (possibly embedded in a Scroll view)
 */

@implementation	NSTextView (IBInspectorClassNames)

- (NSString*) inspectorClassName
{
  return @"GormTextViewAttributesInspector";
}

@end

@interface GormTextViewAttributesInspector : IBInspector
{
  id  backgroundColorWell;
  id  textColorWell;
  id  borderMatrix;
  id  optionMatrix;
}
@end

@implementation GormTextViewAttributesInspector

- (void) _setValuesFromControl: control
{
  BOOL flag;
  BOOL isScrollView;
  id scrollView;

  scrollView = [[object superview] superview];
  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  if (control == backgroundColorWell)
    {
      [object setBackgroundColor: [control color]];
    }
  else if (control == textColorWell)
    {
      [object setTextColor: [control color]];
    }
  else if ( (control == borderMatrix) && isScrollView)
    {
      [scrollView setBorderType: [[control selectedCell] tag]];
    }
  else if (control == optionMatrix)
    {
      flag = ([[control cellAtRow: 0 column: 0] state] == NSOnState) ? YES : NO;
      [object setSelectable: flag];
      flag = ([[control cellAtRow: 1 column: 0] state] == NSOnState) ? YES : NO;
      [object setEditable: flag];
      flag = ([[control cellAtRow: 2 column: 0] state] == NSOnState) ? YES : NO;
      [object setRichText: flag];
      flag = ([[control cellAtRow: 3 column: 0] state] == NSOnState) ? YES : NO;
      [object setImportsGraphics: flag];
    } 

}

- (void) _getValuesFromObject: anObject
{
  BOOL isScrollView;
  id scrollView;

  if (anObject != object)
    {
      return;
    }

  scrollView = [[anObject superview] superview];
  isScrollView = [ scrollView isKindOfClass: [NSScrollView class]];

  [backgroundColorWell setColor: [anObject backgroundColor]];
  [textColorWell setColor: [anObject textColor]];

  if (isScrollView) {
    [borderMatrix selectCellWithTag: [scrollView borderType]];
  }
  
  if ([anObject isSelectable])
    [optionMatrix selectCellAtRow: 0 column: 0];
  if ([anObject isEditable])
    [optionMatrix selectCellAtRow: 1 column: 0];
  if ([anObject isRichText])
    [optionMatrix selectCellAtRow: 2 column: 0];
  if ([anObject importsGraphics])
    [optionMatrix selectCellAtRow: 3 column: 0];

}

- (void) dealloc
{
  RELEASE(window);
  [super dealloc];
}

- (id) init
{
  if ([super init] == nil)
    {
      return nil;
    }
  if ([NSBundle loadNibNamed: @"GormTextViewInspector" owner: self] == NO)
    {
      NSLog(@"Could not gorm GormTextViewInspector");
      return nil;
    }

  return self;
}

- (void) ok: (id)sender
{
  [self _setValuesFromControl: sender];
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  [self _getValuesFromObject: anObject];
}

@end
