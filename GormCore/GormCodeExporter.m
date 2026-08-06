/* GormCodeExporter.m
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

#import "GormCodeExporter.h"
#import "GormClassManager.h"
#import "GormDocument.h"
#import "GormFunctions.h"

@interface GormCodeExporter (Private)
- (void) _appendPreambleToString: (NSMutableString *)source
                customClassNames: (NSArray *)customClassNames
                       headerName: (NSString *)headerName;
- (void) _appendObject: (id)object
              toString: (NSMutableString *)source
              emitted: (NSMutableSet *)emitted
                queued: (NSMutableArray *)queued
              varNames: (NSMutableDictionary *)varNames;
- (void) _appendRelationshipsToString: (NSMutableString *)source
                              varNames: (NSMutableDictionary *)varNames;
- (void) _appendConnectionsToString: (NSMutableString *)source
                           varNames: (NSMutableDictionary *)varNames;
- (void) _appendResultToString: (NSMutableString *)source
                      varNames: (NSMutableDictionary *)varNames;
- (void) _appendLoadHelperToString: (NSMutableString *)source;
- (void) _queueChildrenOfObject: (id)object
                         queued: (NSMutableArray *)queued;
- (NSString *) _variableNameForObject: (id)object
                             varNames: (NSMutableDictionary *)varNames;
- (NSString *) _classNameForObject: (id)object;
- (NSArray *) _customClassNamesForCodeRepresentation;
- (NSString *) _uniqueVariableNameFromName: (NSString *)name
                                  fallback: (NSString *)fallback
                                 usedNames: (NSMutableSet *)usedNames;
- (NSString *) _identifierFromName: (NSString *)name fallback: (NSString *)fallback;
- (NSSet *) _reservedVariableNames;
- (NSString *) _escapedString: (NSString *)string;
- (NSString *) _headerGuardForName: (NSString *)name;
- (NSString *) _rectString: (NSRect)rect;
- (NSString *) _pointString: (NSPoint)point;
- (NSString *) _sizeString: (NSSize)size;
- (NSString *) _keyForObject: (id)object;
- (BOOL) _objectIsOwner: (id)object;
@end

@implementation GormCodeExporter

+ (instancetype) exporterWithDocument: (GormDocument *)document
{
  return AUTORELEASE([[self alloc] initWithDocument: document]);
}

- (instancetype) initWithDocument: (GormDocument *)document
{
  self = [super init];
  if (self != nil)
    {
      ASSIGN(_document, document);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(_document);
  [super dealloc];
}

- (NSString *) codeRepresentation
{
  return [self codeRepresentationWithHeaderName: nil];
}

- (NSString *) codeRepresentationWithHeaderName: (NSString *)headerName
{
  NSMutableString *source = [NSMutableString string];
  NSMutableArray *queued = [NSMutableArray array];
  NSMutableSet *emitted = [NSMutableSet set];
  NSMutableDictionary *varNames = [NSMutableDictionary dictionary];
  NSArray *customClassNames = nil;
  NSEnumerator *topEnum = [[_document topLevelObjects] objectEnumerator];
  NSEnumerator *objectEnum = nil;
  NSEnumerator *connectionEnum = nil;
  id object = nil;
  id<IBConnectors> connection = nil;

  customClassNames = [self _customClassNamesForCodeRepresentation];
  [self _appendPreambleToString: source
               customClassNames: customClassNames
                      headerName: headerName];

  while ((object = [topEnum nextObject]) != nil)
    {
      [queued addObject: object];
    }
  objectEnum = [[_document objects] objectEnumerator];
  while ((object = [objectEnum nextObject]) != nil)
    {
      [queued addObject: object];
    }
  connectionEnum = [[_document connections] objectEnumerator];
  while ((connection = [connectionEnum nextObject]) != nil)
    {
      if ([connection source] != nil)
        {
          [queued addObject: [connection source]];
        }
      if ([connection destination] != nil)
        {
          [queued addObject: [connection destination]];
        }
    }

  while ([queued count] > 0)
    {
      object = [queued objectAtIndex: 0];
      [queued removeObjectAtIndex: 0];
      [self _appendObject: object
                 toString: source
                  emitted: emitted
                   queued: queued
                 varNames: varNames];
    }

  [self _appendRelationshipsToString: source varNames: varNames];
  [self _appendConnectionsToString: source varNames: varNames];
  [self _appendResultToString: source varNames: varNames];
  [source appendString: @"}\n"];
  [self _appendLoadHelperToString: source];

  return source;
}

- (BOOL) exportCodeToFile: (NSString *)filename
{
  NSString *headerName = [[[filename lastPathComponent]
    stringByDeletingPathExtension] stringByAppendingPathExtension: @"h"];

  return [[self codeRepresentationWithHeaderName: headerName]
    writeToFile: filename atomically: YES];
}

- (BOOL) exportCodeToFile: (NSString *)sourceFilename
             headerToFile: (NSString *)headerFilename
{
  NSString *headerName = [headerFilename lastPathComponent];
  BOOL sourceSaved = [[self codeRepresentationWithHeaderName: headerName]
    writeToFile: sourceFilename atomically: YES];
  BOOL headerSaved = [[self headerRepresentationWithName:
    [[headerName stringByDeletingPathExtension] lastPathComponent]]
    writeToFile: headerFilename atomically: YES];

  return (sourceSaved && headerSaved);
}

- (NSString *) headerRepresentationWithName: (NSString *)name
{
  NSMutableString *header = [NSMutableString string];
  NSString *guard = [self _headerGuardForName: name];

  [header appendFormat:
    @"#ifndef %@\n"
    @"#define %@\n\n"
    @"#import <Foundation/Foundation.h>\n\n"
    @"@class NSDictionary;\n\n"
    @"NSDictionary *GormCreateObjects(id owner);\n"
    @"NSDictionary *GormLoadGeneratedObjects(id owner);\n\n"
    @"#endif\n",
    guard, guard];

  return header;
}

- (void) _appendPreambleToString: (NSMutableString *)source
                customClassNames: (NSArray *)customClassNames
                       headerName: (NSString *)headerName
{
  NSEnumerator *classEnum = nil;
  NSString *className = nil;

  if (headerName != nil && [headerName length] > 0)
    {
      [source appendFormat: @"#import \"%@\"\n",
        [self _escapedString: headerName]];
    }
  else
    {
      [source appendString: @"#import <Foundation/Foundation.h>\n"];
    }
  [source appendString:
    @"#import <AppKit/AppKit.h>\n"
    @"#import <InterfaceBuilder/InterfaceBuilder.h>\n"];

  classEnum = [customClassNames objectEnumerator];
  while ((className = [classEnum nextObject]) != nil)
    {
      [source appendFormat: @"#import \"%@.h\"\n",
        [self _escapedString: className]];
    }

  [source appendString:
    @"\n"
    @"/* Generated by Gorm. This is a best-effort source representation of\n"
    @" * an in-memory Gorm document, not a byte-for-byte replacement for a\n"
    @" * .gorm archive. Unsupported object-specific archive state is marked\n"
    @" * with comments near the relevant object.\n"
    @" */\n"
    @"NSDictionary *GormCreateObjects(id owner)\n"
    @"{\n"
    @"  NSMutableDictionary *objects = [NSMutableDictionary dictionary];\n"
    @"  NSMutableArray *topLevelObjects = [NSMutableArray array];\n"
    @"  NSMutableArray *visibleWindows = [NSMutableArray array];\n"
    @"  NSMutableArray *deferredWindows = [NSMutableArray array];\n"
    @"  NSMutableArray *connections = [NSMutableArray array];\n\n"];
}

