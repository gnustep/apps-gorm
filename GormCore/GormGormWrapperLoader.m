/* GormDocumentController.m
 *
 * This class is a subclass of the NSDocumentController
 *
 * Copyright (C) 2006 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:        2006
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
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

#include <GormCore/GormWrapperLoader.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GormCore/GormPalettesManager.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormImage.h>
#include <GormCore/GormSound.h>
#include <GormCore/GormPrivate.h>
#include <GormCore/NSView+GormExtensions.h>
#include <GormCore/GormFunctions.h>

@interface GormGormWrapperLoader : GormWrapperLoader
@end

@implementation GormGormWrapperLoader
+ (NSString *) type
{
  return @"GSGormFileType";
}

/** 
 * The sole purpose of this method is to clean up .gorm files from older
 * versions of Gorm which might have some dangling references.   This method
 * may be added to as time goes on to make sure that it's possible 
 * to repair old .gorm files.
 */
- (void) _repairFile
{
  NSEnumerator *en = [[[document nameTable] allKeys] objectEnumerator];
  NSString *key = nil;
  
  NSRunAlertPanel(_(@"Warning"), 
		  _(@"You are running with 'GormRepairFileOnLoad' set to YES."),
		  nil, nil, nil);

  while((key = [en nextObject]) != nil)
  {
    id obj = [[document nameTable] objectForKey: key];
    if([obj isKindOfClass: [NSMenu class]] && ![key isEqual: @"NSMenu"])
      {
	id sm = [obj supermenu];
	if(sm == nil)
	  {
	    NSArray *menus = findAll(obj);
	    NSLog(@"Found and removed a dangling menu %@, %@.",obj,[document nameForObject: obj]);
	    [document detachObjects: menus];
	    [document detachObject: obj];
	    
	    // Since the menu is a top level object, it is not retained by
	    // anything else.  When it was unarchived it was autoreleased, and
	    // the detach also does a release.  Unfortunately, this causes a
	    // crash, so this extra retain is only here to stave off the 
	    // release, so the autorelease can release the menu when it should.
	    RETAIN(obj); // extra retain to stave off autorelease...
	  }
      }

    if([obj isKindOfClass: [NSMenuItem class]])
      {
	id m = [obj menu];
	if(m == nil)
	  {
	    id sm = [obj submenu];

	    NSLog(@"Found and removed a dangling menu item %@, %@.",obj,[document nameForObject: obj]);
	    [document detachObject: obj];

	    // if there are any submenus, detach those as well.
	    if(sm != nil)
	      {
		NSArray *menus = findAll(sm);
		[document detachObjects: menus];
	      }
	  }
      }

    /**
     * If it's a view and it does't have a window *AND* it's not a top level object
     * then it's not a standalone view, it's an orphan.   Delete it.
     */
    if([obj isKindOfClass: [NSView class]])
      {
	if([obj window] == nil && 
	   [[document topLevelObjects] containsObject: obj] == NO &&
	   [obj hasSuperviewKindOfClass: [NSTabView class]] == NO)
	  {
	    NSLog(@"Found and removed an orphan view %@, %@",obj,[document nameForObject: obj]);
	    [document detachObject: obj];
	  }
      }
  }
}

/**
 * Private method.  Determines if the document contains an instance of a given
 * class or one of it's subclasses.
 */
