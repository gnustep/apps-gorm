/* All Rights reserved */

#include <AppKit/AppKit.h>

/**
 * GormFilePrefsManager manages per-file preferences and versioning metadata
 * for Gorm documents. It handles loading/saving encoded info, selecting
 * target library versions and archive formats, and maintaining version
 * profiles.
 */
@interface GormFilePrefsManager : NSObject <NSCoding>
{
  id showIncompatibilities;
  id targetVersion;
  id gormAppVersion;
  id archiveType;
  id iwindow;
  id itable;
  id fileType;

  // encoded ivars...
  NSInteger version;
  NSString *targetVersionName;
  NSString *archiveTypeName;

  // version profiles...
  NSDictionary *versionProfiles;
  NSDictionary *currentProfile;
}
/**
 * Show incompatibilities in the panel.
 */
- (void) showIncompatibilities: (id)sender;

/**
 * Action called when the target version pulldown is selected.
 */
- (void) selectTargetVersion: (id)sender;

/**
 * Action called when the archive type pulldown is selected.
 */
- (void) selectArchiveType: (id)sender;

/**
 * Loads the encoded file info from raw data and updates the manager state.
 */
- (BOOL) loadFromData: (NSData *)data;

/**
 * Loads the encoded file info from a file at the specified path.
 */
- (BOOL) loadFromFile: (NSString *)path;

/**
 * Returns the encoded file info representing the current preferences.
 */
- (NSData *) data;

/**
 * Returns the encoded file info including the current set of open items.
 */
- (NSData *) nibDataWithOpenItems: (NSArray *)openItems;

/**
 * Saves the encoded file info to a file at the specified path.
 */
- (BOOL) saveToFile: (NSString *)path;

/**
 * Loads the version profile with the specified version key and makes it
 * current for subsequent operations.
 */
- (void) loadProfile: (NSString *)version;

// accessors...

/**
 * Gorm Version of the current archive.
 */
- (int) version;

/**
 * Which version of the gui library, by name.
 */
- (NSString *)targetVersionName;

/**
 * The archive type name for the current document (e.g., format variant).
 */
- (NSString *)archiveTypeName;

/**
 * Are we set to the latest version?  Returns YES, if so.
 */
- (BOOL) isLatest;

// set class versions
/**
 * Sets the version of the classes.
 */
- (void) setClassVersions;

/**
 * Restores the versions to the most current.
 */
- (void) restoreClassVersions;

/**
 * Returns the version of the class in the current profile.
 */
- (int) versionOfClass: (NSString *)className;

// file type...
/**
 * Sets the file type name to record in the encoded info.
 */
- (void) setFileTypeName: (NSString *)ft;

/**
 * Returns the file type name recorded in the encoded info.
 */
- (NSString *) fileTypeName;

/**
 * The current Gorm version.
 */
+ (int) currentVersion;

/**
 * Current profile for the current model file.
 */
- (NSDictionary *) currentProfile;

/**
 * Version information for the model file.
 */
- (NSDictionary *) versionProfiles;

@end
