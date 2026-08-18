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
#import <GormObjCHeaderParser/OCClass.h>
#import <GormObjCHeaderParser/OCHeaderParser.h>
#import <GormObjCHeaderParser/OCIVar.h>
#import <GormObjCHeaderParser/OCMethod.h>

static NSString *firstMethodName(OCClass *cls)
{
  return [[[cls methods] objectAtIndex: 0] name];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  OCMethod *method;
  OCMethod *classMethod;
  OCIVar *ivar;
  OCClass *cls;
  OCHeaderParser *parser;
  NSString *header;
  NSString *path;

  START_SET("GormObjCHeaderParser")

  method = AUTORELEASE([[OCMethod alloc]
                         initWithString: @"- (IBAction)chooseFile:(id)sender"]);
  [method parse];
  PASS([[method name] isEqual: @"chooseFile:"] && [method isAction],
       "IBAction methods are parsed as actions")

  method = AUTORELEASE([[OCMethod alloc]
                         initWithString:
                           @"- (void)setValue:(id)value forKey:(NSString *)key"]);
  [method parse];
  PASS([[method name] isEqual: @"setValue:(id)value forKey:(NSString *)key"] &&
       [method isAction] == NO,
       "multi-argument instance methods are not treated as actions")

  classMethod = AUTORELEASE([[OCMethod alloc]
                              initWithString: @"+ (id)sharedController"]);
  [classMethod parse];
  PASS([[classMethod name] isEqual: @"sharedController"] &&
       [classMethod isClassMethod],
       "class methods record their selector and class-method flag")

  ivar = AUTORELEASE([[OCIVar alloc] initWithString: @"IBOutlet NSButton *okButton"]);
  [ivar parse];
  PASS([[ivar name] isEqual: @"okButton"] && [ivar isOutlet],
       "IBOutlet ivars are parsed as outlets")

  ivar = AUTORELEASE([[OCIVar alloc] initWithString: @"int count"]);
  [ivar parse];
  PASS([[ivar name] isEqual: @"count"] && [ivar isOutlet] == NO,
       "plain ivars are parsed without outlet metadata")

  cls = AUTORELEASE([[OCClass alloc]
                      initWithString:
                        @"@interface TestController : NSObject\n"
                        @"{\n"
                        @"  IBOutlet id window;\n"
                        @"}\n"
                        @"- (IBAction)show:(id)sender;\n"
                        @"@end"]);
  [cls parse];
  PASS([[cls className] isEqual: @"TestController"] &&
       [[cls superClassName] isEqual: @"NSObject"] &&
       [[[[cls ivars] objectAtIndex: 0] name] isEqual: @"window"] &&
       [firstMethodName(cls) isEqual: @"show:"],
       "classes expose parsed names, superclass, outlets, and actions")

  header = @"#import <Foundation/Foundation.h>\n"
           @"// ignored comment\n"
           @"@interface FirstController : NSObject\n"
           @"- (void)awakeFromNib;\n"
           @"@end\n"
           @"/* ignored block comment */\n"
           @"@interface SecondController : NSObject\n"
           @"- (IBAction)run:(id)sender;\n"
           @"@end\n";
  path = [NSTemporaryDirectory()
           stringByAppendingPathComponent:
             [NSString stringWithFormat: @"gorm-parser-%u.h", getpid()]];
  PASS([header writeToFile: path atomically: YES], "test header can be written")

  parser = AUTORELEASE([[OCHeaderParser alloc] initWithContentsOfFile: path]);
  PASS([parser parse] && [[parser classes] count] == 2,
       "headers with comments and preprocessor lines parse into classes")
  PASS([[[[parser classes] objectAtIndex: 0] className]
          isEqual: @"FirstController"] &&
       [[[[parser classes] objectAtIndex: 1] className]
          isEqual: @"SecondController"],
       "parsed classes preserve their names")

  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];

  END_SET("GormObjCHeaderParser")

  RELEASE(pool);
  return 0;
}
