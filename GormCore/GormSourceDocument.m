/* GormSourceDocument.m
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

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>

#import <AppKit/NSMenu.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSView.h>

#import "GormDocument.h"
#import "GormDocumentController.h"
#import "GormFilePrefsManager.h"
#import "GormProtocol.h"
#import "GormPrivate.h"
#import "GormSourceDocument.h"

@implementation GormSourceDocument

/**
 * Returns an autoreleast GormSourceDocument object;
 */
+ (instancetype) sourceWithGormDocument: (GormDocument *)doc
{
  return AUTORELEASE([[self alloc] initWithGormDocument: doc]);
}

/**
 * Initialize with GormDocument object to parse the XML from or into.
 */
- (instancetype) initWithGormDocument: (GormDocument *)doc
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_gormDocument, doc);

      _sourceString = [[NSMutableString alloc] init];
      _headerString = [[NSMutableString alloc] init];
    }
  return self;
}

- (void) dealloc
{
  DESTROY(_gormDocument);
  DESTROY(_sourceString);
  DESTROY(_headerString);
  
  [super dealloc];
}

- (void) _collectObjectsFromObject: (id)obj
{
  NSString *name = [_gormDocument nameForObject: obj];

  if (name != nil)
    {
      // collect data...
    }
}

- (void) _buildSourceDocument
{
  NSEnumerator *en = [[_gormDocument topLevelObjects] objectEnumerator];
  id o = nil;

  [_gormDocument deactivateEditors];
  while ((o = [en nextObject]) != nil)
    {
      [self _collectObjectsFromObject: o];
    }
  [_gormDocument reactivateEditors];
}

/**
 * Exports Source file for CAT.  This method starts the process and calls
 * another method that recurses through the objects in the model and pulls
 * any translatable elements.
 */
- (BOOL) exportSourceDocumentWithName: (NSString *)name
{
  BOOL result = NO;
  
  [self _buildSourceDocument];
  
  result = [_sourceString writeToFile: name atomically: YES];
  if (result == YES)
    {
      result = [_headerString writeToFile: name atomically: YES];      
    }
  
  return result;
}

@end
