#ifndef GORMFILESOWNER_H
#define GORMFILESOWNER_H

/*
 * Each document has a GormFilesOwner object that is used as a placeholder
 * for the owner of the document.
 */
@interface	GormFilesOwner : NSObject
{
  NSString	*className;
}
- (NSString*) className;
- (void) setClassName: (NSString*)aName;
@end

#endif
