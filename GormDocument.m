/* GormDocument.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
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

#include "GormPrivate.h"
#include "GormClassManager.h"
#include "GormCustomView.h"

NSString *IBDidOpenDocumentNotification = @"IBDidOpenDocumentNotification";
NSString *IBWillSaveDocumentNotification = @"IBWillSaveDocumentNotification";
NSString *IBDidSaveDocumentNotification = @"IBDidSaveDocumentNotification";
NSString *IBWillCloseDocumentNotification = @"IBWillCloseDocumentNotification";



@implementation	GormFirstResponder
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormFirstResponder"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
- (NSString*) inspectorClassName
{
  return @"GormNotApplicableInspector";
}
- (NSString*) connectInspectorClassName
{
  return @"GormConnectionInspector";
}
- (NSString*) sizeInspectorClassName
{
  return @"GormNotApplicableInspector";
}
@end

@implementation	GormFontManager
- (NSImage*) imageForViewer
{
  static NSImage	*image = nil;

  if (image == nil)
    {
      NSBundle	*bundle = [NSBundle mainBundle];
      NSString	*path = [bundle pathForImageResource: @"GormFontManager"];

      image = [[NSImage alloc] initWithContentsOfFile: path];
    }
  return image;
}
@end



/*
 * Trivial classes for connections from objects to their editors, and from
 * child editors to their parents.  This does nothing special, but we can
 * use the fact that it's a different class to search for it in the connections
 * array.
 */
@interface	GormObjectToEditor : NSNibConnector
@end

@implementation	GormObjectToEditor
@end

@interface	GormEditorToParent : NSNibConnector
@end

@implementation	GormEditorToParent
@end

@implementation GormDocument

static NSImage	*objectsImage = nil;
static NSImage	*imagesImage = nil;
static NSImage	*soundsImage = nil;
static NSImage	*classesImage = nil;

+ (void) initialize
{
  if (self == [GormDocument class])
    {
      NSBundle	*bundle;
      NSString	*path;

      bundle = [NSBundle mainBundle];
      path = [bundle pathForImageResource: @"GormObject"];
      if (path != nil)
	{
	  objectsImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormImage"];
      if (path != nil)
	{
	  imagesImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormSound"];
      if (path != nil)
	{
	  soundsImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
      path = [bundle pathForImageResource: @"GormClass"];
      if (path != nil)
	{
	  classesImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
    }
}

- (void) addConnector: (id<IBConnectors>)aConnector
{
  if ([connections indexOfObjectIdenticalTo: aConnector] == NSNotFound)
    {
      [connections addObject: aConnector];
    }
}

- (NSArray*) allConnectors
{
  return [NSArray arrayWithArray: connections];
}

- (void) attachObject: (id)anObject toParent: (id)aParent
{
  NSArray	*old;

  /*
   * Create a connector that links this object to its parent.
   * A nil parent is the root of the hierarchy so we use a dummy object for it.
   */
  if (aParent == nil)
    {
      aParent = filesOwner;
    }
  old = [self connectorsForSource: anObject ofClass: [NSNibConnector class]];
  if ([old count] > 0)
    {
      [[old objectAtIndex: 0] setDestination: aParent];
    }
  else
    {
      NSNibConnector	*con = [NSNibConnector new];

      [con setSource: anObject];
      [con setDestination: aParent];
      [self addConnector: (id<IBConnectors>)con];
      RELEASE(con);
    }
  /*
   * Make sure that there is a name for this object.
   */
  if ([self nameForObject: anObject] == nil)
    {
      [self setName: nil forObject: anObject];
    }

  /*
   * Add top-level objects to objectsView and open their editors.
   */
  if ([anObject isKindOfClass: [NSWindow class]] == YES
    || [anObject isKindOfClass: [NSMenu class]] == YES
    || [anObject isKindOfClass: [GSNibItem class]] == YES)
    {
      [objectsView addObject: anObject];
      [[self openEditorForObject: anObject] activate];
      if ([anObject isKindOfClass: [NSWindow class]] == YES)
	{
	  [anObject setReleasedWhenClosed: NO];
	}
    }

  /*
   * if this a scrollview, it is interesting to add its contentview
   * if it is a tableview or a textview
   */
  if (([anObject isKindOfClass: [NSScrollView class]] == YES)
      && ([(NSScrollView *)anObject documentView] != nil))
    {
      if ([[anObject documentView] isKindOfClass: 
				    [NSTableView class]] == YES)
	{
	  [self attachObject: [anObject documentView]
		toParent: aParent];
	}
      else if ([[anObject documentView] isKindOfClass: 
					  [NSTextView class]] == YES)
	{
	  [self attachObject: [anObject documentView]
		toParent: aParent];
	}

    }
}

- (void) attachObjects: (NSArray*)anArray toParent: (id)aParent
{
  NSEnumerator	*enumerator = [anArray objectEnumerator];
  NSObject	*obj;

  while ((obj = [enumerator nextObject]) != nil)
    {
      [self attachObject: obj toParent: aParent];
    }
}

- (void) beginArchiving
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  id			obj;

  /*
   * Map all connector sources and destinations to their name strings.
   * Deactivate editors so they won't be archived.
   */
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      if ([con isKindOfClass: [GormObjectToEditor class]] == YES)
	{
	  [savedEditors addObject: con];
	  [[con destination] deactivate];
	}
      else if ([con isKindOfClass: [GormEditorToParent class]] == YES)
	{
	  [savedEditors addObject: con];
	}
      else
	{
	  NSString	*name;

	  obj = [con source];
	  name = [self nameForObject: obj];
	  [con setSource: name];
	  obj = [con destination];
	  name = [self nameForObject: obj];
	  [con setDestination: name];
	}
    }
  [connections removeObjectsInArray: savedEditors];

  /*
   * Remove objects and connections that shouldn't be archived.
   */
  NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSOwner"]);
  [nameTable removeObjectForKey: @"NSOwner"];
  NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSFirst"]);
  [nameTable removeObjectForKey: @"NSFirst"];
  if (fontManager != nil)
    {
      NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSFont"]);
      [nameTable removeObjectForKey: @"NSFont"];
    }

  /* Add information about the NSOwner to the archive */
  NSMapInsert(objToName, (void*)[filesOwner className], (void*)@"NSOwner");
  [nameTable setObject: [filesOwner className] forKey: @"NSOwner"];  
}

- (void) changeCurrentClass: (id)sender
{
  int	row = [classesView selectedRow];
  id	classes = [classManager allClassNames];

  NSLog(@"Double Action");

  if (row >= 0 && row < [classes count])
    {
      [classEditor setSelectedClassName: [classes objectAtIndex: row]];
      [self setSelectionFromEditor: (id)classEditor];
    }
  
}

- (void) changeView: (id)sender
{
  int tag = [[sender selectedCell] tag];

  switch (tag)
    {
      case 0: // objects
	[selectionBox setContentView: scrollView];
	break;

      case 3: // classes
	[selectionBox setContentView: classesScrollView];
	break;
    }
}

- (GormClassManager*) classManager
{
  return classManager;
}

/*
 * A Gorm document is encoded in the archive as a GSNibContainer ...
 * A class that the gnustep gui library knbows about and can unarchive.
 */
- (Class) classForCoder
{
  return [GSNibContainer class];
}

- (NSArray*) connectorsForDestination: (id)destination
{
  return [self connectorsForDestination: destination ofClass: 0];
}

- (NSArray*) connectorsForDestination: (id)destination
                              ofClass: (Class)aConnectorClass
{
  NSMutableArray	*array = [NSMutableArray arrayWithCapacity: 16];
  NSEnumerator		*enumerator = [connections objectEnumerator];
  id<IBConnectors>	c;

  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c destination] == destination
	&& (aConnectorClass == 0 || aConnectorClass == [c class]))
	{
	  [array addObject: c];
	}
    }
  return array;
}

