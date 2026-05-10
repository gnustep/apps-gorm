#include <AppKit/AppKit.h>

#ifndef	INCLUDED_GormNSPopUpButton_h
#define	INCLUDED_GormNSPopUpButton_h
GS_EXPORT_CLASS
@interface GormNSPopUpButton : NSPopUpButton
@end
GS_EXPORT_CLASS
@interface GormNSPopUpButtonCell : NSPopUpButtonCell
{
}
@end

@interface NSPopUpButtonCell (DirtyHack)
- (id) _gormInitTextCell: (NSString *) string;
@end

#endif
