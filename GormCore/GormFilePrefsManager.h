/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface GormFilePrefsManager : NSObject <NSCoding>
{
  id showIncompatibilities;
  id targetVersion;
  id gormAppVersion;
  id archiveType;
  id iwindow;
  id itable;
  
  // encoded ivars...
  int version;
  NSString *targetVersionName;
  NSString *archiveTypeName;

  // version profiles...
  NSDictionary *versionProfiles;
  NSDictionary *currentProfile;
}
- (void) showIncompatibilities: (id)sender;
- (void) selectTargetVersion: (id)sender;
- (void) selectArchiveType: (id)sender;

- (BOOL) loadFromFile: (NSString *)path;
- (BOOL) saveToFile: (NSString *)path;
- (void) loadProfile: (NSString *)version;

// accessors...
- (int) version;
- (NSString *)targetVersionName;
- (NSString *)archiveTypeName;
- (BOOL) isLatest;

// set class versions
- (void) setClassVersions;
- (void) restoreClassVersions;
- (int) versionOfClass: (NSString *)className;

+ (int) currentVersion;
@end