- (NSArray*) connectorsForSource: (id)source
{
  return [self connectorsForSource: source ofClass: 0];
}

- (NSArray*) connectorsForSource: (id)source
			 ofClass: (Class)aConnectorClass
{
  NSMutableArray	*array = [NSMutableArray arrayWithCapacity: 16];
  NSEnumerator		*enumerator = [connections objectEnumerator];
  id<IBConnectors>	c;

  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c source] == source
	&& (aConnectorClass == 0 || aConnectorClass == [c class]))
	{
	  [array addObject: c];
	}
    }
  return array;
}

- (BOOL) containsObject: (id)anObject
{
  if ([self nameForObject: anObject] == nil)
    {
      return NO;
    }
  return YES;
}

- (BOOL) containsObjectWithName: (NSString*)aName forParent: (id)parent
{
  id	obj = [nameTable objectForKey: aName];

  if (obj == nil)
    {
      return NO;
    }
  return YES; 
}

- (BOOL) copyObject: (id)anObject
               type: (NSString*)aType
       toPasteboard: (NSPasteboard*)aPasteboard
{
  return [self copyObjects: [NSArray arrayWithObject: anObject]
		      type: aType
	      toPasteboard: aPasteboard];
}

- (BOOL) copyObjects: (NSArray*)anArray
                type: (NSString*)aType
        toPasteboard: (NSPasteboard*)aPasteboard
{
  NSEnumerator	*enumerator;
  NSMutableSet	*editors;
  id		obj;
  NSData	*data;

  /*
   * Remove all editors from the selected objects before archiving
   * and restore them afterwards.
   */
  editors = [NSMutableSet new];
  enumerator = [anArray objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    {
      id	editor = [self editorForObject: obj create: NO];

      if (editor != nil)
	{
	  [editors addObject: editor];
	  [editor deactivate];
	}
    }
  data = [NSArchiver archivedDataWithRootObject: anArray];
  enumerator = [editors objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil)
    {
      [obj activate];
    }
  RELEASE(editors);

  [aPasteboard declareTypes: [NSArray arrayWithObject: aType]
		      owner: self];
  return [aPasteboard setData: data forType: aType];
}

- (id) createSubclass: (id)sender
{
  int		i = [classesView selectedRow];
  NSArray	*classNames = [classManager allClassNames];

  if (i >= 0 && i < [classNames count])
    {
      NSString	*newClassName;

      newClassName = [classManager addClassWithSuperClassName:
	[classNames objectAtIndex: i]];
      [classesView reloadData];
      classNames = [classManager allClassNames];
      i = [classNames indexOfObject: newClassName];
      [classesView selectRow: i byExtendingSelection: NO];
      [self editClass: self];
    }
  return self;
}

- (void) pasteboardChangedOwner: (NSPasteboard*)sender
{
  NSDebugLog(@"Owner changed for %@", sender);
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [window setDelegate: nil];
  [window performClose: self];
  RELEASE(classManager);
  RELEASE(classEditor);
  RELEASE(hidden);
  RELEASE(filesOwner);
  RELEASE(firstResponder);
  RELEASE(fontManager);
  NSFreeMapTable(objToName);
  RELEASE(documentPath);
  RELEASE(savedEditors);
  RELEASE(scrollView);
  RELEASE(classesScrollView);
  [super dealloc];
}

- (void) detachObject: (id)anObject
{
  NSString	*name = RETAIN([self nameForObject: anObject]);
  unsigned	count;

  [[self editorForObject: anObject create: NO] close];

  count = [connections count];
  while (count-- > 0)
    {
      id<IBConnectors>	con = [connections objectAtIndex: count];

      if ([con destination] == anObject || [con source] == anObject)
	{
	  [connections removeObjectAtIndex: count];
	}
    }
  NSMapRemove(objToName, (void*)anObject);
  if ([anObject isKindOfClass: [NSWindow class]] == YES
    || [anObject isKindOfClass: [NSMenu class]] == YES)
    {
      [objectsView removeObject: anObject];
    }
  /*
   * Make sure this object isn't in the list of objects to be made visible
   * on nib loading.
   */
  [self setObject: anObject isVisibleAtLaunch: NO];

  [nameTable removeObjectForKey: name];
  RELEASE(name);
}

- (void) detachObjects: (NSArray*)anArray
{
  NSEnumerator  *enumerator = [anArray objectEnumerator];
  NSObject      *obj;

  while ((obj = [enumerator nextObject]) != nil)
    {
      [self detachObject: obj];
    }
}

- (NSString*) documentPath
{
  return documentPath;
}

- (id) parseHeader: (NSString *)headerPath
{
  NSString *headerFile = [NSString stringWithContentsOfFile: headerPath];
  NSScanner *headerScanner = [NSScanner scannerWithString: headerFile];
  GormClassManager *cm = [self classManager];

  while(![headerScanner isAtEnd])
    {
      NSScanner *classScanner = nil;
      NSString *classString = nil;
      BOOL classfound = NO, result = NO;
      NSArray *outletTokens = [NSArray arrayWithObjects: @"id", @"IBOutlet", nil];
      NSArray *actionTokens = [NSArray arrayWithObjects: @"(void)", @"(IBAction)", nil];
      NSEnumerator *outletEnum = [outletTokens objectEnumerator];
      NSEnumerator *actionEnum = [actionTokens objectEnumerator];
      NSString *outletToken = nil;
      NSString *actionToken = nil;

      classfound = [headerScanner scanUpToString: @"@interface"
			     intoString: nil];

      [headerScanner scanUpToString: @"@end"
		     intoString: &classString];
      
      if(classfound && ![headerScanner isAtEnd])
	{
	  NSString 
	    *className = nil,
	    *superClassName = nil,
	    *ivarString = nil,
	    *methodString = nil;
	  NSScanner 
	    *classScanner = [NSScanner scannerWithString: classString],
	    *ivarScanner = nil,
	    *methodScanner = nil;
	  NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString: @" :"];
	  NSMutableArray 
	    *actions = [NSMutableArray array],
	    *outlets = [NSMutableArray array];

	  [classScanner scanString: @"@interface"
			intoString: nil];
	  [classScanner scanUpToCharactersFromSet: stopSet
			intoString: &className];
	  [classScanner scanString: @":"
			intoString: nil];
	  [classScanner scanUpToString: @"\n"
			intoString: &superClassName];
	  [classScanner scanUpToString: @"{"
			intoString: nil];
	  [classScanner scanUpToString: @"}"
			intoString: &ivarString];
	  [classScanner scanUpToString: @"@end"
			intoString: &methodString];
	  NSDebugLog(@"Found a class \"%@\" with super class \"%@\"", className,
		     superClassName);

	  // Interate over the possible tokens which can make an
	  // ivar an outlet.
	  while((outletToken = [outletEnum nextObject]) != nil)
	    {
	      NSDebugLog(@"outlet Token = %@",outletToken);
	      // Scan the variables of the class...
	      ivarScanner = [NSScanner scannerWithString: ivarString];
	      while(![ivarScanner isAtEnd])
		{
		  NSString *outlet = nil;
		  
		  [ivarScanner scanUpToString: outletToken
			       intoString: nil];
		  [ivarScanner scanString: outletToken
			       intoString: nil];
		  [ivarScanner scanUpToString: @";"
			       intoString: &outlet];
		  if(![ivarScanner isAtEnd])
		    {
		      NSDebugLog(@"outlet = %@",outlet);
		      [outlets addObject: outlet];
		    }
		}
	    }
	  
	  while((actionToken = [actionEnum nextObject]) != nil)
	    {
	      NSDebugLog(@"Action token %@",actionToken);
	      methodScanner = [NSScanner scannerWithString: methodString];
	      while(![methodScanner isAtEnd])
		{
		  NSString *action = nil;
		  BOOL hasArguments = NO;
		  NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString: @";:"];
		  
		  // Scan the method name
		  [methodScanner scanUpToString: actionToken
				 intoString: nil];
		  [methodScanner scanString: actionToken
				 intoString: nil];
		  [methodScanner scanUpToCharactersFromSet: stopSet
				 intoString: &action];
		  
		  // This will return true if the method has args.
		  hasArguments = [methodScanner scanString: @":"
						intoString: nil];
		  
		  if(hasArguments)
		    {
		      BOOL isAction = NO;
		      NSString *argType = nil;
		      
		      // If the argument is (id) then the method can
		      // be considered an action and we add it to the list.
		      isAction = [methodScanner scanString: @"(id)"
						intoString: &argType];
		      
		      if(![methodScanner isAtEnd])
			{
			  if(isAction)
			    {
			      NSDebugLog(@"action = %@",action);
			      [actions addObject: action];
			    }
			  else
			    {
			      NSDebugLog(@"Not an action");
			    }
			}
		    }
		} // end while
	    } // end while 

	  result = [cm addClassNamed: className
		       withSuperClassNamed: superClassName
		       withActions: actions
		       withOutlets: outlets];
	  if(result)
	    {
	      NSLog(@"Class %@ added", className);
	    }
	  else
	    {
	      NSLog(@"Class %@ failed to add", className);
	    }
	} // if we found a class
    }
  return self;
}

