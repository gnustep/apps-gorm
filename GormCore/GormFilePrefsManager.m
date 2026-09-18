/** <title>GormFilePrefsManager</title>

  <abstract>Stores per-document file information.</abstract>

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: July 2003.
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library;
   If not, write to the Free Software Foundation,
   31 Milk St # 960789 Boston, MA 02196 USA
*/ 

/* All rights reserved */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <InterfaceBuilder/InterfaceBuilder.h>

#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepGUI/GSGormLoading.h>

#include "GormVersion.h"
#include "GormFilePrefsManager.h"
#include "GormFunctions.h"
#include "GormDocument.h"

NSString *formatVersion(NSInteger version)
{
  NSInteger bit16 = 65536;
  NSInteger bit8  = 256;
  NSInteger maj   = 0; 
  NSInteger min   = 0;
  NSInteger pch   = 0;
  NSInteger v     = version;

  // pull the version fromt the number
  maj = (int)((float)v / (float)bit16);
  v -= (bit16 * maj);
  min = (int)((float)v / (float)bit8);
  v -= (bit8 * min);
  pch = v;
  
  return [NSString stringWithFormat: @"%ld.%ld.%ld / %ld",(long)maj,(long)min,(long)pch,(long)version];
}


@implementation GormFilePrefsManager

- (void) dealloc
{
  RELEASE(archiveTypeName);
  [super dealloc];
}

+ (int) currentVersion
{
  return appVersion(GORM_MAJOR_VERSION,
		    GORM_MINOR_VERSION,
		    GORM_SUBMINOR_VERSION);
}

- (void) awakeFromNib
{
  version = [GormFilePrefsManager currentVersion];
  [gormAppVersion setStringValue: formatVersion(version)];
  ASSIGN(archiveTypeName, [[archiveType selectedItem] title]);
}

- (void) selectArchiveType: (id)sender
{
  ASSIGN(archiveTypeName, [[sender selectedItem] title]);
  NSDebugLog(@"Set Archive type... %@",sender);
}

// Loading and saving the file.
- (BOOL) saveToFile: (NSString *)path
{
  return [[self data] writeToFile: path atomically: YES];
}

// Loading and saving the file.
- (NSData *) data
{
  // upon saving, update to the latest.
  version = [GormFilePrefsManager currentVersion];
  [gormAppVersion setStringValue: formatVersion(version)];

  // return the data...
  return  [NSArchiver archivedDataWithRootObject: self];
}

- (NSData *) nibDataWithOpenItems: (NSArray *)openItems
{
  NSMutableDictionary *dict = 
    [NSMutableDictionary dictionary];
  NSRect docLocation = 
    [[(GormDocument *)[(id<IB>)[NSApp delegate] activeDocument] window] frame];
  NSRect screenRect = [[NSScreen mainScreen] frame];
  NSString *stringRect = [NSString stringWithFormat: @"%d %d %d %d %d %d %d %d",
				   (int)docLocation.origin.x, (int)docLocation.origin.y, 
				   (int)docLocation.size.width, (int)docLocation.size.height,
				   (int)screenRect.origin.x, (int)screenRect.origin.y, 
				   (int)screenRect.size.width, (int)screenRect.size.height];

  // upon saving, update to the latest.
  version = [GormFilePrefsManager currentVersion];
  [gormAppVersion setStringValue: formatVersion(version)];
  
  [dict setObject: stringRect forKey: @"IBDocumentLocation"];
  [dict setObject: @"437.0" forKey: @"IBFramework Version"];
  [dict setObject: @"8I127" forKey: @"IBSystem Version"];
  [dict setObject: [NSNumber numberWithBool: YES] 
	forKey: @"IBUsesTextArchiving"]; // for now.
  [dict setObject: openItems forKey: @"IBOpenItems"];

  return [NSPropertyListSerialization dataFromPropertyList: dict 
				      format: NSPropertyListXMLFormat_v1_0
				      errorDescription: NULL];
}

- (BOOL) loadFromFile: (NSString *)path
{
  return [self loadFromData: [NSData dataWithContentsOfFile: path]];
}

- (BOOL) loadFromData: (NSData *)data
{
  BOOL result = YES;

  NS_DURING
    {
      GormFilePrefsManager *object = (GormFilePrefsManager *)
	[NSUnarchiver unarchiveObjectWithData: data];
      [gormAppVersion setStringValue: formatVersion([object version])];
      version = [object version];
      [archiveType selectItemWithTitle: [object archiveTypeName]];
      ASSIGN(archiveTypeName, [object archiveTypeName]);
      result = YES;
    }
  NS_HANDLER
    {
      NSLog(@"Problem loading info file: %@",[localException reason]);
      result = NO;
    }
  NS_ENDHANDLER;
  
  return result;
}

// encoding...
- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(int) at: &version];
  // Keep the positional data.info layout, but never persist an old save target.
  [coder encodeObject: @"Latest Version"];
  [coder encodeObject: archiveTypeName];
}

- (id) initWithCoder: (NSCoder *)coder
{
  if((self = [super init]) != nil)
    {
      [coder decodeValueOfObjCType: @encode(int) at: &version];
      // Discard the obsolete target version from existing documents.
      [coder decodeObject];
      archiveTypeName = RETAIN([coder decodeObject]);
    }

  return self;
}

// accessors
- (int) version
{
  return version;
}

- (NSString *)archiveTypeName
{
  return archiveTypeName;
}

- (void) setFileTypeName: (NSString *)ft
{
  [fileType setStringValue: ft];
}

- (NSString *) fileTypeName
{
  return [fileType stringValue];
}

@end
