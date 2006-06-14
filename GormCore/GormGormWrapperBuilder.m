/* GormWrapperBuilder
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSNibTemplates.h>
#include <GormCore/GormWrapperBuilder.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormFilePrefsManager.h>
#include <GormCore/GormDocument.h>
#include <GormCore/GormProtocol.h>
#include <GormCore/GormPalettesManager.h>

@interface GSNibContainer (BuilderAdditions)
- (id) initWithDocument: (GormDocument *)document;
- (void) prepareConnectionsWithDocument: (GormDocument *)document;
- (void) resetConnectionsWithDocument: (GormDocument *)document;
@end;

@implementation GSNibContainer (BuilderAdditions)
- (id) initWithDocument: (GormDocument *)document
{
  if((self = [self init]) != nil)
    {
      NSMutableArray        *visible = [nameTable objectForKey: @"NSVisible"];
      NSMutableArray        *deferred = [nameTable objectForKey: @"NSDeferred"];
      NSDictionary          *customClasses = [[document classManager] customClassMap];

      // Create the container for the .gorm file...
      [nameTable addEntriesFromDictionary: [document nameTable]];
      [topLevelObjects addObjectsFromArray: [[document topLevelObjects] allObjects]];
      [connections addObjectsFromArray: [document connections]];
      [visible addObjectsFromArray: [[document visibleWindows] allObjects]];
      [deferred addObjectsFromArray: [[document deferredWindows] allObjects]];

      // add the custom class mapping...
      [nameTable setObject: customClasses forKey: @"GSCustomClassMap"];
    }
  return self;
}

- (void) prepareConnectionsWithDocument: (GormDocument *)document
{
  NSEnumerator *enumerator = [connections objectEnumerator];
  id conn = nil;
  while ((conn = [enumerator nextObject]) != nil)
    {
      NSString *name = nil;
      id obj = nil;

      obj = [conn source];
      name = [document nameForObject: obj];
      [conn setSource: name];
      obj = [conn destination];
      name = [document nameForObject: obj];
      [conn setDestination: name];
    }
}

- (void) resetConnectionsWithDocument: (GormDocument *)document
{
  NSEnumerator *enumerator = [connections objectEnumerator];
  id conn = nil;
  while ((conn = [enumerator nextObject]) != nil)
    {
      NSString	*name = nil;
      id obj = nil;

      name = (NSString*)[conn source];
      obj = [document objectForName: name];
      [conn setSource: obj];
      name = (NSString*)[conn destination];
      obj = [document objectForName: name];
      [conn setDestination: obj];
    }
}
@end

@interface GormGormWrapperBuilder : GormWrapperBuilder
@end

@implementation GormGormWrapperBuilder
+ (NSString *) type
{
  return @"GSGormFileType";
}

/**
 * Private method which iterates through the list of custom classes and instructs 
 * the archiver to replace the actual object with template during the archiving 
 * process.
 */
- (void) _replaceObjectsWithTemplates: (NSArchiver *)archiver
{
  NSEnumerator *en = [[document nameTable] keyEnumerator];
  GormClassManager *classManager = [document classManager];
  GormFilePrefsManager *filePrefsManager = [document filePrefsManager];
  id key = nil;

  // loop through all custom objects and windows
  while((key = [en nextObject]) != nil)
    {
      id customClass = [classManager customClassForName: key];
      id object = [document objectForName: key];
      id template = nil;
      if(customClass != nil)
	{
	  NSString *superClass = [classManager nonCustomSuperClassOf: customClass];
	  template = [GSTemplateFactory templateForObject: object
					withClassName: customClass 
					withSuperClassName: superClass];
	}
      else if([object isKindOfClass: [NSWindow class]] 
	      && [filePrefsManager versionOfClass: @"GSWindowTemplate"] > 0)
	{
	  template = [GSTemplateFactory templateForObject: object
					withClassName: [object className]
					withSuperClassName: [object className]]; 
	  
	}

      // if the template has been created, replace the object with it.
      if(template != nil)
	{
	  // if the object is deferrable, then set the flag appropriately.
	  if([template respondsToSelector: @selector(setDeferFlag:)])
	    {
	      [template setDeferFlag: [document objectIsDeferred: object]];
	    }
	  
	  //  if the object can accept autoposition information
	  if([object respondsToSelector: @selector(autoPositionMask)])
	    {
	      int mask = [object autoPositionMask];
	      if([template respondsToSelector: @selector(setAutoPositionMask:)])
		{
		  [template setAutoPositionMask: mask];
		}
	    }

	  // replace the object with the template.
	  [archiver replaceObject: object withObject: template];
	}
    }
}

- (NSMutableDictionary *)buildFileWrapperDictionaryWithDocument: (GormDocument *)doc
{
  NSArchiver            *archiver = nil;
  NSMutableData         *archiverData = nil;
  NSString              *gormPath = @"objects.gorm";
  NSString              *classesPath = @"data.classes";
  NSString              *infoPath = @"data.info";
  GormPalettesManager   *palettesManager = [(id<Gorm>)NSApp palettesManager];
  NSDictionary          *substituteClasses = [palettesManager substituteClasses];
  NSEnumerator          *en = [substituteClasses keyEnumerator];
  NSString              *subClassName = nil;
  NSFileWrapper         *fileWrapper = nil;
  NSMutableDictionary   *fileWrappers = [super buildFileWrapperDictionaryWithDocument: doc];

  if(fileWrappers)
    {
      GormClassManager *classManager = [document classManager];
      GormFilePrefsManager *filePrefsManager = [document filePrefsManager];
      GSNibContainer *container = nil;

      [document beginArchiving];
      container = [[GSNibContainer alloc] initWithDocument: document];

      /*
       * Set up archiving...
       */
      archiverData = [NSMutableData dataWithCapacity: 0];
      archiver = [[NSArchiver alloc] initForWritingWithMutableData: archiverData];
      
      /* 
       * Special gorm classes to their archive equivalents. 
       */
      [archiver encodeClassName: @"GormObjectProxy" 
		intoClassName: @"GSNibItem"];
      [archiver encodeClassName: @"GormCustomView"
		intoClassName: @"GSCustomView"];
      
      
      while((subClassName = [en nextObject]) != nil)
	{
	  NSString *realClassName = [substituteClasses objectForKey: subClassName];
	  [archiver encodeClassName: subClassName
		    intoClassName: realClassName];
	}
      
      /*
       * Initialize templates 
       */
      [self _replaceObjectsWithTemplates: archiver];
      // [container prepareConnectionsWithDocument: document];
      [archiver encodeRootObject: container];
      // [container resetConnectionsWithDocument: document];
      RELEASE(archiver); // We're done with the archiver here..
      
      /* 
       * Add the gorm, info and classes files to the package.
       */
      fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: archiverData];
      [fileWrappers setObject: fileWrapper forKey: gormPath];
      RELEASE(fileWrapper);
      fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: [classManager data]];
      [fileWrappers setObject: fileWrapper forKey: classesPath];
      RELEASE(fileWrapper);
      fileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: [filePrefsManager data]];
      [fileWrappers setObject: fileWrapper forKey: infoPath];
      RELEASE(fileWrapper);

      // release the container...
      RELEASE(container);
      [document endArchiving];
    }

  return fileWrappers;
}
@end