- (id) loadClass: (id)sender
{
  NSArray	*fileTypes = [NSArray arrayWithObjects: @"h", @"H", nil];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
       return [self parseHeader: [oPanel filename]];
    }

  return nil;
}

- (id) editClass: (id)sender
{
  [self changeCurrentClass: sender];

  return self;
}

- (id) createClassFiles: (id)sender
{
  NSSavePanel		*sp;
  int	row = [classesView selectedRow];
  id	classes = [classManager allClassNames];
  int			result;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: @"m"];
  [sp setTitle: @"Save source file as..."];
  if (documentPath == nil)
    result = [sp runModalForDirectory: NSHomeDirectory() file: @""];
  else
    result = [sp runModalForDirectory: 
		   [documentPath stringByDeletingLastPathComponent]
		 file: @""];

  if (result == NSOKButton)
    {
      NSString *sourceName = [sp filename];
      NSString *headerName;

      [sp setRequiredFileType: @"h"];
      [sp setTitle: @"Save header file as..."];
      result = [sp runModalForDirectory: 
		     [sourceName stringByDeletingLastPathComponent]
		   file: 
		     [[[sourceName lastPathComponent]
			stringByDeletingPathExtension] 
		       stringByAppendingString: @".h"]];
      if (result == NSOKButton)
	{
	  headerName = [sp filename];
	  
	  NSLog(@"createClassFiles");
	  if (row >= 0 && row < [classes count])
	    {
	      NSLog([classes objectAtIndex: row]);
	      if (![classManager 
		     makeSourceAndHeaderFilesForClass: 
		       [classes objectAtIndex: row]
		     withName: sourceName
		     and: headerName])
		{
		  NSRunAlertPanel(@"Alert", 
				  @"Could not create the class's file",
				  nil, nil, nil);
		}
	      
	      return self;
	    }
	}
    }
  return nil;
}

- (void) editor: (id<IBEditors>)anEditor didCloseForObject: (id)anObject
{
  NSArray		*links;

  /*
   * If there is a link from this editor to a parent, remove it.
   */
  links = [self connectorsForSource: anEditor
			    ofClass: [GormEditorToParent class]];
  NSAssert([links count] < 2, NSInternalInconsistencyException);
  if ([links count] == 1)
    {
      [connections removeObjectIdenticalTo: [links objectAtIndex: 0]];
    }

  /*
   * Remove the connection linking the object to this editor
   */
  links = [self connectorsForSource: anObject
			    ofClass: [GormObjectToEditor class]];
  NSAssert([links count] < 2, NSInternalInconsistencyException);
  [connections removeObjectIdenticalTo: [links objectAtIndex: 0]];

  /*
   * Make sure that this editor is not the selection owner.
   */
  if ([(id<IB>)NSApp selectionOwner] == anEditor)
    {
      [self resignSelectionForEditor: anEditor];
    }
}

- (id<IBEditors>) editorForObject: (id)anObject
                           create: (BOOL)flag
{
  return [self editorForObject: anObject inEditor: nil create: flag];
}

- (id<IBEditors>) editorForObject: (id)anObject
                         inEditor: (id<IBEditors>)anEditor
                           create: (BOOL)flag
{
  NSArray	*links;

  /*
   * Look up the editor links for the object to see if it already has an
   * editor.  If it does return it, otherwise create a new editor and a
   * link to it if the flag is set.
   */
  links = [self connectorsForSource: anObject
			    ofClass: [GormObjectToEditor class]];
  if ([links count] == 0 && flag == YES)
    {
      Class		eClass;
      id<IBEditors>	editor;
      id<IBConnectors>	link;

      eClass = NSClassFromString([anObject editorClassName]);
      editor = [[eClass alloc] initWithObject: anObject inDocument: self];
      link = [GormObjectToEditor new];
      [link setSource: anObject];
      [link setDestination: editor];
      [connections addObject: link];
      RELEASE(link);
      if (anEditor == nil)
	{
	  /*
	   * By default all editors are owned by the top-level editor of
	   * the document.
           */
	  anEditor = objectsView;
	}
      if (anEditor != editor)
	{
	  /*
	   * Link to the parent of the editor.
	   */
	  link = [GormEditorToParent new];
	  [link setSource: editor];
	  [link setDestination: anEditor];
	  [connections addObject: link];
	  RELEASE(link);
	}
      RELEASE(editor);
      return editor;
    }
  else
    {
      return [[links lastObject] destination];
    }
}

