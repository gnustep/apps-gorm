/*
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * This file is part of GNUstep.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

#import "Testing.h"
#import <math.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import <GormCore/NSString+methods.h>

/* The historical data.info layout, including its obsolete save target. */
@interface ArchivedFilePreferences : NSObject <NSCoding>
{
@public
  int version;
  NSString *target;
  NSString *archiveType;
}
@end

@implementation ArchivedFilePreferences
- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(int) at: &version];
  [coder encodeObject: target];
  [coder encodeObject: archiveType];
}
- (id) initWithCoder: (NSCoder *)coder
{
  if ((self = [super init]) != nil)
    {
      [coder decodeValueOfObjCType: @encode(int) at: &version];
      target = RETAIN([coder decodeObject]);
      archiveType = RETAIN([coder decodeObject]);
    }
  return self;
}
- (void) dealloc
{
  RELEASE(target);
  RELEASE(archiveType);
  [super dealloc];
}
@end

static BOOL floatsAreClose(CGFloat a, CGFloat b)
{
  return fabs(a - b) < 0.001;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSArray *found;
  NSView *root;
  NSView *child;
  NSView *grandchild;
  NSDictionary *dict;
  NSColor *color;
  CGFloat red, green, blue, alpha;
  GormResource *resource;

  START_SET("GormCore framework")

  PASS([[@"" capitalizedFirstCharacterString] isEqual: @""],
       "empty strings can be capitalized")
  PASS([[@"panelController" capitalizedFirstCharacterString]
          isEqual: @"PanelController"],
       "the first string character can be capitalized")
  PASS([[@"PanelController" lowercaseFirstCharacterString]
          isEqual: @"panelController"],
       "the first string character can be lowercased")
  PASS([[@"panel" splitCamelCaseString] isEqual: @"Panel"],
       "lowercase words are capitalized when split")

  PASS([identifierString(@"123 Panel Controller!") isEqual: @"PanelController"],
       "identifierString removes illegal and leading numeric characters")
  PASS([identifierString(@"!!!") isEqual: @"dummyIdentifier"],
       "identifierString falls back for empty identifiers")
  PASS([formatAction(@"perform:") isEqual: @"perform:"],
       "formatAction leaves a valid action selector unchanged")
  PASS([formatAction(@"perform") isEqual: @"perform:"],
       "formatAction appends a missing action colon")
  PASS([formatOutlet(@"delegate:") isEqual: @"delegate"],
       "formatOutlet removes an outlet colon")

  dict = colorToDict([NSColor colorWithCalibratedRed: 0.25
                                              green: 0.5
                                               blue: 0.75
                                              alpha: 0.8]);
  color = colorFromDict(dict);
  [color getRed: &red green: &green blue: &blue alpha: &alpha];
  PASS((floatsAreClose(red, 0.25)) &&
       (floatsAreClose(green, 0.5)) &&
       (floatsAreClose(blue, 0.75)) &&
       (floatsAreClose(alpha, 0.8)),
       "colors round-trip through dictionaries")
  PASS(colorToDict(nil) == nil && colorFromDict(nil) == nil,
       "nil colors and dictionaries are accepted")

  found = findAllSubmenus([NSArray arrayWithObject: @"PlainObject"]);
  PASS([found count] == 1 && [[found objectAtIndex: 0] isEqual: @"PlainObject"],
       "findAllSubmenus includes non-menu selections")

  root = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]);
  child = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 5, 5)]);
  grandchild = AUTORELEASE([[NSView alloc] initWithFrame:
                                      NSMakeRect(0, 0, 2, 2)]);
  [child addSubview: grandchild];
  [root addSubview: child];
  found = allSubviews(root);
  PASS([found count] == 2 &&
       [found objectAtIndex: 0] == child &&
       [found objectAtIndex: 1] == grandchild,
       "allSubviews returns descendants without the root view")

  resource = AUTORELEASE([[GormResource alloc]
                           initWithData: [NSData dataWithBytes: "gorm"
                                                        length: 4]
                           withFileName: @"data.resource"
                              inWrapper: YES]);
  PASS(resource != nil && [[resource fileName] isEqual: @"data.resource"] &&
       [[resource data] length] == 4 && [resource isInWrapper],
       "GormResource can represent data stored in a wrapper")

  {
    ArchivedFilePreferences *old = [ArchivedFilePreferences new];
    NSMutableData *data = [NSMutableData data];
    NSArchiver *writer = [[NSArchiver alloc] initForWritingWithMutableData: data];
    GormFilePrefsManager *prefs = [GormFilePrefsManager new];
    NSUnarchiver *reader;
    ArchivedFilePreferences *saved;

    old->version = 0x7fffff; // Metadata decoding is separate from document version warnings.
    old->target = [@"GNUstep gui-0.9.3" copy];
    old->archiveType = [@"Binary" copy];
    [writer encodeClassName: @"ArchivedFilePreferences"
               intoClassName: @"GormFilePrefsManager"];
    [writer encodeRootObject: old];
    PASS([prefs loadFromData: data],
         "metadata with an old save target and newer producer loads")
    PASS([[prefs archiveTypeName] isEqual: @"Binary"],
         "discarding a save target preserves the following archive metadata")

    reader = [[NSUnarchiver alloc] initForReadingWithData: [prefs data]];
    [reader decodeClassName: @"GormFilePrefsManager"
               asClassName: @"ArchivedFilePreferences"];
    saved = [reader decodeObject];
    PASS([saved->target isEqual: @"Latest Version"] &&
         saved->version == [GormFilePrefsManager currentVersion],
         "saving replaces obsolete target metadata with the current version")
    PASS([saved->archiveType isEqual: @"Binary"],
         "file metadata survives loading and resaving")
    RELEASE(reader);
    RELEASE(prefs);
    RELEASE(writer);
    RELEASE(old);
  }

  END_SET("GormCore framework")

  RELEASE(pool);
  return 0;
}