- (void) _appendObject: (id)object
              toString: (NSMutableString *)source
               emitted: (NSMutableSet *)emitted
                queued: (NSMutableArray *)queued
              varNames: (NSMutableDictionary *)varNames
{
  NSString *objectKey = [self _keyForObject: object];
  NSString *varName = nil;
  NSString *className = nil;

  if ([emitted containsObject: objectKey])
    {
      return;
    }

  [emitted addObject: objectKey];
  [self _queueChildrenOfObject: object queued: queued];

  varName = [self _variableNameForObject: object varNames: varNames];
  className = [self _classNameForObject: object];

  if ([self _objectIsOwner: object] == YES)
    {
      [source appendFormat:
        @"  id %@ = (owner != nil) ? owner : [[[NSApplication alloc] init] autorelease];\n",
        varName];
    }
  else if ([object isKindOfClass: [NSWindow class]])
    {
      NSWindow *window = (NSWindow *)object;
      [source appendFormat:
        @"  %@ *%@ = [[[%@ alloc] initWithContentRect: %@ styleMask: %u backing: NSBackingStoreBuffered defer: NO] autorelease];\n",
        className, varName, className, [self _rectString: [window frame]],
        (unsigned)[window styleMask]];
      if ([window title] != nil)
        {
          [source appendFormat: @"  [%@ setTitle: @\"%@\"];\n",
            varName, [self _escapedString: [window title]]];
        }
      [source appendFormat: @"  [%@ setReleasedWhenClosed: %@];\n",
        varName, [window isReleasedWhenClosed] ? @"YES" : @"NO"];
    }
  else if ([object isKindOfClass: [NSMenu class]])
    {
      NSMenu *menu = (NSMenu *)object;
      [source appendFormat: @"  %@ *%@ = [[[%@ alloc] initWithTitle: @\"%@\"] autorelease];\n",
        className, varName, className, [self _escapedString: [menu title]]];
    }
  else if ([object isKindOfClass: [NSMenuItem class]])
    {
      NSMenuItem *item = (NSMenuItem *)object;
      NSString *action = ([item action] != NULL)
        ? NSStringFromSelector([item action]) : nil;
      [source appendFormat:
        @"  %@ *%@ = [[[%@ alloc] initWithTitle: @\"%@\" action: %@ keyEquivalent: @\"%@\"] autorelease];\n",
        className, varName, className, [self _escapedString: [item title]],
        (action != nil) ? [NSString stringWithFormat: @"@selector(%@)", action] : @"NULL",
        [self _escapedString: [item keyEquivalent]]];
      [source appendFormat: @"  [%@ setEnabled: %@];\n",
        varName, [item isEnabled] ? @"YES" : @"NO"];
      if ([item tag] != 0)
        {
          [source appendFormat: @"  [%@ setTag: %d];\n", varName, (int)[item tag]];
        }
    }
  else if ([object isKindOfClass: [NSTabViewItem class]])
    {
      NSTabViewItem *item = (NSTabViewItem *)object;
      [source appendFormat: @"  %@ *%@ = [[[%@ alloc] initWithIdentifier: @\"%@\"] autorelease];\n",
        className, varName, className,
        [self _escapedString: [[item identifier] description]]];
      if ([item label] != nil)
        {
          [source appendFormat: @"  [%@ setLabel: @\"%@\"];\n",
            varName, [self _escapedString: [item label]]];
        }
    }
  else if ([object isKindOfClass: [NSView class]])
    {
      NSView *view = (NSView *)object;
      [source appendFormat: @"  %@ *%@ = [[[%@ alloc] initWithFrame: %@] autorelease];\n",
        className, varName, className, [self _rectString: [view frame]]];
      [source appendFormat: @"  [%@ setAutoresizingMask: %u];\n",
        varName, (unsigned)[view autoresizingMask]];
      if ([object respondsToSelector: @selector(setTitle:)]
          && [object respondsToSelector: @selector(title)])
        {
          NSString *title = [object title];
          if (title != nil)
            {
              [source appendFormat: @"  [%@ setTitle: @\"%@\"];\n",
                varName, [self _escapedString: title]];
            }
        }
      if ([object respondsToSelector: @selector(setStringValue:)]
          && [object respondsToSelector: @selector(stringValue)])
        {
          NSString *stringValue = [object stringValue];
          if (stringValue != nil)
            {
              [source appendFormat: @"  [%@ setStringValue: @\"%@\"];\n",
                varName, [self _escapedString: stringValue]];
            }
        }
      if ([object respondsToSelector: @selector(setTag:)])
        {
          int tag = (int)[object tag];
          if (tag != 0)
            {
              [source appendFormat: @"  [%@ setTag: %d];\n", varName, tag];
            }
        }
    }
  else if ([object isKindOfClass: [NSCell class]])
    {
      NSCell *cell = (NSCell *)object;
      [source appendFormat: @"  %@ *%@ = [[[%@ alloc] initTextCell: @\"%@\"] autorelease];\n",
        className, varName, className, [self _escapedString: [cell stringValue]]];
    }
  else
    {
      [source appendFormat: @"  %@ *%@ = [[[%@ alloc] init] autorelease];\n",
        className, varName, className];
      [source appendFormat: @"  /* %@ may need additional setup not expressible by the generic exporter. */\n",
        varName];
    }

  {
    NSString *name = [_document nameForObject: object];
    if (name != nil)
      {
        [source appendFormat: @"  [objects setObject: %@ forKey: @\"%@\"];\n",
          varName, [self _escapedString: name]];
      }
  }

  [source appendString: @"\n"];
}

