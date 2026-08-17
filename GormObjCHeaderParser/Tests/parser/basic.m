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
#import <Foundation/Foundation.h>
#import <GormObjCHeaderParser/GormObjCHeaderParser.h>

static NSString *temporaryHeader(NSString *contents)
{
  NSString *name;
  NSString *path;

  name = [NSString stringWithFormat: @"gorm-parser-%@.h",
                   [[NSProcessInfo processInfo] globallyUniqueString]];
  path = [NSTemporaryDirectory() stringByAppendingPathComponent: name];
  if ([contents writeToFile: path atomically: YES] == NO)
    {
      return nil;
    }
  return path;
}

static OCMethod *method(NSString *declaration)
{
  OCMethod *value;

  value = AUTORELEASE([[OCMethod alloc] initWithString: declaration]);
  [value parse];
  return value;
}

static OCIVar *ivar(NSString *declaration)
{
  OCIVar *value;

  value = AUTORELEASE([[OCIVar alloc] initWithString: declaration]);
  [value parse];
  return value;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSScanner *scanner;
  NSString *scanned;
  OCMethod *m;
  OCIVar *v;
  OCIVarDecl *decl;
  NSArray *values;
  OCClass *classInfo;
  OCHeaderParser *parser;
  NSString *path;
  NSString *header;

  START_SET("Gorm Objective-C header parser")

  /* ParserFunctions: substring and token-boundary behavior. */
  PASS(lookAhead(@"prefix IBOutlet suffix", @"IBOutlet"),
       "lookAhead finds an embedded substring")
  PASS(!lookAhead(@"prefix outlet suffix", @"IBOutlet"),
       "lookAhead is case sensitive")
  PASS(lookAheadForToken(@"id object", @"id"),
       "lookAheadForToken accepts a leading whitespace-delimited token")
  PASS(!lookAheadForToken(@"identifier", @"id"),
       "lookAheadForToken rejects a token prefix")
  PASS(!lookAheadForToken(@" id object", @"id"),
       "lookAheadForToken only considers the start of the input")

  /* NSScanner additions: delimiter inclusion and end-of-input behavior. */
  scanner = [NSScanner scannerWithString: @"alpha;beta"];
  [scanner setCharactersToBeSkipped: nil];
  scanned = nil;
  [scanner scanUpToAndIncludingString: @";" intoString: &scanned];
  PASS([scanned isEqual: @"alpha;"],
       "string scanning includes the delimiter")
  scanned = nil;
  [scanner scanUpToAndIncludingString: @";" intoString: &scanned];
  PASS([scanned isEqual: @"beta"],
       "string scanning returns the remainder when no delimiter exists")
  scanner = [NSScanner scannerWithString: @";tail"];
  [scanner setCharactersToBeSkipped: nil];
  scanned = nil;
  [scanner scanUpToAndIncludingString: @";" intoString: &scanned];
  PASS([scanned isEqual: @";"],
       "string scanning returns a delimiter at the current position")
  scanner = [NSScanner scannerWithString: @"name  value"];
  [scanner setCharactersToBeSkipped: nil];
  scanned = nil;
  [scanner scanUpToAndIncludingCharactersFromSet:
             [NSCharacterSet whitespaceCharacterSet]
                                             intoString: &scanned];
  PASS([scanned isEqual: @"name  "],
       "character-set scanning includes the complete delimiter run")

  /* OCMethod: selectors, method kind, and Gorm action classification. */
  m = method(@"-(void)refresh");
  PASS([[m name] isEqual: @"refresh"], "an instance selector is parsed")
  PASS(![m isClassMethod], "a minus method is an instance method")
  PASS(![m isAction], "a zero-argument method is not an action")
  m = method(@"+(id)sharedController");
  PASS([[m name] isEqual: @"sharedController"], "a class selector is parsed")
  PASS([m isClassMethod], "a plus method is a class method")
  PASS(![m isAction], "class methods are not actions")
  m = method(@"-(IBAction)perform:(id)sender");
  PASS([[m name] isEqual: @"perform:"], "an action selector is parsed")
  PASS([m isAction], "IBAction with one id argument is an action")
  m = method(@"-(void)select:(id)sender");
  PASS([m isAction], "void with one id argument is an action")
  m = method(@"-reset:(id)sender");
  PASS([m isAction], "the implicit id return type can form an action")
  m = method(@"-(NSInteger)count:(id)sender");
  PASS(![m isAction], "an incompatible return type is not an action")
  m = method(@"-(void)move:(id)sender to:(id)destination");
  PASS(![m isAction], "a multi-argument method is not an action")

  /* OCIVar and OCProperty share declaration parsing. */
  v = ivar(@"NSString *title");
  PASS([[v name] isEqual: @"title"], "an object-pointer ivar name is parsed")
  PASS(![v isOutlet], "a typed object ivar is not implicitly an outlet")
  v = ivar(@"id delegate");
  PASS([[v name] isEqual: @"delegate"], "an id ivar name is parsed")
  PASS([v isOutlet], "an id ivar is treated as an outlet")
  v = ivar(@"IBOutlet NSView *contentView");
  PASS([[v name] isEqual: @"contentView"], "an IBOutlet name is parsed")
  PASS([v isOutlet], "IBOutlet is marked as an outlet")
  v = AUTORELEASE([[OCProperty alloc]
                    initWithString: @"NSString *representedObject"]);
  [v parse];
  PASS([[v name] isEqual: @"representedObject"],
       "OCProperty uses ivar declaration parsing")

  /* OCIVarDecl: single, grouped, outlet, and protocol-qualified forms. */
  decl = AUTORELEASE([[OCIVarDecl alloc] initWithString: @"NSInteger count"]);
  [decl parse];
  values = [decl ivars];
  PASS([values count] == 1, "a single declaration creates one ivar")
  PASS([[[values objectAtIndex: 0] name] isEqual: @"count"],
       "a single declaration preserves its name")
  decl = AUTORELEASE([[OCIVarDecl alloc]
                       initWithString: @"IBOutlet id first, second, third"]);
  [decl parse];
  values = [decl ivars];
  PASS([values count] == 3, "a grouped declaration creates every ivar")
  PASS([[[values objectAtIndex: 0] name] isEqual: @"first"] &&
       [[[values objectAtIndex: 1] name] isEqual: @"second"] &&
       [[[values objectAtIndex: 2] name] isEqual: @"third"],
       "grouped declaration names retain source order")
  PASS([[values objectAtIndex: 0] isOutlet] &&
       [[values objectAtIndex: 1] isOutlet] &&
       [[values objectAtIndex: 2] isOutlet],
       "grouped declarations propagate outlet status")
  decl = AUTORELEASE([[OCIVarDecl alloc]
                       initWithString: @"id<NSCopying> representedObject"]);
  [decl parse];
  PASS([[[[decl ivars] objectAtIndex: 0] name]
          isEqual: @"representedObject"],
       "protocol qualification is removed before parsing")

  /* OCClass: normal interfaces, categories, members, and mutator API. */
  classInfo = AUTORELEASE([[OCClass alloc] initWithString:
    @"@interface PanelController : NSObject { IBOutlet id owner; NSInteger count; } -(IBAction)close:(id)sender; +(id)sharedPanel; @end"]);
  [classInfo parse];
  PASS([[classInfo className] isEqual: @"PanelController"],
       "OCClass parses the class name")
  PASS([[classInfo superClassName] isEqual: @"NSObject"],
       "OCClass parses the superclass name")
  PASS(![classInfo isCategory], "a class interface is not a category")
  PASS([[classInfo ivars] count] == 2, "OCClass parses its ivars")
  PASS([[classInfo methods] count] == 2, "OCClass parses its methods")
  classInfo = AUTORELEASE([[OCClass alloc]
                            initWithString: @"@interface NSObject (GormAdditions) -(void)inspect; @end"]);
  [classInfo parse];
  PASS([[classInfo className] isEqual: @"NSObject"],
       "a category retains the base class name")
  PASS([classInfo isCategory], "a category is identified")
  [classInfo addMethod: @"addedAction:" isAction: YES];
  [classInfo addIVar: @"addedOutlet" isOutlet: YES];
  PASS([[[[classInfo methods] lastObject] name] isEqual: @"addedAction:"] &&
       [[[classInfo methods] lastObject] isAction],
       "the method mutator records name and action status")
  PASS([[[[classInfo ivars] lastObject] name] isEqual: @"addedOutlet"] &&
       [[[classInfo ivars] lastObject] isOutlet],
       "the ivar mutator records name and outlet status")

  /* OCHeaderParser: file preprocessing and multiple interface extraction. */
  header = @"#import <Foundation/Foundation.h>\n"
            "// @interface Ignored : NSObject @end\n"
            "/* @interface AlsoIgnored : NSObject @end */\n"
            "@interface First : NSObject\n"
            "{\n"
            "  IBOutlet id delegate;\n"
            "}\n"
            "-(IBAction)run:(id)sender;;;\n"
            "@end\n"
            "@interface Second (Extras)\n"
            "-(void)extra;\n"
            "@end\n";
  path = temporaryHeader(header);
  PASS(path != nil, "the test header can be written")
  parser = AUTORELEASE([[OCHeaderParser alloc] initWithContentsOfFile: path]);
  PASS([parser parse], "a valid header parses successfully")
  PASS([[parser classes] count] == 2,
       "comments, directives, and redundant semicolons do not create classes")
  PASS([[[[parser classes] objectAtIndex: 0] className] isEqual: @"First"] &&
       [[[[parser classes] objectAtIndex: 1] className] isEqual: @"Second"],
       "multiple classes retain source order")
  PASS([[[[parser classes] objectAtIndex: 0] ivars] count] == 1,
       "the full parser exposes parsed ivars")
  PASS([[[[parser classes] objectAtIndex: 0] methods] count] == 1,
       "the full parser exposes parsed methods")
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];

  path = temporaryHeader(@"#define NOTHING 1\n// no declarations\n");
  parser = AUTORELEASE([[OCHeaderParser alloc] initWithContentsOfFile: path]);
  PASS(![parser parse], "a header without interfaces reports failure")
  PASS([[parser classes] count] == 0,
       "a header without interfaces produces no class metadata")
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];

  END_SET("Gorm Objective-C header parser")

  [pool drain];
  return 0;
}
