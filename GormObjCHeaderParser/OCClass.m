/* OCClass.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Gregory John Casamento <greg_casamento@yahoo.com>
 * Date:	1999, 2002
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


#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSScanner.h>
#include <GormObjCHeaderParser/OCClass.h>
#include <GormObjCHeaderParser/OCMethod.h>
#include <GormObjCHeaderParser/OCIVar.h>
#include <GormObjCHeaderParser/NSScanner+OCHeaderParser.h>

@implementation OCClass
- (id) initWithString: (NSString *)string
{
  if((self = [super init]) != nil)
    {
      methods = [[NSMutableArray alloc] init];
      ivars = [[NSMutableArray alloc] init];
      ASSIGN(classString, string);
    }
  return self;
}

- (void) dealloc
{
  RELEASE(methods);
  RELEASE(ivars);
  RELEASE(classString);
  RELEASE(className);
  RELEASE(superClassName);
  [super dealloc];
}

- (NSArray *) methods
{
  return methods;
}

- (void) addMethod: (NSString *)name isAction: (BOOL) flag
{
  OCMethod *method = AUTORELEASE([[OCMethod alloc] init]);
  [method setName: name];
  [method setIsAction: flag];
  [methods addObject: method];
}

- (NSArray *) ivars
{
  return ivars;
}

- (void) addIVar: (NSString *)name isOutlet: (BOOL) flag
{
  OCIVar *ivar = AUTORELEASE([[OCIVar alloc] init]);
  [ivar setName: name];
  [ivar setIsOutlet: flag];
  [ivars addObject: ivar];
}

- (NSString *) className
{
  return className;
}

- (void) setClassName: (NSString *)name
{
  ASSIGN(className, name);
}

- (NSString *) superClassName
{
  return superClassName;
}

- (void) setSuperClassName: (NSString *)name
{
  ASSIGN(superClassName,name);
}

- (BOOL) isCategory
{
  return isCategory;
}

- (void) setIsCategory: (BOOL)flag
{
  isCategory = flag;
}

- (void) _strip
{
  NSString *resultString = nil;
  // strip whitespace...
  ASSIGN(classString, resultString);
}

- (void) _parseClass
{
  NSScanner *scanner = [NSScanner scannerWithString: classString];
  NSString *interfaceLine = nil;

  [scanner scanUpToString: @"@interface" intoString: NULL]; // look ahead...  
  [scanner scanUpToString: @"\n" intoString: &interfaceLine];
  scanner = [NSScanner scannerWithString: interfaceLine]; // reset scanner... 
  if(NSEqualRanges([interfaceLine rangeOfString: @":"],NSMakeRange(NSNotFound,0)) == NO)
    {
      [scanner scanUpToAndIncludingString: @"@interface" intoString: NULL];
      [scanner scanUpToString: @":" intoString: &className];
      RETAIN(className);
      [scanner scanString: @":" intoString: NULL];
      [scanner scanUpToString: @" " intoString: &superClassName];
      RETAIN(superClassName);
    }
  else // category...
    {
      [scanner scanUpToAndIncludingString: @"@interface" intoString: NULL];
      [scanner scanUpToString: @" " intoString: &className];
      RETAIN(className);
      [self setIsCategory: YES];
    }
}

- (void) _parseIVars
{
  NSScanner *scanner = [NSScanner scannerWithString: classString];
  NSString *ivarsString = nil;

  // put the ivars into a a string...
  [scanner scanUpToAndIncludingString: @"{" intoString: NULL];
  [scanner scanUpToString: @"}" intoString: &ivarsString];
  [scanner scanString: @"}" intoString: NULL];

  // scan each ivar...
  scanner = [NSScanner scannerWithString: ivarsString];
  while(![scanner isAtEnd])
    {
      NSString *ivarLine = nil;
      OCIVar *ivar = nil;

      [scanner scanUpToString: @";" intoString: &ivarLine];
      [scanner scanString: @";" intoString: NULL];
      ivar = AUTORELEASE([[OCIVar alloc] initWithString: ivarLine]); 
      [ivar parse];
      [ivars addObject: ivar];
    }
}

- (void) _parseMethods
{
  NSScanner *scanner = [NSScanner scannerWithString: classString];
  NSString *methodsString = nil;

  // put the methods into a a string...
  [scanner scanUpToAndIncludingString: @"{" intoString: NULL];
  [scanner scanUpToString: @"}" intoString: NULL];
  [scanner scanString: @"}" intoString: NULL];
  [scanner scanUpToString: @"@end" intoString: &methodsString];

  // scan each method...
  scanner = [NSScanner scannerWithString: methodsString];
  while(![scanner isAtEnd])
    {
      NSString *methodLine = nil;
      OCMethod *method = nil;

      [scanner scanUpToString: @";" intoString: &methodLine];
      [scanner scanString: @";" intoString: NULL];
      method = AUTORELEASE([[OCMethod alloc] initWithString: methodLine]);       
      [method parse];
      [methods addObject: method];
    }
}

- (void) parse
{
  // [self _strip];
  [self _parseClass];
  if([self isCategory] == NO)
    {
      [self _parseIVars];
    }
  [self _parseMethods];
}
@end