- (BOOL) _containsKindOfClass: (Class)cls
{
  NSEnumerator *en = [[document nameTable] objectEnumerator];
  id obj = nil;
  while((obj = [en nextObject]) != nil)
    {
      if([obj isKindOfClass: cls])
	{
	  return YES;
	}
    }
  return NO;
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *) doc
{
  NS_DURING
    {
      NSMutableDictionary	*cc = nil;
      NSData		        *data = nil;
      NSData                    *classes = nil;
      NSUnarchiver		*u = nil;
      NSEnumerator		*enumerator = nil;
      id <IBConnectors>	         con = nil;
      NSString                  *ownerClass, *key = nil;
      BOOL                       repairFile = [[NSUserDefaults standardUserDefaults] boolForKey: @"GormRepairFileOnLoad"];
      GormPalettesManager       *palettesManager = [(id<Gorm>)NSApp palettesManager];
      NSDictionary              *substituteClasses = [palettesManager substituteClasses];
      NSEnumerator              *en = [substituteClasses keyEnumerator];
      NSString                  *subClassName = nil;
      unsigned int           	version = NSNotFound;
      NSDictionary              *fileWrappers = nil;
      
      if ([super loadFileWrapper: wrapper withDocument: doc])
	{
	  GormClassManager *classManager = [document classManager];

	  key = nil;
	  fileWrappers = [wrapper fileWrappers];

	  enumerator = [fileWrappers keyEnumerator];
	  while((key = [enumerator nextObject]) != nil)
	    {
	      NSFileWrapper *fw = [fileWrappers objectForKey: key];
	      if([fw isRegularFile])
		{
		  NSData *fileData = [fw regularFileContents];
		  if([key isEqual: @"objects.gorm"])
		    {
		      data = fileData;
		    }
		  else if([key isEqual: @"data.info"])
		    {
		      [document setInfoData: fileData];
		    }
		  else if([key isEqual: @"data.classes"])
		    {
		      classes = fileData;
		      
		      // load the custom classes...
		      if (![classManager loadCustomClassesWithData: classes]) 
			{
			  NSRunAlertPanel(_(@"Problem Loading"), 
					  _(@"Could not open the associated classes file.\n"
					    @"You won't be able to edit connections on custom classes"), 
					  _(@"OK"), nil, nil);
			}
		    }
		}
	    }
	  
	  // check the data...
	  if (data == nil || [document infoData] == nil || classes == nil)
	    {
	      return NO;
	    }
	  
	  /*
	   * Create an unarchiver, and use it to unarchive the gorm file while
	   * handling class replacement so that standard objects understood
	   * by the gui library are converted to their Gorm internal equivalents.
	   */
	  u = [[NSUnarchiver alloc] initForReadingWithData: data];
	  
	  /*
	   * Special internal classes
	   */ 
	  [u decodeClassName: @"GSNibItem" 
	     asClassName: @"GormObjectProxy"];
	  [u decodeClassName: @"GSCustomView" 
	     asClassName: @"GormCustomView"];
	  
	  /*
	   * Substitute any classes specified by the palettes...
	   */
	  while((subClassName = [en nextObject]) != nil)
	    {
	      NSString *realClassName = [substituteClasses objectForKey: subClassName];
	      [u decodeClassName: realClassName 
		 asClassName: subClassName];
	    }
	  
	  // turn off custom classes.
	  [GSClassSwapper setIsInInterfaceBuilder: YES]; 
	  GSNibContainer *container = [u decodeObject];
	  if (container == nil || [container isKindOfClass: [GSNibContainer class]] == NO)
	    {
	      return NO;
	    }
	  // turn on custom classes.
	  [GSClassSwapper setIsInInterfaceBuilder: NO]; 
	  
	  /*
	   * Retrieve the custom class data and refresh the classes view...
	   */
	  NSMutableDictionary *nt = [container nameTable];
	  
	  cc = [nt objectForKey: @"GSCustomClassMap"];
	  if (cc == nil)
	    {
	      cc = [NSMutableDictionary dictionary]; // create an empty one.
	      [nt setObject: cc forKey: @"GSCustomClassMap"];
	    }
	  [classManager setCustomClassMap: cc];
	  [nt removeObjectForKey: @"GSCustomClassMap"];
	  
	  //
	  // Get all of the visible objects...
	  //
	  NSArray *visible = [nt objectForKey: @"NSVisible"];
	  id visObj = nil;
	  enumerator = [visible objectEnumerator];
	  while((visObj = [enumerator nextObject]) != nil)
	    {
	      [document setObject: visObj isVisibleAtLaunch: YES];
	    }
	  [nt removeObjectForKey: @"NSVisible"];
	  
	  //
	  // Get all of the deferred objects...
	  //
	  NSArray *deferred = [nt objectForKey: @"NSDeferred"];
	  id defObj = nil;
	  enumerator = [deferred objectEnumerator];
	  while((defObj = [enumerator nextObject]) != nil)
	    {
	      [document setObject: defObj isDeferred: YES];
	    }
	  [nt removeObjectForKey: @"NSDeferred"];
	  
	  /*
	   * In the newly loaded nib container, we change all the connectors
	   * to hold the objects rather than their names (using our own dummy
	   * object as the 'NSOwner'.
	   */
	  ownerClass = [nt objectForKey: @"NSOwner"];
	  if (ownerClass)
	    {
	      [[document filesOwner] setClassName: ownerClass];
	    }
	  [[container nameTable] removeObjectForKey: @"NSOwner"];
	  [[container nameTable] removeObjectForKey: @"NSFirst"];
	  
	  //
	  // Add entries...
	  //
	  [[document nameTable] addEntriesFromDictionary: nt];
	  
	  //
	  // Add top level items...
	  //
	  NSArray *objs = [[container topLevelObjects] allObjects];
	  [[document topLevelObjects] addObjectsFromArray: objs];
					
	  
	  /* Iterate over the contents of nameTable and create the connections */
	  nt = [document nameTable];
	  enumerator = [[container connections] objectEnumerator];
	  while ((con = [enumerator nextObject]) != nil)
	    {
	      NSString  *name;
	      id        obj;
	      
	      name = (NSString*)[con source];
	      obj = [nt objectForKey: name];
	      [con setSource: obj];
	      name = (NSString*)[con destination];
	      obj = [nt objectForKey: name];
	      [con setDestination: obj];
	    }
	  
	  /*
	   * If the GSNibContainer version is 0, we need to add the top level objects
	   * to the list so that they can be properly processed.
	   */
	  if([u versionForClassName: NSStringFromClass([GSNibContainer class])] == 0)
	    {
	      id obj;
	      NSEnumerator *en = [nt objectEnumerator];
	      
	      // get all of the GSNibItem subclasses which could be top level objects
	      while((obj = [en nextObject]) != nil)
		{
		  if([obj isKindOfClass: [GSNibItem class]] &&
		     [obj isKindOfClass: [GSCustomView class]] == NO)
		    {
		      [[container topLevelObjects] addObject: obj];
		    }
		}
	      [document setOlderArchive: YES];
	    }
	  
	  /*
	   * If the GSWindowTemplate version is 0, we need to let Gorm know that this is
	   * an older archive.  Also, if the window template is not in the archive we know
	   * it was made by an older version of Gorm.
	   */
	  version = [u versionForClassName: NSStringFromClass([GSWindowTemplate class])];
	  if(version == NSNotFound && [self _containsKindOfClass: [NSWindow class]])
	    {
	      [document setOlderArchive: YES];
	    }

	  /*
	   * repair the .gorm file, if needed.
	   */
	  if(repairFile)
	    {
	      [self _repairFile];
	    }
	  
	  /* 
	   * Rebuild the mapping from object to name for the nameTable... 
	   */
	  [document rebuildObjToNameMapping];
	  
	  NSDebugLog(@"nameTable = %@",[container nameTable]);
	  
	  // awaken all elements after the load is completed.
	  enumerator = [nt keyEnumerator];
	  while ((key = [enumerator nextObject]) != nil)
	    {
	      id o = [nt objectForKey: key];
	      if ([o respondsToSelector: @selector(awakeFromDocument:)])
		{
		  [o awakeFromDocument: document];
		}
	    }
	  
	  // document opened...
	  [document setDocumentOpen: YES];
	  
	  // release the unarchiver..
	  RELEASE(u);
	}
      else
	{
	  return NO;
	}
    }
  NS_HANDLER
    {
      NSRunAlertPanel(_(@"Problem Loading"), 
		      [NSString stringWithFormat: @"Failed to load file.  Exception: %@",[localException reason]], 
		      _(@"OK"), nil, nil);
      return NO; 
    }
  NS_ENDHANDLER;

  // if we made it here, then it was a success....
  return YES;
}
@end