- (void) _appendRelationshipsToString: (NSMutableString *)source
                              varNames: (NSMutableDictionary *)varNames
{
  NSEnumerator *topEnum = [[_document topLevelObjects] objectEnumerator];
  id object = nil;

  [source appendString: @"  /* Containment */\n"];
  while ((object = [topEnum nextObject]) != nil)
    {
      NSString *varName = [self _variableNameForObject: object varNames: varNames];

      [source appendFormat: @"  [topLevelObjects addObject: %@];\n", varName];

      if ([object isKindOfClass: [NSWindow class]])
        {
          NSView *contentView = [(NSWindow *)object contentView];
          if (contentView != nil)
            {
              [source appendFormat: @"  [%@ setContentView: %@];\n",
                varName, [self _variableNameForObject: contentView varNames: varNames]];
            }
        }
    }

  topEnum = [[_document visibleWindows] objectEnumerator];
  while ((object = [topEnum nextObject]) != nil)
    {
      [source appendFormat: @"  [visibleWindows addObject: %@];\n",
        [self _variableNameForObject: object varNames: varNames]];
    }

  if ([_document respondsToSelector: @selector(deferredWindows)])
    {
      topEnum = [[_document deferredWindows] objectEnumerator];
      while ((object = [topEnum nextObject]) != nil)
        {
          [source appendFormat: @"  [deferredWindows addObject: %@];\n",
            [self _variableNameForObject: object varNames: varNames]];
        }
    }

  topEnum = [[varNames allKeys] objectEnumerator];
  while ((object = [topEnum nextObject]) != nil)
    {
      NSValue *value = nil;
      id realObject = nil;
      NSString *parentName = nil;

      value = object;
      realObject = [value nonretainedObjectValue];
      parentName = [self _variableNameForObject: realObject varNames: varNames];

      if ([realObject isKindOfClass: [NSView class]])
        {
          NSEnumerator *subEnum = [[(NSView *)realObject subviews] objectEnumerator];
          NSView *subview = nil;
          while ((subview = [subEnum nextObject]) != nil)
            {
              [source appendFormat: @"  [%@ addSubview: %@];\n",
                parentName, [self _variableNameForObject: subview varNames: varNames]];
            }

          if ([realObject isKindOfClass: [NSScrollView class]])
            {
              NSView *documentView = [[(NSScrollView *)realObject contentView] documentView];
              if (documentView != nil)
                {
                  [source appendFormat: @"  [%@ setDocumentView: %@];\n",
                    parentName, [self _variableNameForObject: documentView varNames: varNames]];
                }
            }
        }
      else if ([realObject isKindOfClass: [NSMenu class]])
        {
          NSEnumerator *itemEnum = [[(NSMenu *)realObject itemArray] objectEnumerator];
          NSMenuItem *item = nil;
          while ((item = [itemEnum nextObject]) != nil)
            {
              [source appendFormat: @"  [%@ addItem: %@];\n",
                parentName, [self _variableNameForObject: item varNames: varNames]];
            }
        }
      else if ([realObject isKindOfClass: [NSMenuItem class]])
        {
          NSMenu *submenu = [(NSMenuItem *)realObject submenu];
          if (submenu != nil)
            {
              [source appendFormat: @"  [%@ setSubmenu: %@];\n",
                parentName, [self _variableNameForObject: submenu varNames: varNames]];
            }
        }
      else if ([realObject isKindOfClass: [NSTabView class]])
        {
          NSEnumerator *itemEnum = [[(NSTabView *)realObject tabViewItems] objectEnumerator];
          NSTabViewItem *item = nil;
          while ((item = [itemEnum nextObject]) != nil)
            {
              [source appendFormat: @"  [%@ addTabViewItem: %@];\n",
                parentName, [self _variableNameForObject: item varNames: varNames]];
            }
        }
      else if ([realObject isKindOfClass: [NSTabViewItem class]])
        {
          NSView *view = [(NSTabViewItem *)realObject view];
          if (view != nil)
            {
              [source appendFormat: @"  [%@ setView: %@];\n",
                parentName, [self _variableNameForObject: view varNames: varNames]];
            }
        }
    }
  [source appendString: @"\n"];
}

