/* GormPrivate.m
 *
 * Copyright (C) 1999, 2003 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2003, 2004
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include "GormPrivate.h"
#include "GormFontViewController.h"
#include "GormSetNameController.h"
#include "GNUstepGUI/GSNibCompatibility.h"
#include "GNUstepBase/GSObjCRuntime.h"

// for templates...
#include <AppKit/NSControl.h>
#include <AppKit/NSButton.h>

NSString *GormToggleGuidelineNotification = @"GormToggleGuidelineNotification";
NSString *GormDidModifyClassNotification = @"GormDidModifyClassNotification";
NSString *GormDidAddClassNotification = @"GormDidAddClassNotification";
NSString *GormDidDeleteClassNotification = @"GormDidDeleteClassNotification";
NSString *GormWillDetachObjectFromDocumentNotification = @"GormWillDetachObjectFromDocumentNotification";
NSString *GormResizeCellNotification = @"GormResizeCellNotification";

// Define this as "NO" initially.   We only want to turn this on while loading or testing.
static BOOL _isInInterfaceBuilder = NO;

@class	InfoPanel;

// we had this include for grouping/ungrouping selectors
#include "GormViewWithContentViewEditor.h"

@implementation GSNibItem (GormAdditions)
- initWithClassName: (NSString*)className frame: (NSRect)frame
{
  self = [super init];

  theClass = [className copy];
  theFrame = frame;

  return self;
}
- (NSString*) className
{
  return theClass;
}
@end

@interface NSObject (GormPrivate)
+ (void) poseAsClass: (Class)aClassObject;
@end

@implementation NSObject (GormPrivate)
+ (void) poseAsClass: (Class)aClassObject
{
  // disable poseAs: while in Gorm.
  class_pose_as(self, aClassObject);
  NSLog(@"WARNING: poseAs: called in Gorm.");
}

+ (BOOL) canSubstituteForClass: (Class)origClass
{
  if(self == origClass)
    {
      return YES;
    }
  else if([self isSubclassOfClass: origClass])
    {
      Class cls = self;
      while(cls != nil && cls != origClass)
	{
	  if(GSGetMethod(cls, @selector(initWithCoder:), YES, NO) != NULL &&
	     GSGetMethod(cls, @selector(encodeWithCoder:), YES, NO) != NULL)
	    {
	      return NO;
	    }
	  cls = GSObjCSuper(cls); // get super class
	}
      return YES;
    }

  return NO;
}
@end

@implementation GormObjectProxy
/*
 * Perhaps this would be better to have a dummy initProxyWithCoder
 * in GSNibItem class, so that we are not dependent on actual coding
 * order of the ivars ?
 */
- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: 
			  NSStringFromClass([GSNibItem class])];
  
  if (version == NSNotFound)
    {
      NSLog(@"no GSNibItem");
      version = [aCoder versionForClassName: 
			  NSStringFromClass([GormObjectProxy class])];
    }

  if (version == 0)
    {
      // do not decode super (it would try to morph into theClass ! )
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      RETAIN(theClass); // release in dealloc of GSNibItem... 
      
      return self; 
    }
  else if (version == 1)
    {
      // do not decode super (it would try to morph into theClass ! )
      [aCoder decodeValueOfObjCType: @encode(id) at: &theClass];
      theFrame = [aCoder decodeRect];
      [aCoder decodeValueOfObjCType: @encode(unsigned int) 
	      at: &autoresizingMask];  
      RETAIN(theClass); // release in dealloc of GSNibItem... 
      
      return self; 
    }
  else
    {
      NSLog(@"no initWithCoder for version %d", version);
      RELEASE(self);
      return nil;
    }
}

- (NSString*) inspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (void) setClassName: (NSString *)className
{
  ASSIGNCOPY(theClass, className); 
}

- (NSImage *) imageForViewer
{
  NSImage *image = [super imageForViewer];
  if([theClass isEqual: @"NSFontManager"])
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString *path = [bundle pathForImageResource: @"GormFontManager"]; 
      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}

@end

// define the class proxy...
@implementation GormClassProxy
- (id) initWithClassName: (NSString *)n
{
  self = [super init];
  if (self != nil)
    {
      if([n isKindOfClass: [NSString class]])
	{
	  // create a copy.
	  ASSIGNCOPY(name, n);
	}
      else
	{
	  NSLog(@"Attempt to add a class proxy with className = %@",n);
	}
    }
  return self;
}

- (void) dealloc
{
  RELEASE(name);
  [super dealloc];
}

- (NSString*) className
{
  return name;
}

- (NSString*) inspectorClassName
{
  return @"GormClassInspector";
}

- (NSString*) classInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) connectInspectorClassName
{
  return @"GormNotApplicableInspector";
}

- (NSString*) sizeInspectorClassName
{
  return @"GormNotApplicableInspector";
}
@end

// custom class additions...
@implementation GSClassSwapper (GormCustomClassAdditions)
+ (void) setIsInInterfaceBuilder: (BOOL)flag
{
  _isInInterfaceBuilder = flag;
}

- (BOOL) isInInterfaceBuilder
{
  return _isInInterfaceBuilder;
}
@end

@implementation IBResourceManager (GormAdditions)
+ (void) registerForAllPboardTypes: (id)editor
			inDocument: (id)doc
{
  NSArray *allTypes = [doc allManagedPboardTypes];
  [editor registerForDraggedTypes: allTypes];
}
@end

// these are temporary until the deprecated templates are removed...
////////////////////////////////////////////////////////
// DEPRECATED TEMPLATES                               //
////////////////////////////////////////////////////////
@interface NSWindowTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSWindowTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSTextTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSTextTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSTextViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSTextViewTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSMenuTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSMenuTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSControlTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSControlTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end

@interface NSButtonTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder;
@end
@implementation NSButtonTemplate (GormCustomClassAdditions)
- (BOOL) isInInterfaceBuilder
{
  return YES;
}
@end
////////////////////////////////////////////////////////
// END OF DEPRECATED TEMPLATES                        //
////////////////////////////////////////////////////////


