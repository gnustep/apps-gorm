/* GormObjectInspector.m
 *
 * Copyright (C) 1999 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <richard@brainstrom.co.uk>
 * Date:	1999
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include "GormObjectInspector.h"
#include <errno.h>
#include <limits.h>
#include <float.h>
#include <math.h>

/* NSInvocation preserves the actual argument and return ABI, including
 * NSInteger on 64-bit runtimes.  Do not call arbitrary IMPs as returning id.
 */
typedef union
{
  signed char c; unsigned char C;
  short s; unsigned short S;
  int i; unsigned int I;
  long l; unsigned long L;
  long long q; unsigned long long Q;
  _Bool B;
  float f; double d;
  id object;
} GormInspectorValue;

static const char *
GormInspectorType(const char *type)
{
  while (*type && strchr("rnNoORV", *type) != NULL)
    type++;
  return type;
}

static NSString *
GormInspectorTypeName(const char *type)
{
  switch (*GormInspectorType(type))
    {
      case '@': return typeId;
      case 'c': return typeCharOrBool;
      case 'C': return typeUChar;
      case 's': return @"Short integer";
      case 'S': return @"Unsigned short integer";
      case 'i': return typeInt;
      case 'I': return typeUInt;
      case 'l': return @"Long integer";
      case 'L': return @"Unsigned long integer";
      case 'q': return @"Long long integer";
      case 'Q': return @"Unsigned long long integer";
      case 'B': return @"Boolean (0 or 1)";
      case 'f': return typeFloat;
      case 'd': return typeDouble;
      default: return nil;
    }
}

static BOOL
GormInspectorParse(NSString *text, char type, GormInspectorValue *result)
{
  NSString *trimmed = [text stringByTrimmingCharactersInSet:
    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  const char *start = [trimmed UTF8String];
  char *end;
  long long signedValue;
  unsigned long long unsignedValue;
  double realValue;

  if (start == NULL || *start == 0
      || strlen(start) != [trimmed lengthOfBytesUsingEncoding: NSUTF8StringEncoding])
    return NO;
  errno = 0;
  if (type == 'f' || type == 'd')
    {
      realValue = strtod(start, &end);
      if (errno == ERANGE || end == start || *end != 0 || !isfinite(realValue))
        return NO;
      if (type == 'f')
        {
          if (fabs(realValue) > FLT_MAX
              || (realValue != 0 && (float)realValue == 0))
            return NO;
          result->f = realValue;
        }
      else
        result->d = realValue;
      return YES;
    }
  if (strchr("CSILQB", type) != NULL)
    {
      if (*start == '-')
        return NO;
      unsignedValue = strtoull(start, &end, 10);
      if (errno == ERANGE || end == start || *end != 0)
        return NO;
#define UNSIGNED_CASE(code, field, maximum) \
      case code: if (unsignedValue > maximum) return NO; \
        result->field = unsignedValue; return YES
      switch (type)
        {
          UNSIGNED_CASE('C', C, UCHAR_MAX);
          UNSIGNED_CASE('S', S, USHRT_MAX);
          UNSIGNED_CASE('I', I, UINT_MAX);
          UNSIGNED_CASE('L', L, ULONG_MAX);
          UNSIGNED_CASE('Q', Q, ULLONG_MAX);
          UNSIGNED_CASE('B', B, 1);
        }
#undef UNSIGNED_CASE
    }
  signedValue = strtoll(start, &end, 10);
  if (errno == ERANGE || end == start || *end != 0)
    return NO;
#define SIGNED_CASE(code, field, minimum, maximum) \
  case code: if (signedValue < minimum || signedValue > maximum) return NO; \
    result->field = signedValue; return YES
  switch (type)
    {
      SIGNED_CASE('c', c, SCHAR_MIN, SCHAR_MAX);
      SIGNED_CASE('s', s, SHRT_MIN, SHRT_MAX);
      SIGNED_CASE('i', i, INT_MIN, INT_MAX);
      SIGNED_CASE('l', l, LONG_MIN, LONG_MAX);
      SIGNED_CASE('q', q, LLONG_MIN, LLONG_MAX);
    }
#undef SIGNED_CASE
  return NO;
}

static NSString *
GormInspectorFormat(GormInspectorValue v, char type)
{
  switch (type)
    {
      case 'c': return [NSString stringWithFormat: @"%d", v.c];
      case 'C': return [NSString stringWithFormat: @"%u", (unsigned)v.C];
      case 's': return [NSString stringWithFormat: @"%d", v.s];
      case 'S': return [NSString stringWithFormat: @"%u", (unsigned)v.S];
      case 'i': return [NSString stringWithFormat: @"%d", v.i];
      case 'I': return [NSString stringWithFormat: @"%u", v.I];
      case 'l': return [NSString stringWithFormat: @"%ld", v.l];
      case 'L': return [NSString stringWithFormat: @"%lu", v.L];
      case 'q': return [NSString stringWithFormat: @"%lld", v.q];
      case 'Q': return [NSString stringWithFormat: @"%llu", v.Q];
      case 'B': return v.B ? @"1" : @"0";
      case 'f': return [NSString stringWithFormat: @"%.9g", v.f];
      case 'd': return [NSString stringWithFormat: @"%.17g", v.d];
      default: return v.object == nil ? @"" : [v.object description];
    }
}

@implementation GormObjectInspector

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSBundle *bundle = [NSBundle bundleForClass: [GormObjectInspector class]];
      if ([bundle loadNibNamed: @"GormObjectInspector" owner: self
              topLevelObjects: NULL] == NO)
        {
          NSDebugLog(@"Couldn't load GormObjectInspector");
          RELEASE(self);
          return nil;
        }
      sets = [[NSMutableArray alloc] init];
      gets = [[NSMutableDictionary alloc] init];
      types = [[NSMutableDictionary alloc] init];
      [okButton setEnabled: NO];
      revertButton = nil;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(gets);
  RELEASE(sets);
  RELEASE(types);
  [super dealloc];
}