- (void) endArchiving
{
  NSEnumerator		*enumerator;
  id<IBConnectors>	con;
  id			obj;

  /*
   * Restore removed objects.
   */
  NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSOwner"]);
  [nameTable setObject: filesOwner forKey: @"NSOwner"];
  NSMapInsert(objToName, (void*)filesOwner, (void*)@"NSOwner");
  NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSFirst"]);
  [nameTable setObject: firstResponder forKey: @"NSFirst"];
  NSMapInsert(objToName, (void*)firstResponder, (void*)@"NSFirst");
  if (fontManager != nil)
    {
      NSMapRemove(objToName, (void*)[nameTable objectForKey: @"NSFont"]);
      [nameTable setObject: fontManager forKey: @"NSFont"];
      NSMapInsert(objToName, (void*)fontManager, (void*)@"NSFont");
    }

  /*
   * Map all connector source and destination names to their objects.
   */
  enumerator = [connections objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSString	*name;

      name = (NSString*)[con source];
      obj = [self objectForName: name];
      [con setSource: obj];
      name = (NSString*)[con destination];
      obj = [self objectForName: name];
      [con setDestination: obj];
    }

  /*
   * Restore editor links and reactivate the editors.
   */
  [connections addObjectsFromArray: savedEditors];
  enumerator = [savedEditors objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      [[con destination] activate];
    }
  [savedEditors removeAllObjects];
}

- (void) handleNotification: (NSNotification*)aNotification
{
  NSString	*name = [aNotification name];

  if ([name isEqual: NSWindowWillCloseNotification] == YES)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSEnumerator	*enumerator;
      id		obj;

      [nc postNotificationName: IBWillCloseDocumentNotification
			object: self];

      enumerator = [nameTable objectEnumerator];
      while ((obj = [enumerator nextObject]) != nil)
	{
	  if ([obj isKindOfClass: [NSMenu class]] == YES)
	    {
	      if ([[obj window] isVisible] == YES)
		{
		  [hidden addObject: obj];
		  [obj close];
		}
	    }
	  else if ([obj isKindOfClass: [NSWindow class]] == YES)
	    {
	      if ([obj isVisible] == YES)
		{
		  [hidden addObject: obj];
		  [obj orderOut: self];
		}
	    }
	}

      [self setDocumentActive: NO];
    }
  else if ([name isEqual: NSWindowDidBecomeKeyNotification] == YES)
    {
      [self setDocumentActive: YES];
    }
  else if ([name isEqual: NSWindowWillMiniaturizeNotification] == YES)
    {
      [self setDocumentActive: NO];
    }
  else if ([name isEqual: NSWindowDidDeminiaturizeNotification] == YES)
    {
      [self setDocumentActive: YES];
    }
  else if ([name isEqual: IBWillBeginTestingInterfaceNotification] == YES)
    {
      if ([window isVisible] == YES)
	{
	  [hidden addObject: window];
	  [window setExcludedFromWindowsMenu: YES];
	  [window orderOut: self];
	}
      if ([(id<IB>)NSApp activeDocument] == self)
	{
	  NSEnumerator	*enumerator;
	  id		obj;

	  enumerator = [nameTable objectEnumerator];
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  if ([[obj window] isVisible] == YES)
		    {
		      [hidden addObject: obj];
		      [obj close];
		    }
		}
	      else if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  if ([obj isVisible] == YES)
		    {
		      [hidden addObject: obj];
		      [obj orderOut: self];
		    }
		}
	    }
	}
    }
  else if ([name isEqual: IBWillEndTestingInterfaceNotification] == YES)
    {
      if ([hidden count] > 0)
	{
	  NSEnumerator	*enumerator;
	  id		obj;

	  enumerator = [hidden objectEnumerator];
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  [obj display];
		}
	      else if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderFront: self];
		}
	    }
	  [hidden removeAllObjects];
	  [window setExcludedFromWindowsMenu: NO];
	}
    }
  else if ([name isEqual: IBClassNameChangedNotification] == YES)
    {
      if ([aNotification object] == classManager) [classesView reloadData];
    }
}