- (void) _appendConnectionsToString: (NSMutableString *)source
                           varNames: (NSMutableDictionary *)varNames
{
  NSEnumerator *connectionEnum = [[_document connections] objectEnumerator];
  id<IBConnectors> connection = nil;
  unsigned index = 0;
  NSMutableSet *usedNames = [NSMutableSet setWithArray: [varNames allValues]];
  NSMutableArray *connectionNames = [NSMutableArray array];
  NSString *connectionName = nil;

  [source appendString: @"  /* Connections */\n"];
  [usedNames unionSet: [self _reservedVariableNames]];
  while ((connection = [connectionEnum nextObject]) != nil)
    {
      id sourceObject = [connection source];
      id destinationObject = [connection destination];
      NSString *sourceName = [self _variableNameForObject: sourceObject varNames: varNames];
      NSString *destinationName = [self _variableNameForObject: destinationObject varNames: varNames];
      NSString *className = NSStringFromClass([connection class]);

      if (sourceName == nil || destinationName == nil)
        {
          [source appendFormat: @"  /* Skipped %@ connection %@ -> %@ (%@). */\n",
            className, sourceObject, destinationObject, [connection label]];
          continue;
        }

      connectionName = [self _uniqueVariableNameFromName: nil
                                                fallback: [NSString stringWithFormat: @"connection%u", index]
                                               usedNames: usedNames];
      [connectionNames addObject: connectionName];

      [source appendFormat: @"  %@ *%@ = [[[%@ alloc] init] autorelease];\n",
        className, connectionName, className];
      [source appendFormat: @"  [%@ setSource: %@];\n", connectionName, sourceName];
      [source appendFormat: @"  [%@ setDestination: %@];\n", connectionName, destinationName];
      if ([connection label] != nil)
        {
          [source appendFormat: @"  [%@ setLabel: @\"%@\"];\n",
            connectionName, [self _escapedString: [connection label]]];
        }
      [source appendFormat: @"  [connections addObject: %@];\n", connectionName];
      index++;
    }

  if ([connectionNames count] > 0)
    {
      [source appendString:
        @"\n"
        @"  NSEnumerator *connectionEnumerator = [connections objectEnumerator];\n"
        @"  id<IBConnectors> connection = nil;\n"
        @"  while ((connection = [connectionEnumerator nextObject]) != nil)\n"
        @"    {\n"
        @"      [connection establishConnection];\n"
        @"    }\n"];
    }
  [source appendString: @"\n"];
}

