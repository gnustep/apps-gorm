/* GormNibWrapperLoader
 *
 * Copyright (C) 2006 Free Software Foundation, Inc.
 *
 * Author:      Gregory John Casamento <greg.casamento@gmail.com>
 * Date:        2006
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <GormCore/GormCore.h>

#include "GormNibWrapperLoader.h"
#include "GormOpenStepNibReader.h"

@class GormNSWindow;

@implementation GormNibWrapperLoader
+ (NSString *) fileType
{
  return @"GSNibFileType";
}

- (NSDictionary *)defaultClassesDict
{
  NSString *defaultClassesString = @"{ IBClasses = ({CLASS = FirstResponder; LANGUAGE = ObjC; SUPERCLASS = NSObject; }); IBVersion = 1; }";
  return [defaultClassesString propertyList];
}

- (BOOL) isTopLevelObject: (id)obj
{
  NSMapTable *objects = [_container objects];
  id val = NSMapGet(objects,obj);
  BOOL result = NO;

  if(val == _nibFilesOwner || val == nil)
    {
      result = YES;
    }

  return result;
}

- (BOOL) loadFileWrapper: (NSFileWrapper *)wrapper withDocument: (GormDocument *) doc
{
  BOOL result = NO;
  BOOL wasInInterfaceBuilder = [NSClassSwapper isInInterfaceBuilder];
  NSKeyedUnarchiver *u = nil;

  NS_DURING
    {
      NSData		        *data = nil;
      NSData                    *classes = nil;
      BOOL typedStream = NO;
      NSString                  *key = nil;
      GormPalettesManager       *palettesManager = [(id<GormAppDelegate>)[NSApp delegate] palettesManager];
      NSDictionary              *substituteClasses = [palettesManager substituteClasses];
      NSString                  *subClassName = nil;
      NSDictionary              *fileWrappers = nil;

      if ([super loadFileWrapper: wrapper withDocument: doc])
	{
	  GormClassManager *classManager = [document classManager];
	  id               docFilesOwner;
	  NSMapTable       *objects;
	  NSArray          *objs;
	  NSEnumerator     *en;
	  id               o;
	  NSMapTable       *classesTable;
	  NSArray          *classKeys;

	  // turn off custom classes...
	  [NSClassSwapper setIsInInterfaceBuilder: YES];	  

	  if([wrapper isDirectory])
	    {
              NSArray *payloads = [NSArray arrayWithObjects:
                @"keyedobjects.nib", @"objects.nib", @"data.nib", nil];
              fileWrappers = [wrapper fileWrappers];
              en = [payloads objectEnumerator];
              while ((key = [en nextObject]) != nil)
                {
                  NSFileWrapper *fw = [fileWrappers objectForKey: key];
                  if (fw != nil)
                    {
                      /* A corrupt preferred payload must not select an
                       * older interface from the same bundle. */
                      if ([fw isRegularFile]) data = [fw regularFileContents];
                      break;
                    }
                }
              if ([[fileWrappers objectForKey: @"classes.nib"] isRegularFile])
                {
                  classes = [[fileWrappers objectForKey: @"classes.nib"]
                    regularFileContents];
                  if (![classManager loadNibFormatCustomClassesWithData: classes])
                    {
                      if ([(id<GormAppDelegate>)[NSApp delegate] isInTool])
                        NSLog(@"Could not load the associated nib classes file.");
                      else
                        NSRunAlertPanel(_(@"Problem Loading"),
                          _(@"Could not open the associated classes file.\n"
                            @"You won't be able to edit connections on custom classes"),
                          _(@"OK"), nil, nil);
                    }
                }
	    }
	  else
	    {
	      data = [wrapper regularFileContents];
	      classes = nil; // (NSData *)0xdeadbeef;
	    }

	  // check the data...
	  if ([data length] == 0)
	    {
	      result = NO;
	    }
	  else
	    {
	      /*
	       * Create an unarchiver, and use it to unarchive the gorm file while
	       * handling class replacement so that standard objects understood
	       * by the gui library are converted to their Gorm internal equivalents.
	       */

              typedStream = GormOpenStepNibIsTypedStream(data);
              if (typedStream)
                data = GormOpenStepNibKeyedData(data);

	      u = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
	      [u setDelegate: self];
	      
	      /*
	       * Special internal classes
	       */ 
	      [u setClass: [GormCustomView class] 
		 forClassName: @"NSCustomView"];
	      [u setClass: [GormWindowTemplate class] 
		 forClassName: @"NSWindowTemplate"];
	      [u setClass: [GormNSWindow class] 
		 forClassName: @"NSWindow"];
	      
	      /*
	       * Substitute any classes specified by the palettes...
	       */
	      en = [substituteClasses keyEnumerator];
	      while((subClassName = [en nextObject]) != nil)
		{
		  NSString *realClassName = [substituteClasses objectForKey: subClassName];
		  Class substituteClass = NSClassFromString(subClassName);
		  [u setClass: substituteClass
		     forClassName: realClassName];
		}
	      
	      //
	      // decode
	      //
	      _container = [u decodeObjectForKey: @"IB.objectdata"];
	      if (_container == nil || [_container isKindOfClass: [NSIBObjectData class]] == NO)
		{
		  result = NO;
		}
	      else
		{
                  if (typedStream)
                    GormOpenStepNibFinishDecoding(u);
		  _nibFilesOwner = [_container objectForName: @"File's Owner"];
		  
		  docFilesOwner = [document filesOwner];
		  objects = [_container names];
		  /* Historical nibs may name only File's Owner.  The ownership
                   * map, not the names map, defines the complete graph. */
                  objs = [[NSSet setWithArray: [NSAllMapTableKeys(objects)
                    arrayByAddingObjectsFromArray:
                      NSAllMapTableKeys([_container objects])]] allObjects];
		  en = [objs objectEnumerator];
		  o = nil;
		  
		  //
		  // set the current class on the File's owner...
		  //
		  if ([_nibFilesOwner respondsToSelector: @selector(className)])
		    {
		      [docFilesOwner setClassName: [_nibFilesOwner className]];	  
		    }
		  
		  //
		  // add objects...
		  //
		  while((o = [en nextObject]) != nil)
		    {
		      id obj = o;
		      NSString *customClassName = nil;
		      NSString *objName = nil;
		      
		      // skip the file's owner, it is handled above...
		      if(o == _nibFilesOwner
			 || o == [document firstResponder])
			{
			  continue;
			}
		      
		      //
                      // If it's NSApplication (most likely the File's Owner)
                      // skip it...
                      //
                      if ([o isKindOfClass: [NSCustomObject class]]
                          || [o isKindOfClass: [GormObjectProxy class]])
                        {
                          if ([[o className] isEqualToString: @"NSApplication"])
                            {
                              continue;
                            }

                          customClassName = [o className];
                        }
                      
		      //
		      // if it's a window template, then replace it with an actual window.
		      //
		      if([o isKindOfClass: [NSWindowTemplate class]])
			{
			  NSString *className = [o className];
			  BOOL isDeferred = [o isDeferred];
			  BOOL isVisible = [[_container visibleWindows]
                                             containsObject: o];
			  
			  // make the object deferred/visible...
			  obj = [o nibInstantiate];
			  
			  [document setObject: obj isDeferred: isDeferred];
			  [document setObject: obj isVisibleAtLaunch: isVisible];

			  [document attachObject: obj
					toParent: nil];
			  
			  // record the custom class...
			  if([classManager isCustomClass: className])
			    {
			      customClassName = className;
			    }
			}

		      if([self isTopLevelObject: obj])
			{		  
			  [document attachObject: obj
                                        toParent: nil];
			}
		      
		      if(customClassName != nil)
			{
			  objName = [document nameForObject: obj];
			  [classManager setCustomClass: customClassName
                                               forName: objName];
			}
		    }
		  
                  /* Preserve explicit names after all parents are attached. */
                  en = [NSAllMapTableKeys([_container names]) objectEnumerator];
                  while ((o = [en nextObject]) != nil)
                    {
                      id obj = [o isKindOfClass: [NSWindowTemplate class]]
                        ? [o realObject] : o;
                      NSString *name = NSMapGet([_container names], o);
                      if (o != _nibFilesOwner && obj != nil
                          && [document nameForObject: obj] != nil)
                        [document setName: name forObject: obj];
                    }
                  
                  /*
                   * Legacy OpenStep/Rhapsody nibs named the application main
                   * menu "MainMenu" (or "_NSMainMenu").  The GNUstep gorm
                   * runtime loader (GSNibContainer -awakeWithContext:) auto-
                   * wires the main menu by looking up the name table for the
                   * key "NSMenu", so a converted gorm that keeps the legacy
                   * name would leave the menu orphaned: no menu bar appears
                   * and the menu key-equivalents (File > Open, ...) are
                   * dead.  Modern gorm documents already name the main menu
                   * "NSMenu" (see -attachObject: in GormDocument), so rename
                   * the legacy main menu to the name the runtime expects.
                   * The object is already attached and named by the loop
                   * above; renaming it here updates the name table, and
                   * because connections reference it by object identity,
                   * every written connection and the name table follow to
                   * "NSMenu".  -setName:forObject: bails out if the name is
                   * already taken, so a nib that genuinely has both a
                   * "MainMenu" and an "NSMenu" object is left untouched.
                   */
                  {
                    id mainMenu = [document objectForName: @"MainMenu"];
                    if (mainMenu == nil)
                      mainMenu = [document objectForName: @"_NSMainMenu"];
                    if ([mainMenu isKindOfClass: [NSMenu class]]
                        && [document objectForName: @"NSMenu"] == nil)
                      [document setName: @"NSMenu" forObject: mainMenu];
                  }

		  //
		  // Add custom classes...
		  //
		  classesTable = [_container classes];
		  classKeys = NSAllMapTableKeys(classesTable);
		  en = [classKeys objectEnumerator];
		  while((o = [en nextObject]) != nil)
		    {
		      NSString *name = [document nameForObject: o];
		      NSString *customClass = NSMapGet(classesTable, o);
		      if(name != nil && customClass != nil)
			{
			  [classManager setCustomClass: customClass forName: name];
			}
		      else
			{
			  NSLog(@"Name %@ or class %@ for object %@ is nil.", name, customClass, o);
			}
		    }
		  
		  //
		  // add connections...
		  //
		  en = [[_container connections] objectEnumerator];
		  o = nil;
		  while((o = [en nextObject]) != nil)
		    {
		      id dest = [o destination];
		      id src = [o source];
		      
		      // NSLog(@"Connector: %@",o);
		      
		      if([o isKindOfClass: [NSNibControlConnector class]])
			{
			  NSString *tag = [o label];
			  NSRange colonRange = [tag rangeOfString: @":"];
			  NSUInteger location = colonRange.location;
			  
			  if(location == NSNotFound)
			    {
			      NSString *newTag = [NSString stringWithFormat: @"%@:",tag];
			      [o setLabel: (id)newTag];
			    }
			}
		      
		      if(dest == _nibFilesOwner)
			{
			  [o setDestination: [document filesOwner]];
			}
		      else if(dest == nil)
			{
			  [o setDestination: [document firstResponder]];
			}
		      
		      if(src == _nibFilesOwner)
			{
			  [o setSource: [document filesOwner]];
			}
		      else if(src == nil)
			{
			  [o setSource: [document firstResponder]];
			}
		      
		      // check src/dest for window template...
		      if([src isKindOfClass: [NSWindowTemplate class]])
			{
			  id win = [src realObject];
			  [o setSource: win];
			}
		      
		      if([dest isKindOfClass: [NSWindowTemplate class]])
			{
			  id win = [dest realObject];
			  [o setDestination: win];
			}
		      
		      // skip any help connectors...
		      if([o isKindOfClass: [NSIBHelpConnector class]])
			{
			  continue;
			}
		      [document addConnector: o];
		    }
		  
		  
		  // clear the changes, since we just loaded the document.
		  [document updateChangeCount: NSChangeCleared];
		  
		  result = YES;
		}
	    }
	  [u finishDecoding];
	}
    }
  NS_HANDLER
    {
      [NSClassSwapper setIsInInterfaceBuilder: wasInInterfaceBuilder];
      if ([(id<GormAppDelegate>)[NSApp delegate] isInTool])
        NSLog(@"Failed to load nib: %@", [localException reason]);
      else
        NSRunAlertPanel(_(@"Problem Loading"), @"%@", _(@"OK"), nil, nil,
                       [localException reason]);
      result = NO; 
    }
  NS_ENDHANDLER;

  [NSClassSwapper setIsInInterfaceBuilder: wasInInterfaceBuilder];
  [u release];
  _container = nil;
  _nibFilesOwner = nil;

  // return the result.
  return result;
}