- (NSInteger) browser: (NSBrowser*)sender numberOfRowsInColumn: (NSInteger)column
{
  return [sets count];
}

- (BOOL) browser: (NSBrowser*)sender selectCellWithString: (NSString*)title
       inColumn: (NSInteger)col
{
  [self update: self];
  return YES;
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (NSInteger)col
{
  return _(@"Attribute setters");
}

- (void) browser: (NSBrowser*)sender willDisplayCell: (id)aCell
          atRow: (NSInteger)row column: (NSInteger)col
{
  BOOL valid = row >= 0 && (NSUInteger)row < [sets count];
  [aCell setStringValue: valid ? [sets objectAtIndex: row] : @""];
  [aCell setEnabled: valid];
  [aCell setLeaf: YES];
}

- (void) ok: (id)sender
{
  NSString *name = [[browser selectedCell] stringValue];
  NSString *encoding = [types objectForKey: name];
  GormInspectorValue v;
  NSInvocation *invocation;
  id createdObject = nil;

  if (encoding == nil || object == nil)
    return;
  memset(&v, 0, sizeof(v));
  @try
    {
      char type = [encoding characterAtIndex: 0];
      if (type == '@')
        {
          v.object = [value stringValue];
          if (!isString)
            {
              NSString *text = [v.object stringByTrimmingSpaces];
              int choice = NSRunAlertPanel(_(@"Settings"),
                _(@"Set object using '%@' as"), _(@"Object name"),
                _(@"String"), _(@"Class name"), text);
              if (choice == NSAlertAlternateReturn)
                v.object = text;
              else if (choice == NSAlertOtherReturn)
                {
                  createdObject = [[NSClassFromString(text) alloc] init];
                  v.object = createdObject;
                }
              else
                v.object = [[(id<IB>)[NSApp delegate] activeDocument]
                  objectForName: text];
              if (v.object == nil)
                {
                  [label setTitle: _(@"Object or class not found")];
                  return;
                }
            }
        }
      else if (!GormInspectorParse([value stringValue], type, &v))
        {
          [label setTitle: _(@"Invalid or out-of-range value")];
          return;
        }
      invocation = [NSInvocation invocationWithMethodSignature:
        [object methodSignatureForSelector: NSSelectorFromString(name)]];
      [invocation setSelector: NSSelectorFromString(name)];
      [invocation setArgument: &v atIndex: 2];
      [invocation invokeWithTarget: object];
      [super ok: sender];
      [self update: self];
    }
  @catch (NSException *exception)
    {
      [label setTitle: _(@"Unable to set value")];
      [value setToolTip: [exception reason]];
      NSDebugLog(@"Inspector setter %@ failed: %@", name, exception);
    }
  @finally
    {
      RELEASE(createdObject);
    }
}

- (void) setObject: (id)anObject
{
  Class c;

  if (anObject == object)
    {
      [self update: self];
      return;
    }
  ASSIGN(object, anObject);
  [sets removeAllObjects];
  [gets removeAllObjects];
  [types removeAllObjects];
  for (c = [object class]; c != Nil && c != [NSObject class]; c = [c superclass])
    {
      unsigned int count, i;
      Method *methods = class_copyMethodList(c, &count);
      for (i = 0; i < count; i++)
        {
          NSString *name = NSStringFromSelector(method_getName(methods[i]));
          NSMethodSignature *signature;
          const char *type;
          NSString *stem, *getter;
          NSArray *candidates;
          NSUInteger j;

          if ([name length] <= 4 || ![name hasPrefix: @"set"]
              || [name rangeOfString: @":"].location != [name length] - 1
              || [sets containsObject: name])
            continue;
          signature = [object methodSignatureForSelector: NSSelectorFromString(name)];
          if ([signature numberOfArguments] != 3
              || strcmp(GormInspectorType([signature methodReturnType]), @encode(void)))
            continue;
          type = GormInspectorType([signature getArgumentTypeAtIndex: 2]);
          /* Blocks, pointers, structures and other unsupported types stay out. */
          if (GormInspectorTypeName(type) == nil || strcmp(type, "@?") == 0)
            continue;
          [sets addObject: name];
          [types setObject: [NSString stringWithUTF8String: type] forKey: name];
          stem = [name substringWithRange: NSMakeRange(3, [name length] - 4)];
          getter = [[[stem substringToIndex: 1] lowercaseString]
            stringByAppendingString: [stem substringFromIndex: 1]];
          candidates = [NSArray arrayWithObjects: getter,
            [@"is" stringByAppendingString: stem], stem, nil];
          for (j = 0; j < [candidates count]; j++)
            {
              NSString *candidate = [candidates objectAtIndex: j];
              SEL selector = NSSelectorFromString(candidate);
              NSMethodSignature *readSignature;
              if (![object respondsToSelector: selector])
                continue;
              readSignature = [object methodSignatureForSelector: selector];
              if ([readSignature numberOfArguments] == 2
                  && strcmp(GormInspectorType([readSignature methodReturnType]), type) == 0)
                {
                  [gets setObject: candidate forKey: name];
                  break;
                }
            }
        }
      free(methods);
    }
  [sets sortUsingSelector: @selector(compare:)];
  [browser loadColumnZero];
  [self update: self];
}

- (void) update: (id)sender
{
  NSString *name = [[browser selectedCell] stringValue];
  NSString *encoding = [types objectForKey: name];
  NSString *getter = [gets objectForKey: name];

  isString = NO;
  [value setToolTip: nil];
  [value setStringValue: @""];
  [value setEditable: encoding != nil];
  [okButton setEnabled: encoding != nil];
  if (encoding == nil)
    [label setTitle: _(@"No Type")];
  else if (getter == nil)
    [label setTitle: [NSString stringWithFormat: _(@"%@ - value unknown"),
      GormInspectorTypeName([encoding UTF8String])]];
  else
    {
      @try
        {
          GormInspectorValue v;
          SEL selector = NSSelectorFromString(getter);
          NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
            [object methodSignatureForSelector: selector]];
          memset(&v, 0, sizeof(v));
          [invocation setSelector: selector];
          [invocation invokeWithTarget: object];
          [invocation getReturnValue: &v];
          isString = [encoding hasPrefix: @"@"]
            && [v.object isKindOfClass: [NSString class]];
          [label setTitle: GormInspectorTypeName([encoding UTF8String])];
          [value setStringValue: GormInspectorFormat(v, [encoding characterAtIndex: 0])];
        }
      @catch (NSException *exception)
        {
          [label setTitle: _(@"Unable to read value")];
          [value setToolTip: [exception reason]];
          [okButton setEnabled: NO];
          NSDebugLog(@"Inspector getter %@ failed: %@", getter, exception);
        }
    }
}

- (void) revert: (id)sender
{
  [super revert: sender];
  [self update: sender];
}

- (BOOL) wantsButtons
{
  return YES;
}
@end
