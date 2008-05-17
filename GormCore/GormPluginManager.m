/* GormPalettesManager.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2004
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

#include "GormPrivate.h"
#include <Foundation/NSArray.h>
#include <Foundation/NSSet.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSSound.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include "GormFunctions.h"
#include "GormPluginManager.h"

#define BUILTIN_PLUGINS @"BuiltinPlugins"
#define USER_PLUGINS    @"UserPlugins"

@implementation GormPluginManager

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(bundles);
  RELEASE(plugins);
  RELEASE(pluginsDict);
  [super dealloc];
}

/*
- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];

  if ([name isEqual: IBWillBeginTestingInterfaceNotification] == YES)
    {
      if ([panel isVisible] == YES)
	{
	  hiddenDuringTest = YES;
	  [panel orderOut: self];
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if (hiddenDuringTest == YES)
	{
	  hiddenDuringTest = NO;
	  [panel orderFront: self];
	}
    }
}
*/

- (id) init
{
  NSArray	 *array;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray        *userPlugins = [defaults arrayForKey: USER_PLUGINS];
  // NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  
  self = [super init];
  if(self != nil)
    {
      /*
      if([NSBundle loadNibNamed: @"GormPluginPanel" owner: self] == NO)
        {
          return nil;
        }
      */
    }
  else
    {
      return nil;
    }
  
  //
  // Initialize dictionary
  //
  pluginsDict = [[NSMutableDictionary alloc] init];
  plugins = [[NSMutableArray alloc] init];
  pluginNames = [[NSMutableArray alloc] init];

  //
  // Set frame name
  //
  // [panel setFrameUsingName: @"Plugins"];
  // [panel setFrameAutosaveName: @"Plugins"];
 
  array = [[NSBundle mainBundle] pathsForResourcesOfType: @"plugin"
                                 inDirectory: nil];
  if ([array count] > 0)
    {
      unsigned	index;
      
      array = [array sortedArrayUsingSelector: @selector(compare:)];
      
      for (index = 0; index < [array count]; index++)
	{
	  [self loadPlugin: [array objectAtIndex: index]];
	}
    }
  
  // if we have any user plugins load them as well.
  if(userPlugins != nil)
    {
      NSEnumerator *en = [userPlugins objectEnumerator];
      id pluginName = nil;
      while((pluginName = [en nextObject]) != nil)
        {
          [self loadPlugin: pluginName];
        }
    }

  /*
  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: IBWillBeginTestingInterfaceNotification
      object: nil];
  [nc addObserver: self
      selector: @selector(handleNotification:)
      name: IBWillEndTestingInterfaceNotification
      object: nil];
  */

  return self;
}

- (BOOL) bundlePathIsLoaded: (NSString *)path
{
  int		col = 0;  
  NSBundle	*bundle;
  for (col = 0; col < [bundles count]; col++)
    {
      bundle = [bundles objectAtIndex: col];
      if ([path isEqualToString: [bundle bundlePath]] == YES)
	{
	  return YES;
	}
    }
  return NO;
}

