/** <title>GormFilePrefsManager</title>

  <abstract>Sets the information about the .gorm file's version.  
  This allows a file to be saved as an older version of the .gorm 
  format so that older releases can still use .gorm files created 
  by people who have the latest GNUstep and Gorm version.</abstract>

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Gregory John Casamento
   Date: July 2003.
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library;
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSNibTemplates.h>
#include "GormFilePrefsManager.h"
#include "GormFunctions.h"
#include <Foundation/NSFileManager.h>
#include <Foundation/NSArchiver.h>
#include <GNUstepBase/GSObjCRuntime.h>

NSString *formatVersion(int version)
{
  int bit16 = 65536;
  int bit8  = 256;
  int maj   = 0; 
  int min   = 0;
  int pch   = 0;
  int v     = version;

  // pull the version fromt the number
  maj = (int)((float)v / (float)bit16);
  v -= (bit16 * maj);
  min = (int)((float)v / (float)bit8);
  v -= (bit8 * min);
  pch = v;
  
  return [NSString stringWithFormat: @"%d.%d.%d / %d",maj,min,pch,version];
}


@implementation GormFilePrefsManager

// initializers...
- (id) init
{
  if((self = [super init]) != nil)
    {
      NSBundle *bundle = [NSBundle mainBundle];
      NSString *path = [bundle pathForResource: @"VersionProfiles" ofType: @"plist"];
      versionProfiles = RETAIN([[NSString stringWithContentsOfFile: path] propertyList]);
    }
  return self;
}

- (void) dealloc
{
  NSDebugLog(@"Deallocating...");
  [iwindow performClose: self];
  RELEASE(iwindow);
  RELEASE(versionProfiles);
  // TEST_RELEASE(targetVersionName);
  // TEST_RELEASE(archiveTypeName);
  [super dealloc];
}

+ (int) currentVersion
{
  return appVersion(0,8,1); 
}

- (void) awakeFromNib
{
  version = [GormFilePrefsManager currentVersion];
  [gormAppVersion setStringValue: formatVersion(version)];
  ASSIGN(targetVersionName, [[targetVersion selectedItem] title]);
  ASSIGN(archiveTypeName, [[archiveType selectedItem] title]);
  [self selectTargetVersion: targetVersion];
}

// set class versions
- (void) setClassVersions
{
  NSEnumerator *en = [currentProfile keyEnumerator];
  id className = nil;
  
  NSDebugLog(@"set the class versions to the profile selected... %@",targetVersionName);
  while((className = [en nextObject]) != nil)
    {
      Class cls = NSClassFromString(className);
      NSDictionary *info = [currentProfile objectForKey: className];
      int v = [[info objectForKey: @"version"] intValue];
      NSDebugLog(@"Setting version %d for class %@",v,className);
      [cls setVersion: v];
    }
}

- (void) restoreClassVersions
{
  NSDictionary *latestVersion = [versionProfiles objectForKey: @"Latest Version"];
  NSEnumerator *en = [latestVersion keyEnumerator];
  id className = nil;
  
  // The "Latest Version" key must always exist.
  NSDebugLog(@"restore the class versions to the latest version...");
  while((className = [en nextObject]) != nil)
    {
      Class cls = NSClassFromString(className);
      NSDictionary *info = [latestVersion objectForKey: className];
      int v = [[info objectForKey: @"version"] intValue];
      NSDebugLog(@"Setting version %d for class %@",v,className);
      [cls setVersion: v];
    }
}

// class profile
- (void) loadProfile: (NSString *)profileName
{
  NSDebugLog(@"Loading profile %@",profileName);
  currentProfile = [versionProfiles objectForKey: targetVersionName];
}

// actions...
- (void) showIncompatibilities: (id)sender
{
  [itable reloadData];
  [iwindow orderFront: self];
  [iwindow center];
}

- (void) selectTargetVersion: (id)sender
{
  ASSIGN(targetVersionName, [[sender selectedItem] title]);
  [self loadProfile: targetVersionName];
  [itable reloadData];
}

- (void) selectArchiveType: (id)sender
{
  ASSIGN(archiveTypeName, [[sender selectedItem] title]);
  NSDebugLog(@"Set Archive type... %@",sender);
}

// Loading and saving the file.
- (BOOL) saveToFile: (NSString *)path
{
  return [NSArchiver archiveRootObject: self toFile: path];
}

- (BOOL) loadFromFile: (NSString *)path
{
  BOOL result = YES;
  NSFileManager *mgr = [NSFileManager defaultManager];

  // read/load the file...
  if([mgr isReadableFileAtPath: path])
    {
      NS_DURING
	{
	  id object = [NSUnarchiver unarchiveObjectWithFile: path];
	  [gormAppVersion setStringValue: formatVersion([object version])];
	  version = [object version];
	  [targetVersion selectItemWithTitle: [object targetVersionName]];
	  ASSIGN(targetVersionName,[object targetVersionName]);
	  [archiveType selectItemWithTitle: [object archiveTypeName]];
	  ASSIGN(archiveTypeName, [object archiveTypeName]);
	  [self selectTargetVersion: targetVersion];
	  result = YES;
	}
      NS_HANDLER
	{
	  NSLog(@"Problem loading info file: %@",[localException reason]);
	  result = NO;
	}
      NS_ENDHANDLER
    }

  return result;
}

// encoding...
- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(int) at: &version];
  [coder encodeObject: targetVersionName];
  [coder encodeObject: archiveTypeName];
}

- (id) initWithCoder: (NSCoder *)coder
{
  if((self = [super init]) != nil)
    {
      [coder decodeValueOfObjCType: @encode(int) at: &version];
      targetVersionName = [coder decodeObject];
      archiveTypeName = [coder decodeObject];
    }

  return self;
}

// accessors
- (int) version
{
  return version;
}

- (NSString *)targetVersionName
{
  return targetVersionName;
}

- (NSString *)archiveTypeName
{
  return archiveTypeName;
}

- (BOOL) isLatest
{
  return ([targetVersionName isEqual: @"Latest Version"]);
}

// Data Source
- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
  return [currentProfile count];
}

- (id) tableView: (NSTableView *)aTableView 
objectValueForTableColumn: (NSTableColumn *)aTableColumn 
	     row: (int)rowIndex
{
  id obj = nil;

  if([[aTableColumn identifier] isEqual: @"item"])
    {
      obj = [NSString stringWithFormat: @"#%d",rowIndex+1];
    }
  else if([[aTableColumn identifier] isEqual: @"description"])
    {
      NSArray *keys = [currentProfile allKeys];
      NSString *key = [keys objectAtIndex: rowIndex];
      NSDictionary *info = [currentProfile objectForKey: key];
      obj = [info objectForKey: @"comment"];
    }

  return obj;
}

- (void) tableView: (NSTableView *)aTableView 
    setObjectValue: (id)anObject 
    forTableColumn: (NSTableColumn *)aTableColumn
	       row: (int)rowIndex
{
}
@end

