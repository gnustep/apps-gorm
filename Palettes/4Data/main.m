/* main.m

   Copyright (C) 1999 Free Software Foundation, Inc.

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
#include "../../Gorm.h"
#include "../../GormPrivate.h"


/* -----------------------------------------------------------
 * Some additions to the NSNumberFormatter Class specific to Gorm
 * -----------------------------------------------------------*/
NSArray *predefinedNumberFormats;
int defaultNumberFormatIndex = 0;

@implementation NSNumberFormatter (GormAdditions)

+ (void) initialize
{
  predefinedNumberFormats = [NSArray arrayWithObjects:
       [NSArray arrayWithObjects: @"$#,##0.00;0.00;-$#,##0.00",@"9999.99",@"-9999.99",nil],
       [NSArray arrayWithObjects: @"$#,##0.00;0.00;[Red]($#,##0.00)",@"9999.99",@"-9999.99",nil],
       [NSArray arrayWithObjects: @"0.00;0.00;-0.00",@"9999.99",@"-9999.99",nil],
       [NSArray arrayWithObjects: @"0;0;-0",@"100",@"-100",nil],
       [NSArray arrayWithObjects: @"00000;00000;-00000",@"100",@"-100",nil],
       [NSArray arrayWithObjects: @"0%;0%;-0%",@"100",@"-100",nil],
       [NSArray arrayWithObjects: @"0.00%;0.00%;-0.00%",@"99.99",@"-99.99",nil],
       nil];
}


+ (int) formatCount
{
  return [predefinedNumberFormats count];
}

+ (NSString *) formatAtIndex: (int)i
{
  return [[predefinedNumberFormats objectAtIndex:i] objectAtIndex:0];
}

+ (NSString *) positiveFormatAtIndex: (int)i
{
  NSString *fmt =[[predefinedNumberFormats objectAtIndex:i] objectAtIndex:0];
  
  return [ [fmt componentsSeparatedByString:@";"] objectAtIndex:0];
}

+ (NSString *) zeroFormatAtIndex: (int)i
{
  NSString *fmt =[[predefinedNumberFormats objectAtIndex:i] objectAtIndex:0];
  
  return [ [fmt componentsSeparatedByString:@";"] objectAtIndex:1];
}

+ (NSString *) negativeFormatAtIndex: (int)i
{
  NSString *fmt =[[predefinedNumberFormats objectAtIndex:i] objectAtIndex:0];
  
  return [ [fmt componentsSeparatedByString:@";"] objectAtIndex:2];
}

+ (NSDecimalNumber *) positiveValueAtIndex: (int)i
{
   return [NSDecimalNumber decimalNumberWithString:
                [[predefinedNumberFormats objectAtIndex:i] objectAtIndex:1] ];
}

+ (NSDecimalNumber *) negativeValueAtIndex: (int)i
{
   return [NSDecimalNumber decimalNumberWithString:
                [[predefinedNumberFormats objectAtIndex:i] objectAtIndex:2] ];
}

+ (int) indexOfFormat: (NSString *) format
{
  int i;
  NSString *fmt;
  int count = [predefinedNumberFormats count];

  for (i=0;i<count;i++)
    {
      fmt = [[predefinedNumberFormats objectAtIndex:i] objectAtIndex:0];
      if ([fmt isEqualToString: format])
        {
          return i;
        }
    }
  
  return NSNotFound;
}

+ (NSString *) defaultFormat
{
  return [NSNumberFormatter formatAtIndex:defaultNumberFormatIndex];
}


+ (id) defaultFormatValue
{
  return [NSNumberFormatter positiveValueAtIndex:defaultNumberFormatIndex];
}

- (NSString *) zeroFormat
{
  NSArray *fmts = [[self format] componentsSeparatedByString:@";"];

  if ([fmts count] != 3)
    return @"";
  else
    return [fmts objectAtIndex:1];
}

@end

/* -----------------------------------------------------------
 * Some additions to the NSDateFormatter Class specific to Gorm
 * -----------------------------------------------------------*/
NSArray *predefinedDateFormats;
int defaultDateFormatIndex = 3;

@implementation NSDateFormatter (GormAdditions)

+ (void) initialize
{
  predefinedDateFormats = [NSArray arrayWithObjects: @"%c",@"%A, %B %e, %Y",
                         @"%B %e, %Y", @"%e %B %Y", @"%m/%d/%y",
                         @"%b %d, %Y", @"%B %H", @"%d %b %Y",
                         @"%H:%M:%S", @"%I:%M",nil];
}

+ (int) formatCount
{
  return [predefinedDateFormats count];
}

