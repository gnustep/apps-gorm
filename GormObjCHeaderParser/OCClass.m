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
#include <Foundation/NSCharacterSet.h>
#include <GormObjCHeaderParser/OCClass.h>
#include <GormObjCHeaderParser/OCMethod.h>
#include <GormObjCHeaderParser/OCIVar.h>
#include <GormObjCHeaderParser/OCIVarDecl.h>
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
  NSScanner *stripScanner = [NSScanner scannerWithString: classString];
  NSString *resultString = [NSString stringWithString: @""];
  NSCharacterSet *wsnl = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  while(![stripScanner isAtEnd])
    {
      NSString *string = nil;
      [stripScanner scanUpToCharactersFromSet: wsnl intoString: &string];
      resultString = [resultString stringByAppendingString: string];
      if(![stripScanner isAtEnd])
	{
	  resultString = [resultString stringByAppendingString: @" "];
	}
    }
  
  ASSIGN(classString, resultString);
}

- (void) parse
{
  NSScanner *scanner = nil; 
  NSScanner *iscan = nil;
  NSString *interfaceLine = nil;
  NSString *methodsString = nil;
  NSString *ivarsString = nil;
  NSRange range;
  NSRange notFound = NSMakeRange(NSNotFound,0);
  NSCharacterSet *wsnl = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSCharacterSet *pmcs = [NSCharacterSet characterSetWithCharactersInString: @"+-"];

  // get the interface line... look ahead...  
  [self _strip];
  scanner = [NSScanner scannerWithString: classString];
  if(NSEqualRanges(range = [classString rangeOfString: @"{"], notFound) == NO)
    {
      [scanner scanUpToString: @"@interface" intoString: NULL]; 
      [scanner scanUpToString: @"{" intoString: &interfaceLine];
      iscan = [NSScanner scannerWithString: interfaceLine]; // reset scanner... 
    }
  else // if there is no "{", then there are no ivars...
    {
      [scanner scanUpToString: @"@interface" intoString: NULL]; 
      [scanner scanUpToCharactersFromSet: pmcs intoString: &interfaceLine];
      iscan = [NSScanner scannerWithString: interfaceLine]; // reset scanner... 
    }

  // look ahead...  
  if(NSEqualRanges([interfaceLine rangeOfString: @":"], notFound) == NO)
    {
      NSString *cn = nil, *scn = nil;

      [iscan scanUpToAndIncludingString: @"@interface" intoString: NULL];
      [iscan scanUpToString: @":" intoString: &cn];
      className = [cn stringByTrimmingCharactersInSet: wsnl];
      RETAIN(className);
      [iscan scanString: @":" intoString: NULL];
      [iscan scanUpToCharactersFromSet: wsnl intoString: &scn];
      superClassName = [scn stringByTrimmingCharactersInSet: wsnl];
      RETAIN(superClassName);
    }
  else // category...
    {
      NSString *cn = nil;

      [iscan scanUpToAndIncludingString: @"@interface" intoString: NULL];
      [iscan scanUpToCharactersFromSet: wsnl intoString: &cn];
      className = [cn stringByTrimmingCharactersInSet: wsnl];
      RETAIN(className);
      isCategory = YES;
    }
  
  if(isCategory == NO)
    {          
      NSScanner *ivarScan = nil;

      // put the ivars into a a string...
      [scanner scanUpToAndIncludingString: @"{" intoString: NULL];
      [scanner scanUpToString: @"}" intoString: &ivarsString];
      [scanner scanString: @"}" intoString: NULL];
      
      if(ivarsString != nil)
	{
	  // scan each ivar...
	  ivarScan = [NSScanner scannerWithString: ivarsString];
	  while(![ivarScan isAtEnd])
	    {
	      NSString *ivarLine = nil;
	      OCIVarDecl *ivarDecl = nil;
	      
	      [ivarScan scanUpToString: @";" intoString: &ivarLine];
	      [ivarScan scanString: @";" intoString: NULL];
	      ivarDecl = AUTORELEASE([[OCIVarDecl alloc] initWithString: ivarLine]); 
	      [ivarDecl parse];
	      [ivars addObjectsFromArray: [ivarDecl ivars]];
	    }
	}
    }

  // put the methods into a string...
  if(ivarsString != nil)
    {
      [scanner scanUpToString: @"@end" intoString: &methodsString];
    }
  else // 
    {
      scanner = [NSScanner scannerWithString: classString];
      [scanner scanUpToAndIncludingString: interfaceLine intoString: NULL];
      [scanner scanUpToString: @"@end" intoString: &methodsString];
    }
  
  // scan each method...
  if(methodsString != nil)
    {
      NSScanner *methodScan = [NSScanner scannerWithString: methodsString];
      while(![methodScan isAtEnd])
	{
	  NSString *methodLine = nil;
	  OCMethod *method = nil;
	  
	  [methodScan scanUpToString: @";" intoString: &methodLine];
	  [methodScan scanString: @";" intoString: NULL];
	  method = AUTORELEASE([[OCMethod alloc] initWithString: methodLine]);       
	  [method parse];
	  [methods addObject: method];
	}
    }
}
@end