- (id) init 
{
  self = [super init];
  if (self != nil)
    {
      NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
      NSRect			winrect = NSMakeRect(100,100,340,252);
      NSRect			selectionRect = {{0, 188}, {240, 64}};
      NSRect			scrollRect = {{0, 0}, {340, 188}};
      NSRect			mainRect = {{20, 0}, {320, 188}};
      NSImage			*image;
      NSButtonCell		*cell;
      NSTableColumn             *tableColumn;
      unsigned			style;

      classManager = [[GormClassManager alloc] init]; 
      classEditor = [[GormClassEditor alloc] initWithDocument: self];
      /*
       * NB. We must retain the map values (object names) as the nameTable
       * may not hold identical name objects, but merely equal strings.
       */
      objToName = NSCreateMapTableWithZone(NSNonRetainedObjectMapKeyCallBacks,
	NSObjectMapValueCallBacks, 128, [self zone]);

      savedEditors = [NSMutableArray new];

      style = NSTitledWindowMask | NSClosableWindowMask
	| NSResizableWindowMask | NSMiniaturizableWindowMask;
      window = [[NSWindow alloc] initWithContentRect: winrect
					   styleMask: style 
					     backing: NSBackingStoreRetained
					       defer: NO];
      [window setMinSize: [window frame].size];
      [window setTitle: @"UNTITLED"];

      [window setDelegate: self];

      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowWillCloseNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowDidBecomeKeyNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowWillMiniaturizeNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: NSWindowDidDeminiaturizeNotification
	       object: window];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBClassNameChangedNotification
	       object: nil];

      selectionView = [[NSMatrix alloc] initWithFrame: selectionRect
						 mode: NSRadioModeMatrix
					    cellClass: [NSButtonCell class]
					 numberOfRows: 1
				      numberOfColumns: 4];
      [selectionView setTarget: self];
      [selectionView setAction: @selector(changeView:)];
      [selectionView setAutosizesCells: NO];
      [selectionView setCellSize: NSMakeSize(64,64)];
      [selectionView setIntercellSpacing: NSMakeSize(28,0)];
      [selectionView setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];

      if ((image = objectsImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 0];
	  [cell setTag: 0];
	  [cell setImage: image];
	  [cell setTitle: @"Objects"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = imagesImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 1];
	  [cell setTag: 1];
	  [cell setImage: image];
	  [cell setTitle: @"Images"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = soundsImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 2];
	  [cell setTag: 2];
	  [cell setImage: image];
	  [cell setTitle: @"Sounds"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      if ((image = classesImage) != nil)
	{
	  cell = [selectionView cellAtRow: 0 column: 3];
	  [cell setTag: 3];
	  [cell setImage: image];
	  [cell setTitle: @"Classes"];
	  [cell setBordered: NO];
	  [cell setAlignment: NSCenterTextAlignment];
	  [cell setImagePosition: NSImageAbove];
	}

      [[window contentView] addSubview: selectionView];
      RELEASE(selectionView);

      selectionBox = [[NSBox alloc] initWithFrame: scrollRect];
      [selectionBox setTitlePosition: NSNoTitle];
      [selectionBox setBorderType: NSNoBorder];
      [selectionBox setAutoresizingMask:
	NSViewHeightSizable|NSViewWidthSizable];
      [[window contentView] addSubview: selectionBox];
      RELEASE(selectionBox);

      scrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
      [scrollView setHasVerticalScroller: YES];
      [scrollView setHasHorizontalScroller: NO];
      [scrollView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];

      mainRect.origin = NSMakePoint(0,0);
      objectsView = [[GormObjectEditor alloc] initWithObject: nil
						  inDocument: self];
      AUTORELEASE(objectsView);
      [objectsView setFrame: mainRect];
      [objectsView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
      [scrollView setDocumentView: objectsView];
      RELEASE(objectsView);

      classesScrollView = [[NSScrollView alloc] initWithFrame: scrollRect];
      [classesScrollView setHasVerticalScroller: YES];
      [classesScrollView setHasHorizontalScroller: NO];
      [classesScrollView setAutoresizingMask:
	NSViewHeightSizable|NSViewWidthSizable];

      mainRect.origin = NSMakePoint(0,0);
      classesView = [[NSTableView alloc] initWithFrame: mainRect];
      [classesView setMenu: [(Gorm*)NSApp classMenu]]; 
      [classesView setDataSource: self];
      [classesView setAutoresizesAllColumnsToFit: YES];
      [classesView setAllowsColumnResizing: NO];
      [classesScrollView setDocumentView: classesView];
      RELEASE(classesView);

      tableColumn = [[NSTableColumn alloc] initWithIdentifier: @"classes"];
      [[tableColumn headerCell] setStringValue: @"Classes"];
      [tableColumn setMinWidth: 250];
      [tableColumn setResizable: YES];
      [tableColumn setEditable: YES];
      [classesView addTableColumn: tableColumn];
      RELEASE(tableColumn);

      tableColumn = [[NSTableColumn alloc] initWithIdentifier: @"outlets"];
      [[tableColumn headerCell] setStringValue: @"O"];
      [tableColumn setMinWidth: 25];
      [tableColumn setResizable: NO];
      [classesView addTableColumn: tableColumn];
      RELEASE(tableColumn);

      tableColumn = [[NSTableColumn alloc] initWithIdentifier: @"actions"];
      [[tableColumn headerCell] setStringValue: @"A"];
      [tableColumn setMinWidth: 25];
      [tableColumn setResizable: NO];
      [classesView addTableColumn: tableColumn];
      RELEASE(tableColumn);

      [classesView setFrame: mainRect];

      [selectionBox setContentView: scrollView];

      /*
       * Set up special-case dummy objects and add them to the objects view.
       */
      filesOwner = [GormFilesOwner new];
      [self setName: @"NSOwner" forObject: filesOwner];
      [objectsView addObject: filesOwner];
      firstResponder = [GormFirstResponder new];
      [self setName: @"NSFirst" forObject: firstResponder];
      [objectsView addObject: firstResponder];
      fontManager = [GormFontManager new];
      [self setName: @"NSFont" forObject: fontManager];

      /*
       * Set image for this miniwindow.
       */
      [window setMiniwindowImage: [(id)filesOwner imageForViewer]];

      hidden = [NSMutableArray new];
      /*
       * Watch to see when we are starting/ending testing.
       */
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBWillBeginTestingInterfaceNotification
	       object: nil];
      [nc addObserver: self
	     selector: @selector(handleNotification:)
		 name: IBWillEndTestingInterfaceNotification
	       object: nil];
    }
  return self;
}

- (id) instantiateClass: (id)sender
{
  NSLog(@"document -> instantiateClass: ");

  if ([[selectionView selectedCell] tag] == 3)
    {
      int i = [classesView selectedRow];
      id classNames = [classManager allClassNames];

      if (i >= 0 && i < [classNames count])
	{
	  id className = [classNames objectAtIndex: i];
	  GSNibItem *item = 
	    [[GormObjectProxy alloc] initWithClassName: className
						 frame: NSMakeRect(0,0,0,0)];

	  [self setName: nil forObject: item];
	  [self attachObject: item toParent: nil];
	  //[self setObject: item isVisibleAtLaunch: NO];
	  RELEASE(item);

	  [selectionView selectCellWithTag: 0];
	  [selectionBox setContentView: scrollView];
	}

    }

  return nil;
}

- (BOOL) isActive
{
  return isActive;
}

- (NSString*) nameForObject: (id)anObject
{
  return (NSString*)NSMapGet(objToName, (void*)anObject);
}

- (id) objectForName: (NSString*)name
{
  return [nameTable objectForKey: name];
}

- (BOOL) objectIsVisibleAtLaunch: (id)anObject
{
  return [[nameTable objectForKey: @"NSVisible"] containsObject: anObject];
}

- (NSArray*) objects
{
  return [nameTable allValues];
}

/*
 * NB. This assumes we have an empty document to start with - the loaded
 * document is merged in to it.
 */
