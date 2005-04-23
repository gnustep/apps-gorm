/* GormPrivate.h
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef INCLUDED_GormPrivate_h
#define INCLUDED_GormPrivate_h

@class	GormDocument;
@class	GormInspectorsManager;
@class	GormPalettesManager;

#include <InterfaceBuilder/IBApplicationAdditions.h>
#include <InterfaceBuilder/IBInspector.h>
#include <InterfaceBuilder/IBViewAdditions.h>
#include <GormCore/GormFilesOwner.h>
#include <GormCore/GormDocument.h>
#include <GormCore/GormInspectorsManager.h>
#include <GormCore/GormClassManager.h>
#include <GormCore/GormPalettesManager.h>
#include <GormCore/GormOutlineView.h>
#include <GormCore/GormProtocol.h>

extern NSString *GormLinkPboardType;
extern NSString *GormToggleGuidelineNotification;
extern NSString *GormDidModifyClassNotification;
extern NSString *GormDidAddClassNotification;
extern NSString *GormDidDeleteClassNotification;
extern NSString *GormWillDetachObjectFromDocumentNotification;
extern NSString *GormResizeCellNotification;

// templates
@interface GSNibItem (GormAdditions)
- initWithClassName: (NSString*)className frame: (NSRect)frame;
- (NSString*) className;
@end

@interface GSClassSwapper (GormCustomClassAdditions)
+ (void) setIsInInterfaceBuilder: (BOOL)flag;
- (BOOL) isInInterfaceBuilder;
@end

@interface GormObjectProxy : GSNibItem 
/*
 * Use a GormObjectProxy in Gorm, but encode a GSNibItem in the archive.
 * This is done so that we can provide our own decoding method
 * (GSNibItem tries to morph into the actual class)
 */
- (void) setClassName: (NSString *)className;
@end

@interface GormClassProxy : NSObject
{
  NSString *name;
  int t;
}

- initWithClassName: (NSString*)n;
- (NSString*) className;
- (NSString*) inspectorClassName;
- (NSString*) connectInspectorClassName;
- (NSString*) sizeInspectorClassName;
@end

@interface GormClassEditor : GormOutlineView <IBEditors, IBSelectionOwners>
{
  GormDocument          *document;
  GormClassManager      *classManager;
  NSString              *selectedClass;
}
- (GormClassEditor*) initWithDocument: (GormDocument*)doc;
+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc;
- (void) setSelectedClassName: (NSString*)cn;
- (NSString *) selectedClassName;
- (void) selectClassWithObject: (id)obj editClass: (BOOL)flag;
- (void) selectClassWithObject: (id)obj;
- (void) selectClass: (NSString *)className editClass: (BOOL)flag;
- (void) selectClass: (NSString *)className;
- (BOOL) currentSelectionIsClass;
- (void) editClass;
- (void) createSubclass;
- (void) addAttributeToClass;
- (void) deleteSelection;
- (NSArray *) fileTypes;
@end

@interface	GormGenericEditor : NSMatrix <IBEditors, IBSelectionOwners>
{
  NSMutableArray	*objects;
  id<IBDocuments>	document;
  id			selected;
  NSPasteboard		*dragPb;
  NSString		*dragType;
  BOOL                  closed;
  BOOL                  activated;
  IBResourceManager     *resourceManager;
}
// selection methods...
- (void) selectObjects: (NSArray*)objects;
- (BOOL) wantsSelection;
- (void) copySelection;
- (void) deleteSelection;
- (void) pasteInSelection;
- (void) refreshCells;
- (void) closeSubeditors;

- (NSWindow*) window;
- (void) addObject: (id)anObject;
- (void) refreshCells;
- (void) removeObject: (id)anObject;
- (BOOL) activate;
- (id) initWithObject: (id)anObject inDocument: (id)aDocument;
- (void) close;
- (void) closeSubeditors;
- (BOOL) containsObject: (id)anObject;
- (void) copySelection;
- (void) deleteSelection;
- (id<IBDocuments>) document;
- (id) editedObject;
- (id<IBEditors>) openSubeditorForObject: (id)anObject;
- (void) orderFront;
- (void) pasteInSelection;
- (NSRect) rectForObject: (id)anObject;

- (NSArray *) objects;
- (BOOL) isOpened;
- (NSArray *) fileTypes;
@end

// private methods...
@interface GormGenericEditor (PrivateMethods)
- (void) groupSelectionInScrollView;
- (void) groupSelectionInSplitView;
- (void) groupSelectionInBox;
- (void) ungroup;
- (void) setEditor: (id)anEditor forDocument: (id<IBDocuments>)doc;
- (id) changeSelection: (id)sender;
@end

@interface GormObjectEditor : GormGenericEditor 
{
}
+ (void) setEditor: (id)editor forDocument: (id<IBDocuments>)aDocument;
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (BOOL) acceptsTypeFromArray: (NSArray*)types;
- (void) makeSelectionVisible: (BOOL)flag;
- (void) resetObject: (id)anObject;
- (void) removeAllInstancesOfClass: (NSString *)className;
@end

@interface GormResourceEditor : GormGenericEditor
{
}
- (void) draggedImage: (NSImage*)i endedAt: (NSPoint)p deposited: (BOOL)f;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)flag;
- (void) refreshCells;
- (id) placeHolderWithPath: (NSString *)path;
- (NSArray *) pbTypes;
- (NSString *) resourceType;
- (void) addSystemResources;
@end

@interface GormSoundEditor : GormResourceEditor 
{
}
+ (GormSoundEditor*) editorForDocument: (id<IBDocuments>)aDocument;
@end

@interface GormImageEditor : GormResourceEditor 
{
}
+ (GormImageEditor*) editorForDocument: (id<IBDocuments>)aDocument;
@end

/*
 * NSDateFormatter and NSNumberFormatter extensions
 * for Gorm Formatters used in the Data Palette
 */

@interface NSDateFormatter (GormAdditions)

+ (void) initialize;
+ (int) formatCount;
+ (NSString *) formatAtIndex: (int)index;
+ (int) indexOfFormat: (NSString *) format;
+ (NSString *) defaultFormat;
+ (id) defaultFormatValue;

@end

@interface NSNumberFormatter (GormAdditions)

+ (void) initialize;
+ (int) formatCount;
+ (NSString *) formatAtIndex: (int)index;
+ (NSString *) positiveFormatAtIndex: (int)index;
+ (NSString *) zeroFormatAtIndex: (int)index;
+ (NSString *) negativeFormatAtIndex: (int)index;
+ (NSDecimalNumber *) positiveValueAtIndex: (int)index;
+ (NSDecimalNumber *) negativeValueAtIndex: (int)index;
+ (int) indexOfFormat: format;
+ (NSString *) defaultFormat;
+ (id) defaultFormatValue;
- (NSString *) zeroFormat;

@end

@interface NSObject (GormAdditions)
- (id) allocSubstitute;
- (NSImage *) imageForViewer;
@end

@interface NSApplication (GormAdditions)
- (BOOL) illegalClassSubstitution;
@end

/*
 * Functions for drawing knobs etc.
 */
void GormDrawKnobsForRect(NSRect aFrame);
void GormDrawOpenKnobsForRect(NSRect aFrame);
NSRect GormExtBoundsForRect(NSRect aFrame);
IBKnobPosition GormKnobHitInRect(NSRect aFrame, NSPoint p);
void GormShowFastKnobFills(void);
void GormShowFrameWithKnob(NSRect aRect, IBKnobPosition aKnob);

#endif