- (BOOL) loadPlugin: (NSString*)path
{
  NSBundle	*bundle;
  NSString	*className;
  IBPlugin	*plugin;
  Class		pluginClass;
  //NSDictionary	*pluginInfo;
  //NSWindow	*window;
  //NSArray       *exportClasses;
  //NSArray       *exportSounds;
  //NSArray       *exportImages;
  //NSDictionary  *subClasses;

  if([self bundlePathIsLoaded: path])
    {
      NSRunAlertPanel (nil, _(@"Plugin has already been loaded"), 
		       _(@"OK"), nil, nil);
      return NO;
    }
  bundle = [NSBundle bundleWithPath: path]; 
  if (bundle == nil)
    {
      NSRunAlertPanel(nil, _(@"Could not load Plugin"), 
		      _(@"OK"), nil, nil);
      return NO;
    }

  /* May use this later for class description 
  path = [bundle pathForResource: @"plugin" ofType: @"table"];
  if (path == nil)
    {
      NSRunAlertPanel(nil, _(@"File 'palette.table' missing"),
		      _(@"OK"), nil, nil);
      return NO;
    }

  // attempt to load the palette table in either the strings or plist format.
  NS_DURING
    {
      paletteInfo = [[NSString stringWithContentsOfFile: path] propertyList];
      if (paletteInfo == nil)
	{
	  paletteInfo = [[NSString stringWithContentsOfFile: path] propertyListFromStringsFileFormat];
	  if(paletteInfo == nil)
	    {
	      NSRunAlertPanel(_(@"Problem Loading Palette"), 
			      _(@"Failed to load 'palette.table' using strings or property list format."),
			      _(@"OK"), 
			      nil, 
			      nil);
	      return NO;
	    }
	}
    }
  NS_HANDLER
    {
      NSString *message = [NSString stringWithFormat: 
				      _(@"Encountered exception %@ attempting to load 'palette.table'."),
				    [localException reason]];
      NSRunAlertPanel(_(@"Problem Loading Palette"), 
		      message,
		      _(@"OK"), 
		      nil, 
		      nil);
      return NO;
    }
  NS_ENDHANDLER
  */

  className = [[bundle infoDictionary] objectForKey: @"NSPrincipalClass"];
  if (className == nil)
    {
      NSRunAlertPanel(nil, _(@"No plugin class in plist"),
		      _(@"OK"), nil, nil);
      return NO;
    }

  pluginClass = [bundle classNamed: className];
  if (pluginClass == 0)
    {
      NSRunAlertPanel (nil, _(@"Could not load palette class"), 
		       _(@"OK"), nil, nil);
      return NO;
    }

  plugin = [[pluginClass alloc] init];
  if ([plugin isKindOfClass: [IBPlugin class]] == NO)
    {
      NSRunAlertPanel (nil, _(@"Plugin contains wrong type of class"), 
		       _(@"OK"), nil, nil);
      RELEASE(plugin);
      return NO;
    }

  // add to the bundles list...
  [bundles addObject: bundle];	

  /*
  exportClasses = [paletteInfo objectForKey: @"ExportClasses"];
  if(exportClasses != nil)
    {
      [self importClasses: exportClasses withDictionary: nil];
    }

  exportImages = [paletteInfo objectForKey: @"ExportImages"];
  if(exportImages != nil)
    {
      [self importImages: exportImages withBundle: bundle];
    }

  exportSounds = [paletteInfo objectForKey: @"ExportSounds"];
  if(exportSounds != nil)
    {
      [self importSounds: exportSounds withBundle: bundle];
    }

  subClasses = [paletteInfo objectForKey: @"SubstituteClasses"];
  if(subClasses != nil)
    {
      [substituteClasses addEntriesFromDictionary: subClasses];
    }
  */
 
  [plugin didLoad];

  // manage plugin data.
  [pluginsDict setObject: plugin forKey: className];
  [plugins addObject: plugin];
  [pluginNames addObject: className];

  RELEASE(plugin);

  return YES;
}

- (id) openPlugin: (id) sender
{
  NSArray	 *fileTypes = [NSArray arrayWithObject: @"plugin"];
  NSOpenPanel	 *oPanel = [NSOpenPanel openPanel];
  int		 result;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray        *userPlugins = [defaults arrayForKey: USER_PLUGINS];
  NSMutableArray *newUserPlugins = 
    (userPlugins == nil)?[NSMutableArray array]:[NSMutableArray arrayWithArray: userPlugins];

  [oPanel setAllowsMultipleSelection: YES];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
				   file: nil
				  types: fileTypes];

  if (result == NSOKButton)
    {
      NSArray	*filesToOpen = [oPanel filenames];
      unsigned	count = [filesToOpen count];
      unsigned	i;

      for (i = 0; i < count; i++)
	{
	  NSString	*aFile = [filesToOpen objectAtIndex: i];

	  if([self bundlePathIsLoaded: aFile] == YES &&
	     [userPlugins containsObject: aFile] == NO)
	    {
	      [newUserPlugins addObject: aFile];
	    }
	  else if([self loadPlugin: aFile] == NO)
	    {
	      return nil;
	    }
	  else
	    {
	      [newUserPlugins addObject: aFile];
	    }
	}

      // reset the defaults to include the new plugin.
      [defaults setObject: newUserPlugins forKey: USER_PLUGINS];
      return self;
    }
  return nil;
}

/*
- (NSPanel*) panel
{
  return panel;
}
*/
@end