- (void) _appendResultToString: (NSMutableString *)source
                      varNames: (NSMutableDictionary *)varNames
{
  [source appendString:
    @"  [objects setObject: topLevelObjects forKey: @\"GormTopLevelObjects\"];\n"
    @"  [objects setObject: visibleWindows forKey: @\"GormVisibleWindows\"];\n"
    @"  [objects setObject: deferredWindows forKey: @\"GormDeferredWindows\"];\n"
    @"  [objects setObject: connections forKey: @\"GormConnections\"];\n"
    @"  return objects;\n"];
}

- (void) _appendLoadHelperToString: (NSMutableString *)source
{
  [source appendString:
    @"\n"
    @"NSDictionary *GormLoadGeneratedObjects(id owner)\n"
    @"{\n"
    @"  NSMutableDictionary *objects = [[GormCreateObjects(owner) mutableCopy] autorelease];\n"
    @"  NSArray *visibleWindows = [objects objectForKey: @\"GormVisibleWindows\"];\n"
    @"  NSEnumerator *windowEnumerator = nil;\n"
    @"  NSWindow *window = nil;\n\n"
    @"  windowEnumerator = [visibleWindows objectEnumerator];\n"
    @"  while ((window = [windowEnumerator nextObject]) != nil)\n"
    @"    {\n"
    @"      [window makeKeyAndOrderFront: owner];\n"
    @"    }\n\n"
    @"  return objects;\n"
    @"}\n"];
}

