#ifndef __INCLUDED_GormDocumentWindow_h
#include <AppKit/NSWindow.h>
#include <GormLib/IBResourceManager.h>

@interface GormDocumentWindow : NSWindow
{
  id _document;
  IBResourceManager *dragMgr;
}

@end

#define __INCLUDED_GormDocumentWindow_h
#endif
