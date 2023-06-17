/* All rights reserved */

#import <AppKit/AppKit.h>

#include <GormCore/GormCore.h>
#include <GormCore/GormPrefs.h>

#include <GNUstepBase/GSObjCRuntime.h>

@interface GormAppDelegate : NSObject <IB, GormAppDelegate, GormServer>
{
  IBOutlet id gormMenu;
  IBOutlet id guideLineMenuItem;

  GormPrefController    *preferencesController;
  GormClassManager	*classManager;
  GormInspectorsManager	*inspectorsManager;
  GormPalettesManager	*palettesManager;
  GormPluginManager	*pluginManager;
  id<IBSelectionOwners>	selectionOwner;
  BOOL			isConnecting;
  BOOL			isTesting;
  id             	testContainer;
  NSMenu		*mainMenu; // saves the main menu...
  NSMenu                *servicesMenu; // saves the services menu...
  NSMenu                *classMenu; // so we can set it for the class view
  NSDictionary		*menuLocations;
  NSImage		*linkImage;
  NSImage		*sourceImage;
  NSImage		*targetImage;
  NSImage               *gormImage;
  NSImage               *testingImage;
  id			connectSource;
  id			connectDestination;
  NSMutableArray        *testingWindows;
  NSSet                 *topObjects;
}

@end