- (void) _queueChildrenOfObject: (id)object
                         queued: (NSMutableArray *)queued
{
  if ([object isKindOfClass: [NSWindow class]])
    {
      NSView *contentView = [(NSWindow *)object contentView];
      if (contentView != nil)
        {
          [queued addObject: contentView];
        }
    }
  if ([object isKindOfClass: [NSView class]])
    {
      NSEnumerator *subEnum = [[(NSView *)object subviews] objectEnumerator];
      NSView *subview = nil;
      while ((subview = [subEnum nextObject]) != nil)
        {
          [queued addObject: subview];
        }
      if ([object isKindOfClass: [NSScrollView class]])
        {
          NSView *documentView = [[(NSScrollView *)object contentView] documentView];
          if (documentView != nil)
            {
              [queued addObject: documentView];
            }
        }
    }
  if ([object isKindOfClass: [NSMenu class]])
    {
      NSEnumerator *itemEnum = [[(NSMenu *)object itemArray] objectEnumerator];
      NSMenuItem *item = nil;
      while ((item = [itemEnum nextObject]) != nil)
        {
          [queued addObject: item];
        }
    }
  if ([object isKindOfClass: [NSMenuItem class]])
    {
      NSMenu *submenu = [(NSMenuItem *)object submenu];
      if (submenu != nil)
        {
          [queued addObject: submenu];
        }
    }
  if ([object isKindOfClass: [NSTabView class]])
    {
      NSEnumerator *itemEnum = [[(NSTabView *)object tabViewItems] objectEnumerator];
      NSTabViewItem *item = nil;
      while ((item = [itemEnum nextObject]) != nil)
        {
          [queued addObject: item];
        }
    }
  if ([object isKindOfClass: [NSTabViewItem class]])
    {
      NSView *view = [(NSTabViewItem *)object view];
      if (view != nil)
        {
          [queued addObject: view];
        }
    }
}

