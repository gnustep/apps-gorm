/* OCHeaderParser.m
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


#include <Foundation/Foundation.h>
#include <GormObjCHeaderParser/OCIVar.h>
#include <GormObjCHeaderParser/OCIVarDecl.h>
#include <GormObjCHeaderParser/NSScanner+OCHeaderParser.h>

@implementation OCIVarDecl

- (id) initWithString: (NSString *)string
{
  if((self = [super init]) != nil)
    {
      ASSIGN(ivarString, string);
      ivars = [[NSMutableArray alloc] init];
    }
  else
    {
      RELEASE(self);
    }

  return self;
}

- (NSArray *)ivars
{
  return ivars;
}

- (void) dealloc
{
  RELEASE(ivarString);
  RELEASE(ivars);
  [super dealloc];
}

- (void) _strip
{
  NSScanner *stripScanner = [NSScanner scannerWithString: ivarString];
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

  ASSIGN(ivarString, resultString);
}

- (void) parse
{
  NSRange notFound = NSMakeRange(NSNotFound,0);
  NSCharacterSet *wsnl = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSRange range;

  [self _strip];
  if(NSEqualRanges((range = [ivarString rangeOfString: @","]),notFound) == NO)
    {
      OCIVar *ivar = nil;
      NSScanner *scanner = [NSScanner scannerWithString: ivarString];
      NSString *tempIvar = nil;
      BOOL isOutlet = NO;

      // scan the first one in...
      [scanner scanUpToString: @"," intoString: &tempIvar];
      [scanner scanString: @"," intoString: NULL]; 
      ivar = AUTORELEASE([[OCIVar alloc] initWithString: tempIvar]);
      [ivar parse];
      [ivars addObject: ivar];
      isOutlet = [ivar isOutlet];

      while(![scanner isAtEnd])
	{
	  NSString *name = nil;
	  OCIVar *newIvar = nil;
	 
	  [scanner scanCharactersFromSet: wsnl intoString: NULL];
	  [scanner scanUpToString: @"," intoString: &name];
	  [scanner scanString: @"," intoString: NULL];
	  [scanner scanCharactersFromSet: wsnl intoString: NULL];
	  newIvar = AUTORELEASE([[OCIVar alloc] initWithString: nil]);
	  [newIvar setName: name];
	  [newIvar setIsOutlet: isOutlet];
	  [ivars addObject: newIvar];
	}
    }
  else // for everything else...
    {
      OCIVar *ivar = AUTORELEASE([[OCIVar alloc] initWithString: ivarString]);
      [ivar parse];
      [ivars addObject: ivar];
    }

}
@end