+ (NSString *) formatAtIndex: (int)index
{
  return [predefinedDateFormats objectAtIndex: index];
}

+ (int) indexOfFormat: (NSString *) format
{
  return [predefinedDateFormats indexOfObject: format];
}


+ (NSString *) defaultFormat
{
  return [NSDateFormatter formatAtIndex:defaultDateFormatIndex]; 
}

+ (id) defaultFormatValue
{
  return [NSCalendarDate calendarDate];
}

@end

/* -----------------------------------------------------------
 * The Data Palette (Scroll Text View, formatters, Combo box,...)
 *
 * -----------------------------------------------------------*/
@interface DataPalette: IBPalette
{
}
@end

@implementation DataPalette

- (void) finishInstantiate
{ 

  NSView	*contents;
  NSTextView	*tv;
  NSSize        contentSize;
  id		v;
  NSNumberFormatter *nf;
  NSDateFormatter *df;
  NSRect rect;
  

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 272, 192)
				       styleMask: NSBorderlessWindowMask 
					 backing: NSBackingStoreRetained
					   defer: NO];
  contents = [window contentView];

/*******************/
/* First Column... */
/*******************/


  // NSScrollView
  v = [[NSScrollView alloc] initWithFrame: NSMakeRect(20, 22, 113,148)];
  [v setHasVerticalScroller: YES];
  [v setHasHorizontalScroller: NO];
  [v setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
  [[v contentView] setAutoresizingMask: NSViewHeightSizable 
			    | NSViewWidthSizable];
  [[v contentView] setAutoresizesSubviews:YES];

  rect = [[v contentView] frame];

  tv = [[NSTextView alloc] initWithFrame: rect];
  [tv setMinSize: NSMakeSize(0.0, 0.0)];
  [tv setMaxSize: NSMakeSize(1.0E7,1.0E7)];
  [tv setHorizontallyResizable: NO];
  [tv setVerticallyResizable: YES];
  [tv setAutoresizingMask: NSViewWidthSizable];
  [tv setSelectable: YES];
  [tv setEditable: YES];
  [tv setRichText: YES];
  [tv setImportsGraphics: YES];

  [[tv textContainer] setContainerSize:NSMakeSize(rect.size.width,
						  1e7)];
  [[tv textContainer] setWidthTracksTextView:YES];
  
  [v setDocumentView:tv];
  [contents addSubview: v];
  RELEASE(v);
  RELEASE(tv);

/********************/
/* Second Column... */
/********************/


  // NSImageView
  v = [[NSImageView alloc] initWithFrame: NSMakeRect(143, 98, 96, 72)];
  [v setImageFrameStyle: NSImageFramePhoto]; //FramePhoto not implemented
  [v setImageScaling: NSScaleProportionally];
  [v setImageAlignment: NSImageAlignCenter];
  [v setImage: [NSImage imageNamed: @"Sunday_seurat.tiff"]];
  [contents addSubview: v];
  RELEASE(v);

  /* Number and Date formatters. Note that they have a specific drag type.
     * All other palette objects are views and use the default  IBViewPboardType
     * drag type
     */
  v = [[NSImageView alloc] initWithFrame: NSMakeRect(143, 48, 43, 43)];
  [v setImageFrameStyle: NSImageFramePhoto];
  [v setImageScaling: NSScaleProportionally];
  [v setImageAlignment: NSImageAlignCenter];
  [v setImage: [NSImage imageNamed: @"number_formatter.tiff"]];
  [contents addSubview: v];

  nf = [[NSNumberFormatter alloc] init];
  [nf setFormat: [NSNumberFormatter defaultFormat]];

  [self associateObject: nf type: IBFormatterPboardType with: v];
  RELEASE(v);

  v = [[NSImageView alloc] initWithFrame: NSMakeRect(196, 48, 43, 43)];
  [v setImageFrameStyle: NSImageFramePhoto];
  [v setImageScaling: NSScaleProportionally];
  [v setImageAlignment: NSImageAlignCenter];
  [v setImage: [NSImage imageNamed: @"date_formatter.tiff"]];
  [contents addSubview: v];

  df = [[NSDateFormatter alloc]
           initWithDateFormat: [NSDateFormatter defaultFormat]
         allowNaturalLanguage: NO];

  [self associateObject: df type: IBFormatterPboardType with: v];
  RELEASE(v);
  
  // NSComboBox
  v = [[NSComboBox alloc] initWithFrame: NSMakeRect(143, 22, 96, 21)];
  [contents addSubview: v];
  RELEASE(v);
  
}

@end