- (NSString *) _variableNameForObject: (id)object
                             varNames: (NSMutableDictionary *)varNames
{
  NSValue *key = nil;
  NSString *result = nil;
  NSString *documentName = nil;
  NSString *fallback = nil;
  NSMutableSet *usedNames = nil;

  if (object == nil)
    {
      return nil;
    }

  key = [NSValue valueWithNonretainedObject: object];
  result = [varNames objectForKey: key];
  if (result != nil)
    {
      return result;
    }

  documentName = [_document nameForObject: object];
  fallback = [NSString stringWithFormat: @"%@%u",
    [self _classNameForObject: object], (unsigned)[varNames count]];
  usedNames = [NSMutableSet setWithArray: [varNames allValues]];
  [usedNames unionSet: [self _reservedVariableNames]];
  result = [self _uniqueVariableNameFromName: documentName
                                    fallback: fallback
                                   usedNames: usedNames];

  [varNames setObject: result forKey: key];
  return result;
}

- (NSString *) _classNameForObject: (id)object
{
  GormClassManager *classManager = [_document classManager];
  NSString *className = nil;

  if (object == nil)
    {
      return nil;
    }

  className = [classManager classNameForObject: object];
  if (className == nil || [className length] == 0)
    {
      className = NSStringFromClass([object class]);
    }

  return className;
}

- (NSArray *) _customClassNamesForCodeRepresentation
{
  GormClassManager *classManager = [_document classManager];
  NSMutableSet *classNames = [NSMutableSet set];
  NSDictionary *customInformation = [classManager customClassInformation];
  NSDictionary *customMap = [classManager customClassMap];
  NSEnumerator *nameEnum = nil;
  NSString *className = nil;
  NSArray *allClassNames = nil;
  NSMutableArray *result = nil;

  nameEnum = [[customInformation allKeys] objectEnumerator];
  while ((className = [nameEnum nextObject]) != nil)
    {
      if ([className isKindOfClass: [NSString class]]
          && [className length] > 0)
        {
          [classNames addObject: className];
        }
    }

  nameEnum = [[customMap allValues] objectEnumerator];
  while ((className = [nameEnum nextObject]) != nil)
    {
      if ([className isKindOfClass: [NSString class]]
          && [className length] > 0)
        {
          [classNames addObject: className];
        }
    }

  allClassNames = [classNames allObjects];
  result = [NSMutableArray arrayWithArray:
    [allClassNames sortedArrayUsingSelector: @selector(compare:)]];

  return result;
}

- (NSString *) _uniqueVariableNameFromName: (NSString *)name
                                  fallback: (NSString *)fallback
                                 usedNames: (NSMutableSet *)usedNames
{
  NSString *result = [self _identifierFromName: name fallback: fallback];
  unsigned suffix = 1;

  while ([usedNames containsObject: result])
    {
      result = [[self _identifierFromName: name fallback: fallback]
        stringByAppendingFormat: @"%u", suffix++];
    }

  [usedNames addObject: result];
  return result;
}