- (id) loadDocument: (NSString*)aFile
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  NSMutableDictionary	*nt;
  NSData		*data;
  NSUnarchiver		*u;
  GSNibContainer	*c;
  NSEnumerator		*enumerator;
  id <IBConnectors>	con;
  NSString		*name;
  NSString              *ownerClass;

  data = [NSData dataWithContentsOfFile: aFile];
  if (data == nil)
    {
      NSRunAlertPanel(NULL,
	[NSString stringWithFormat: @"Could not read '%@' data", aFile],
	 @"OK", NULL, NULL);
      return nil;
    }

  /*
   * Create an unarchiver, and use it to unarchive the nib file while
   * handling class replacement so that standard objects understood
   * by the gui library are converted to their Gorm internal equivalents.
   */
  u = AUTORELEASE([[NSUnarchiver alloc] initForReadingWithData: data]);
  [u decodeClassName: @"GSNibContainer" asClassName: @"GormDocument"];
  [u decodeClassName: @"GSNibItem" asClassName: @"GormObjectProxy"];
  [u decodeClassName: @"GSCustomView" asClassName: @"GormCustomView"];
  [u decodeClassName: @"NSWindow" asClassName: @"GormNSWindow"];
  [u decodeClassName: @"NSBrowser" asClassName: @"GormNSBrowser"];

  c = [u decodeObject];
  if (c == nil || [c isKindOfClass: [GSNibContainer class]] == NO)
    {
      NSRunAlertPanel(NULL, @"Could not unarchive document data", 
		       @"OK", NULL, NULL);
      return nil;
    }
  if (![classManager loadFromFile: [[aFile stringByDeletingPathExtension] 
				   stringByAppendingPathExtension: @"classes"]])
    {
      NSRunAlertPanel(NULL, @"Could not open the associated classes file.\n"
	@"You won't be able to edit connections on custom classes", 
	@"OK", NULL, NULL);
    }
  [classesView reloadData];

  /*
   * In the newly loaded nib container, we change all the connectors
   * to hold the objects rather than their names (using our own dummy
   * object as the 'NSOwner'.
   */
  ownerClass = [[c nameTable] objectForKey: @"NSOwner"];
  if (ownerClass)
    [filesOwner setClassName: ownerClass];
  [[c nameTable] setObject: filesOwner forKey: @"NSOwner"];
  [[c nameTable] setObject: firstResponder forKey: @"NSFirst"];

  nt = [c nameTable];
  //NSLog(@"nt : %@", nt);
  //NSLog(@"--------------");
  //NSLog(@"con : %@", [c connections]);
  enumerator = [[c connections] objectEnumerator];
  while ((con = [enumerator nextObject]) != nil)
    {
      NSString  *name;
      id        obj;

      name = (NSString*)[con source];
      obj = [nt objectForKey: name];
      [con setSource: obj];
      name = (NSString*)[con destination];
      obj = [nt objectForKey: name];
      [con setDestination: obj];
    }

  /*
   * Now we merge the objects from the nib container into our own data
   * structures, taking care not to overwrite our NSOwner and NSFirst.
   */
  [nt removeObjectForKey: @"NSOwner"];
  [nt removeObjectForKey: @"NSFirst"];
  [connections addObjectsFromArray: [c connections]];
  [nameTable addEntriesFromDictionary: nt];

  /*
   * Now we build our reverse mapping information and other initialisation
   */
  NSResetMapTable(objToName);
  NSMapInsert(objToName, (void*)filesOwner, (void*)@"NSOwner");
  NSMapInsert(objToName, (void*)firstResponder, (void*)@"NSFirst");
  enumerator = [nameTable keyEnumerator];
  while ((name = [enumerator nextObject]) != nil)
    {
      id	obj = [nameTable objectForKey: name];

      NSMapInsert(objToName, (void*)obj, (void*)name);
      if ([obj isKindOfClass: [NSMenu class]] == YES)
	{
	  [objectsView addObject: obj];
	  if ([name isEqual: @"NSMenu"] == YES)
	    {
	      NSRect	frame = [[NSScreen mainScreen] frame];

	      [[obj window] setFrameTopLeftPoint:
		NSMakePoint(1, frame.size.height-200)];
	      [[self openEditorForObject: obj] activate];
	    }
	}
      else if ([obj isKindOfClass: [NSWindow class]] == YES)
	{
	  [objectsView addObject: obj];
	  [[self openEditorForObject: obj] activate];
	}
      else if ([obj isKindOfClass: [GSNibItem class]] == YES
	       && [obj isKindOfClass: [GormCustomView class]] == NO)
	{
	  [objectsView addObject: obj];
	  //[[self openEditorForObject: obj] activate];
	}
    }

  /*
   * Finally, we set our new file name
   */
  ASSIGN(documentPath, aFile);
  [window setTitleWithRepresentedFilename: documentPath];
  [nc postNotificationName: IBDidOpenDocumentNotification
		    object: self];
  return self;
}

/*
 * NB. This assumes we have an empty document to start with - the loaded
 * document is merged in to it.
 */
- (id) openDocument: (id)sender
{
  NSArray	*fileTypes;
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  if ([[NSUserDefaults standardUserDefaults] boolForKey: @"OpenNibs"] == YES)
    {
      fileTypes = [NSArray arrayWithObjects: @"gorm", @"nib", nil];
    }
  else
    {
      fileTypes = [NSArray arrayWithObjects: @"gorm", nil];
    }
  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      return [self loadDocument: [oPanel filename]];
    }
  return nil;		/* Failed	*/
}

- (id<IBEditors>) openEditorForObject: (id)anObject
{
  id<IBEditors>	e = [self editorForObject: anObject create: YES];
  id<IBEditors>	p = [self parentEditorForEditor: e];
  
  if (p != nil && p != objectsView)
    {
      [self openEditorForObject: [p editedObject]];
    }
  [e orderFront];
  [[e window] makeKeyAndOrderFront: self];
  return e;
}

- (id<IBEditors>) parentEditorForEditor: (id<IBEditors>)anEditor
{
  NSArray		*links;
  GormObjectToEditor	*con;

  links = [self connectorsForSource: anEditor
			    ofClass: [GormObjectToEditor class]];
  con = [links lastObject];
  return [con destination];
}

- (id) parentOfObject: (id)anObject
{
  NSArray		*old;
  id<IBConnectors>	con;

  old = [self connectorsForSource: anObject ofClass: [NSNibConnector class]];
  con = [old lastObject];
  if ([con destination] != filesOwner && [con destination] != firstResponder)
    {
      return [con destination];
    }
  return nil;
}

- (NSArray*) pasteType: (NSString*)aType
        fromPasteboard: (NSPasteboard*)aPasteboard
                parent: (id)parent
{
  NSData	*data;
  NSArray	*objects;
  NSEnumerator	*enumerator;
  NSPoint	filePoint;
  NSPoint	screenPoint;

  data = [aPasteboard dataForType: aType];
  if (data == nil)
    {
      NSLog(@"Pasteboard %@ doesn't contain data of %@", aPasteboard, aType);
      return nil;
    }
  objects = [NSUnarchiver unarchiveObjectWithData: data];
  enumerator = [objects objectEnumerator];
  filePoint = [window mouseLocationOutsideOfEventStream];
  screenPoint = [window convertBaseToScreen: filePoint];

  /*
   * Windows and panels are a special case - for a multiple window paste,
   * the windows need to be positioned so they are not on top of each other.
   */
  if ([aType isEqualToString: IBWindowPboardType] == YES)
    {
      NSWindow	*win;

      while ((win = [enumerator nextObject]) != nil)
	{
	  [win setFrameTopLeftPoint: screenPoint];
	  screenPoint.x += 10;
	  screenPoint.y -= 10;
	}
    }
  [self attachObjects: objects toParent: parent];
  [self touch];
  return objects;
}

- (void) removeConnector: (id<IBConnectors>)aConnector
{
  [connections removeObjectIdenticalTo: aConnector];
}

