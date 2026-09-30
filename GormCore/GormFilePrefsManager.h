/* All Rights reserved */

#include <AppKit/AppKit.h>

/** Stores per-document file information. */
GS_EXPORT_CLASS
@interface GormFilePrefsManager : NSObject <NSCoding>
{
  id gormAppVersion;
  id archiveType;
  id fileType;

  // encoded ivars...
  NSInteger version;
  NSString *archiveTypeName;
}
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

// accessors...

/**
 * Gorm Version of the current archive.
 */
- (int) version;

/**
 * The archive type name for the current document (e.g., format variant).
 */
- (NSString *)archiveTypeName;

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

@end