- (NSString *) _identifierFromName: (NSString *)name fallback: (NSString *)fallback
{
  NSMutableArray *tokens = [NSMutableArray array];
  NSMutableString *token = [NSMutableString string];
  NSMutableString *identifier = [NSMutableString string];
  NSString *source = (name != nil && [name length] > 0) ? name : fallback;
  unsigned i = 0;

  for (i = 0; i < [source length]; i++)
    {
      unichar ch = [source characterAtIndex: i];
      BOOL valid = ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
        || (ch >= '0' && ch <= '9'));

      if (valid == YES)
        {
          [token appendFormat: @"%C", ch];
        }
      else if ([token length] > 0)
        {
          [tokens addObject: [NSString stringWithString: token]];
          [token setString: @""];
        }
    }

  if ([token length] > 0)
    {
      [tokens addObject: [NSString stringWithString: token]];
    }

  if ([tokens count] == 0)
    {
      [tokens addObject: @"object"];
    }

  for (i = 0; i < [tokens count]; i++)
    {
      NSString *part = [tokens objectAtIndex: i];
      NSString *head = nil;
      NSString *tail = nil;

      if ([part length] == 0)
        {
          continue;
        }

      if (i == 0)
        {
          unsigned upperRun = 0;
          unsigned lowerLength = 1;

          while (upperRun < [part length])
            {
              unichar ch = [part characterAtIndex: upperRun];
              if (ch < 'A' || ch > 'Z')
                {
                  break;
                }
              upperRun++;
            }

          if (upperRun == [part length])
            {
              lowerLength = upperRun;
            }
          else if (upperRun > 1)
            {
              lowerLength = upperRun - 1;
            }

          [identifier appendString:
            [[part substringToIndex: lowerLength] lowercaseString]];
          if ([part length] > lowerLength)
            {
              [identifier appendString: [part substringFromIndex: lowerLength]];
            }
        }
      else
        {
          head = [[part substringToIndex: 1] lowercaseString];
          tail = ([part length] > 1) ? [part substringFromIndex: 1] : @"";
          [identifier appendFormat: @"%@%@",
            [head uppercaseString], tail];
        }
    }

  if ([identifier length] > 0)
    {
      unichar firstChar = [identifier characterAtIndex: 0];
      if (firstChar >= '0' && firstChar <= '9')
        {
          [identifier insertString: @"object" atIndex: 0];
        }
    }

  if ([identifier length] == 0)
    {
      [identifier appendString: @"object"];
    }
  return identifier;
}

- (NSSet *) _reservedVariableNames
{
  return [NSSet setWithObjects:
    @"objects",
    @"topLevelObjects",
    @"visibleWindows",
    @"deferredWindows",
    @"connections",
    @"connectionEnumerator",
    @"connection",
    nil];
}

- (NSString *) _escapedString: (NSString *)string
{
  NSMutableString *escaped = [NSMutableString string];
  unsigned i = 0;

  if (string == nil)
    {
      return @"";
    }

  for (i = 0; i < [string length]; i++)
    {
      unichar ch = [string characterAtIndex: i];
      switch (ch)
        {
          case '\\':
            [escaped appendString: @"\\\\"];
            break;
          case '"':
            [escaped appendString: @"\\\""];
            break;
          case '\n':
            [escaped appendString: @"\\n"];
            break;
          case '\r':
            [escaped appendString: @"\\r"];
            break;
          case '\t':
            [escaped appendString: @"\\t"];
            break;
          default:
            [escaped appendFormat: @"%C", ch];
            break;
        }
    }
  return escaped;
}

- (NSString *) _headerGuardForName: (NSString *)name
{
  NSMutableString *guard = [NSMutableString stringWithString: @"INCLUDED_"];
  NSString *source = (name != nil && [name length] > 0) ? name : @"GormGenerated";
  unsigned i = 0;

  for (i = 0; i < [source length]; i++)
    {
      unichar ch = [source characterAtIndex: i];
      BOOL valid = ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
        || (ch >= '0' && ch <= '9'));

      if (valid == YES)
        {
          [guard appendFormat: @"%C", ch];
        }
      else
        {
          [guard appendString: @"_"];
        }
    }

  [guard appendString: @"_h"];
  return guard;
}

- (NSString *) _rectString: (NSRect)rect
{
  return [NSString stringWithFormat:
    @"NSMakeRect(%g, %g, %g, %g)",
    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

- (NSString *) _pointString: (NSPoint)point
{
  return [NSString stringWithFormat:
    @"NSMakePoint(%g, %g)", point.x, point.y];
}

- (NSString *) _sizeString: (NSSize)size
{
  return [NSString stringWithFormat:
    @"NSMakeSize(%g, %g)", size.width, size.height];
}

- (NSString *) _keyForObject: (id)object
{
  return [NSString stringWithFormat: @"%p", object];
}

- (BOOL) _objectIsOwner: (id)object
{
  NSString *name = [_document nameForObject: object];

  return [name isEqualToString: @"NSOwner"];
}

@end
