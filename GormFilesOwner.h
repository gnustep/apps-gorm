#ifndef INCLUDED_GormFilesOwner_h
#define INCLUDED_GormFilesOwner_h

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
