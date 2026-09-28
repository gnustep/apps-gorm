/* GormWrapperBuilder
 *
 * Copyright (C) 2006-2013 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg.casamento@gmail.com>
 * Date:        2006
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>

#import "GormXIBArchiver.h"

@interface GormXibWrapperBuilder : GormWrapperBuilder
@end

@implementation GormXibWrapperBuilder

+ (NSString *) fileType
{
  return @"GSXibFileType";
}

- (NSFileWrapper *) buildFileWrapperWithDocument: (GormDocument *)doc
{
  NSString *error = nil;
  GormPalettesManager *palettesManager =
    [(id<GormAppDelegate>)[NSApp delegate] palettesManager];
  NSData *data = [GormXIBArchiver dataWithGormDocument: doc
                                      classNameMappings:
                                        [palettesManager substituteClasses]
                                      errorDescription: &error];
  NSFileWrapper *fileWrapper;

  if (data == nil)
    {
      NSLog(@"Could not archive XIB data: %@", error);
      [error release];
      return nil;
    }

  fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: data];

  return fileWrapper;
}

@end