- (void) resignSelectionForEditor: (id<IBEditors>)editor
{
  NSEnumerator		*enumerator = [connections objectEnumerator];
  Class			editClass = [GormObjectToEditor class];
  id<IBConnectors>	c;

  /*
   * This editor wants to give up the selection.  Go through all the known
   * editors (with links in the connections array) and try to find one
   * that wants to take over the selection.  Activate whatever editor we
   * find (if any).
   */
  while ((c = [enumerator nextObject]) != nil)
    {
      if ([c class] == editClass)
	{
	  id<IBEditors>	e = [c destination];

	  if (e != editor && [e wantsSelection] == YES)
	    {
	      [e activate];
	      [self setSelectionFromEditor: e];
	      return;
	    }
	}
    }
  /*
   * No editor available to take the selection - set a nil owner.
   */
  [self setSelectionFromEditor: nil];
}

- (void) setupDefaults: (NSString*)type
{
  if (hasSetDefaults == YES)
    {
      return;
    }
  hasSetDefaults = YES;
  if ([type isEqual: @"Application"] == YES)
    {
      NSMenu	*aMenu = [NSMenu new];
      NSWindow	*aWindow;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask
                        | NSResizableWindowMask | NSMiniaturizableWindowMask;

      aWindow = [[NSWindow allocSubstitute]
		  initWithContentRect: NSMakeRect(0,0,600, 400)
		  styleMask: style
		  backing: NSBackingStoreRetained
		  defer: NO];
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: @"My Window"];
      [self setName: @"My Window" forObject: aWindow];
      [self attachObject: aWindow toParent: nil];
      [self setObject: aWindow isVisibleAtLaunch: YES];
      RELEASE(aWindow);

      [aMenu setTitle: @"Main Menu"];
      [aMenu addItemWithTitle: @"Hide" 
		       action: @selector(hide:)
		keyEquivalent: @"h"];	
      [aMenu addItemWithTitle: @"Quit" 
		       action: @selector(terminate:)
		keyEquivalent: @"q"];	
      [self setName: @"NSMenu" forObject: aMenu];
      [self attachObject: aMenu toParent: nil];
      [[aMenu window] setFrameTopLeftPoint:
	NSMakePoint(1, frame.size.height-200)];
      RELEASE(aMenu);
    }
  else if ([type isEqual: @"Inspector"] == YES)
    {
      NSWindow	*aWindow;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask;

      aWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,IVW,IVH)
					    styleMask: style
					      backing: NSBackingStoreRetained
					        defer: NO];
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: @"Inspector Window"];
      [self setName: @"InspectorWin" forObject: aWindow];
      [self attachObject: aWindow toParent: nil];
      RELEASE(aWindow);
    }
  else if ([type isEqual: @"Palette"] == YES)
    {
      NSWindow	*aWindow;
      NSRect	frame = [[NSScreen mainScreen] frame];
      unsigned	style = NSTitledWindowMask | NSClosableWindowMask;

      aWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,272,192)
					    styleMask: style
					      backing: NSBackingStoreRetained
					        defer: NO];
      [aWindow setFrameTopLeftPoint:
	NSMakePoint(220, frame.size.height-100)];
      [aWindow setTitle: @"Palette Window"];
      [self setName: @"PaletteWin" forObject: aWindow];
      [self attachObject: aWindow toParent: nil];
      RELEASE(aWindow);
    }
}

- (void) setName: (NSString*)aName forObject: (id)object
{
  id		oldObject;
  NSString	*oldName;

  if (object == nil)
    {
      NSLog(@"Attempt to set name for nil object");
      return;
    }
  if (aName == nil)
    {
      /*
       * No name given - so we must generate one unless we already have one.
       */
      oldName = [self nameForObject: object];
      if (oldName == nil)
	{
	  NSString	*base;
	  unsigned	i = 0;

	  /*
	   * Generate a sensible name for the object based on its class.
	   */
	  if ([object isKindOfClass: [GSNibItem class]])
	    {
	      // use the actual class name for proxies
	      base = [(id)object className];
	    }
	  else
	    {
	      base = NSStringFromClass([object class]);
	    }
	  if ([base hasPrefix: @"NS"] || [base hasPrefix: @"GS"])
	    {
	      base = [base substringFromIndex: 2];
	    }
	  aName = base;
	  while ([nameTable objectForKey: aName] != nil)
	    {
	      aName = [base stringByAppendingFormat: @"%u", ++i];
	    }
	}
      else
	{
	  return;	/* Already named ... nothing to do */
	}
    }
  else
    {
      oldObject = [nameTable objectForKey: aName];
      if (oldObject != nil)
	{
	  NSLog(@"Attempt to re-use name '%@'", aName);
	  return;
	}
      oldName = [self nameForObject: object];
      if (oldName != nil)
	{
	  if ([oldName isEqual: aName] == YES)
	    {
	      return;	/* Already have this name ... nothing to do */
	    }
	  RETAIN(object);
          AUTORELEASE(object);
	  [nameTable removeObjectForKey: oldName];
	  NSMapRemove(objToName, (void*)object);
	}
    }
  aName = [aName copy];	/* Make sure it's immutable	*/
  [nameTable setObject: object forKey: aName];
  NSMapInsert(objToName, (void*)object, (void*)aName);
  RELEASE(aName);
  if (oldName != nil)
    {
      [nameTable removeObjectForKey: oldName];
    }
  if ([objectsView containsObject: object] == YES)
    {
      [objectsView refreshCells];
    }
}

- (void) setObject: (id)anObject isVisibleAtLaunch: (BOOL)flag
{
  NSMutableArray	*a = [nameTable objectForKey: @"NSVisible"];

  if (flag == YES)
    {
      if (a == nil)
	{
	  a = [NSMutableArray new];
	  [nameTable setObject: a forKey: @"NSVisible"];
	  RELEASE(a);
	}
      if ([a containsObject: anObject] == NO)
	{
	  [a addObject: anObject];
	}
    }
  else
    {
      [a removeObject: anObject];
    }
}

/*
 * To revert to a saved version, we actually load a new document and
 * close the original document, returning the id of the new document.
 */
- (id) revertDocument: (id)sender
{
  GormDocument	*reverted = AUTORELEASE([GormDocument new]);

  if ([reverted loadDocument: documentPath] != nil)
    {
      NSRect	frame = [window frame];

      [window setReleasedWhenClosed: YES];
      [window close];
      [[reverted window] setFrame: frame display: YES];
      return reverted;
    }
  return nil;
}