- (void) unarchiver: (NSKeyedUnarchiver *)unarchiver 
  willReplaceObject: (id)obj 
	 withObject: (id)newObj
{
  // Nothing for now...
}

- (id) unarchiver: (NSKeyedUnarchiver *)unarchiver didDecodeObject: (id)obj
{
  if([obj isKindOfClass: [NSWindowTemplate class]])
    {
      GormClassManager *classManager = [document classManager];
      Class clz ;
      NSString *className = [obj className];
      
      if([classManager isCustomClass: className])
	{
	  className = [classManager nonCustomSuperClassOf: className];
	}
      clz = [unarchiver classForClassName: className];
      [obj setBaseWindowClass: clz];
    }
  else if([obj respondsToSelector: @selector(setTarget:)] &&
	  [obj respondsToSelector: @selector(setAction:)] &&
	  [obj isKindOfClass: [NSCell class]] == NO)
    {
      // blank the target/action for all objects.
      [obj setTarget: nil];
      [obj setAction: NULL];
    }
  else if([obj isKindOfClass: [NSCustomObject class]])
    {
      GormClassManager *classManager = [document classManager];
      NSString *className = [obj className];
      /* Standalone nibs need not have a classes.nib companion.  Keep
       * unknown custom objects editable and give exporters a runtime
       * superclass, without replacing any supplied class metadata. */
      if ([className length] > 0 && ![classManager isKnownClass: className])
        {
          [classManager addClassNamed: className
                 withSuperClassNamed: @"NSObject"
                         withActions: nil
                         withOutlets: nil];
        }
      GormObjectProxy *o = [[GormObjectProxy alloc] initWithClassName: [obj className]];
      obj = o; // replace the object if it's an NSCustomObject...
    }

  return obj;
}
@end
