#include "GormDocumentWindow.h"
#include "GormPrivate.h"

#include <GormLib/IBResourceManager.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSPasteboard.h>

@implementation GormDocumentWindow
- (void) setDocument:(id)document
{
  _document = document;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
{
  NSPasteboard *pb = [sender draggingPasteboard];
  unsigned int mask = [sender draggingSourceOperationMask];
  unsigned int oper = NSDragOperationNone;
  dragMgr = [_document resourceManagerForPasteboard:pb];
  
  if (dragMgr)
    {
      if (mask & NSDragOperationCopy)
        {
	  oper = NSDragOperationCopy;
	}
      else if (mask & NSDragOperationLink)
        {
 	  oper = NSDragOperationLink;
	}
      else if (mask & NSDragOperationMove)
        {
  	  oper = NSDragOperationMove;
	}
      else if (mask & NSDragOperationGeneric)
        {
          oper = NSDragOperationGeneric;
	}
      else if (mask & NSDragOperationPrivate)
        {
          oper = NSDragOperationPrivate;
	}
    }

  return oper;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
  dragMgr = nil;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
  return !(dragMgr == nil);	
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
{
  [dragMgr addResourcesFromPasteboard:[sender draggingPasteboard]];
  return !(dragMgr == nil);	
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
{
  dragMgr = nil;
}

- (void)draggingEnded: (id <NSDraggingInfo>)sender;
{
  dragMgr = nil;
}

@end