- (id) saveAsDocument: (id)sender
{
  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
  NSSavePanel		*sp;
  int			result;

  sp = [NSSavePanel savePanel];

  if ([defs boolForKey: @"SaveAsNib"] == YES)
    {
      [sp setRequiredFileType: @"nib"];
    }
  else
    {
      [sp setRequiredFileType: @"gorm"];
    }

  result = [sp runModalForDirectory: NSHomeDirectory() file: @""];

  if (result == NSOKButton)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*path = [sp filename];
      NSString		*old = documentPath;
      id		retval;

      if ([path isEqual: documentPath] == NO
	&& [mgr fileExistsAtPath: path] == YES)
	{
	  if (NSRunAlertPanel(NULL, @"A document with that name exists", 
	    @"Replace", @"Cancel", NULL) != NSAlertDefaultReturn)
	    {
	      return nil;
	    }
	  else
	    {
	      NSString	*bPath = [path stringByAppendingString: @"~"];

	      [mgr removeFileAtPath: bPath handler: nil];
	      [mgr movePath: path toPath: bPath handler: nil];
	    }
	}
      documentPath = RETAIN(path);
      retval = [self saveDocument: sender];
      if (retval == nil)
	{
	  RELEASE(documentPath);
	  documentPath = old;
	}
      else
	{
	  RELEASE(old);
	  /* FIXME - need to update files window title etc */
	  return self;
	}
    }
  return nil;
}

- (id) saveDocument: (id)sender
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  BOOL			archiveResult;
  NSArchiver            *archiver;
  NSMutableData         *archiverData;

  if (documentPath == nil)
    {
      return [self saveAsDocument: sender];
    }

  [nc postNotificationName: IBWillSaveDocumentNotification
		    object: self];

  [self beginArchiving];

  //NSLog(@"nametable : %@", nameTable);
  //NSLog(@"connections : %@", connections);

  archiverData = [NSMutableData dataWithCapacity: 0];
  archiver = [[NSArchiver alloc] initForWritingWithMutableData: archiverData];
  [archiver encodeClassName: @"GormObjectProxy" intoClassName: @"GSNibItem"];
  [archiver encodeClassName: @"GormCustomView" 
	      intoClassName: @"GSCustomView"];
  [archiver encodeClassName: @"GormNSWindow" 
	      intoClassName: @"NSWindow"];
  [archiver encodeClassName: @"GormNSBrowser" 
	      intoClassName: @"NSBrowser"];
  [archiver encodeRootObject: self];
  archiveResult = [archiverData writeToFile: documentPath atomically: YES]; 
  //archiveResult = [NSArchiver archiveRootObject: self toFile: documentPath];
  RELEASE(archiver);
  if (archiveResult) 
    archiveResult = [classManager saveToFile:
      [[documentPath stringByDeletingPathExtension] 
      stringByAppendingPathExtension: @"classes"]];

  [self endArchiving];

  if (archiveResult == NO)
    {
      NSRunAlertPanel(NULL, @"Could not save document", 
		       @"OK", NULL, NULL);
      return nil;
    }

  [window setDocumentEdited: NO];
  [window setTitleWithRepresentedFilename: documentPath];

  [nc postNotificationName: IBDidSaveDocumentNotification
		    object: self];
  return self;
}

- (void) setDocumentActive: (BOOL)flag
{
  if (flag != isActive)
    {
      NSEnumerator	*enumerator;
      id		obj;

      enumerator = [nameTable objectEnumerator];
      if (flag == YES)
	{
	  [(GormDocument*)[(id<IB>)NSApp activeDocument] setDocumentActive: NO];
	  isActive = YES;
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderFront: self];
		}
	      else if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  [obj display];
		}
	    }
	}
      else
	{
	  isActive = NO;
	  while ((obj = [enumerator nextObject]) != nil)
	    {
	      if ([obj isKindOfClass: [NSWindow class]] == YES)
		{
		  [obj orderOut: self];
		}
	      else if ([obj isKindOfClass: [NSMenu class]] == YES)
		{
		  [obj close];
		}
	    }
	}
    }
}

- (void) setSelectionFromEditor: (id<IBEditors>)anEditor
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName: IBSelectionChangedNotification
		    object: anEditor];
}

- (void) touch
{
  [window setDocumentEdited: YES];
}

- (NSWindow*) windowAndRect: (NSRect*)r forObject: (id)object
{
  /*
   * Get the window and rectangle for which link markup should be drawn.
   */
  if ([objectsView containsObject: object] == YES)
    {
      /*
       * objects that exist in the document objects view must have their link
       * markup drawn there, so we ask the view for the required rectangle.
       */
      *r = [objectsView rectForObject: object];
      return [objectsView window];
    }
  else if ([object isKindOfClass: [NSMenuItem class]] == YES)
    {
      NSArray	*links;
      NSMenu	*menu;
      id	editor;

      /*
       * Menu items must have their markup drawn in the window of the
       * editor of the parent menu.
       */
      links = [self connectorsForSource: object
				ofClass: [NSNibConnector class]];
      menu = [[links lastObject] destination];
      editor = [self editorForObject: menu create: NO];
      *r = [editor rectForObject: object];
      return [editor window];
    }
  else if ([object isKindOfClass: [NSView class]] == YES)
    {
      /*
       * Nowmal view objects just get link markup drawn on them.
       */
      *r = [object convertRect: [object bounds] toView: nil];
      return [object window];
    }
  else
    {
      *r = NSZeroRect;
      return nil;
    }
}

- (NSWindow*) window
{
  return window;
}

- (BOOL) windowShouldClose: (id)sender
{
  if ([window isDocumentEdited] == YES)
    {
      NSString	*msg;
      int	result;

      if (documentPath == nil)
	{
	  msg = @"Document 'UNTITLED' has been modified";
	}
      else
	{
	  msg = [NSString stringWithFormat: @"Document '%@' has been modified",
	    [documentPath lastPathComponent]];
	}
      result = NSRunAlertPanel(NULL, msg, @"Save", @"Cancel", @"Don't Save");
      if (result == NSAlertAlternateReturn)
	{
	  return NO;
	}
      else if (result != NSAlertOtherReturn)
	{
	  [self saveDocument: self];
	}
    }
  return YES;
}

//--- NSTableView dataSource ---
- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
  if (aTableView == classesView)
    {
      return [[classManager allClassNames] count];
    }
  return 0;
}

- (id) tableView: (NSTableView *)aTableView 
objectValueForTableColumn: (NSTableColumn *)aTableColumn 
	     row: (int)rowIndex
{
  if (aTableView == classesView)
    {
      id identifier = [aTableColumn identifier];
      id className = @"";
      id classNames = [classManager allClassNames];
      
      if (rowIndex >= 0 && rowIndex < [classNames count])
	{
	  className = [classNames objectAtIndex: rowIndex];
	}

      if ([identifier isEqualToString: @"classes"])
	{
	  return className;
	}
      else if ([identifier isEqualToString: @"outlets"])
	{
	  return [NSString stringWithFormat: @"%d",
	    [[classManager allOutletsForClassNamed: className] count]];
	}
      else if ([identifier isEqualToString: @"actions"])
	{
	  return [NSString stringWithFormat: @"%d",
	    [[classManager allActionsForClassNamed: className] count]];
	}
    }
  return @"";
}

- (void) tableView: (NSTableView *)aTableView 
    setObjectValue: (id)anObject 
    forTableColumn: (NSTableColumn *)aTableColumn
	       row: (int)rowIndex
{

}
@end

