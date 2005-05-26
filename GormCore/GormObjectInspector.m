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

static NSString	*typeId = @"Object";
static NSString	*typeChar = @"Character or Boolean";
static NSString	*typeUChar = @"Unsigned character/bool";
static NSString	*typeInt = @"Integer";
static NSString	*typeUInt = @"Unsigned integer";
static NSString	*typeFloat = @"Float";
static NSString	*typeDouble = @"Double";


@interface GormObjectInspector : IBInspector
{
  NSBrowser		*browser;
  NSMutableArray	*sets;
  NSMutableDictionary	*gets;
  NSMutableDictionary	*types;
  NSButton		*label;
  NSTextField		*value;
  BOOL			isString;
}
- (void) updateButtons;
@end

@implementation GormObjectInspector

- (int) browser: (NSBrowser*)sender numberOfRowsInColumn: (int)column
{
  return [sets count];
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)col
{
  [self updateButtons];
  return YES;
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)col
{
  return @"Attribute setters";
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)aCell
	   atRow: (int)row
	  column: (int)col
{
  if (row >= 0 && row < [sets count])
    {
      [aCell setStringValue: [sets objectAtIndex: row]];
      [aCell setEnabled: YES];
    }
  else
    {
      [aCell setStringValue: @""];
      [aCell setEnabled: NO];
    }
  [aCell setLeaf: YES];
}

- (void) dealloc
{
  RELEASE(gets);
  RELEASE(sets);
  RELEASE(types);
  RELEASE(okButton);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSView		*contents;
      NSRect		windowRect = NSMakeRect(0, 0, IVW, IVH-IVB);
      NSRect		rect;

      sets = [NSMutableArray new];
      gets = [NSMutableDictionary new];
      types = [NSMutableDictionary new];

      window = [[NSWindow alloc] initWithContentRect: windowRect
					   styleMask: NSBorderlessWindowMask 
					     backing: NSBackingStoreRetained
					       defer: NO];
      contents = [window contentView];

      rect = windowRect;
      rect.size.height -= 70;
      rect.origin.y += 70;

      browser = [[NSBrowser alloc] initWithFrame: rect];
      [browser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [browser setMaxVisibleColumns: 1];
      [browser setAllowsMultipleSelection: NO];
      [browser setHasHorizontalScroller: NO];
      [browser setTitled: YES];
      [browser setDelegate: self];
      [browser setTarget: self];
      [browser setAction: @selector(updateButtons)];

      [contents addSubview: browser];
      RELEASE(browser);

      rect = windowRect;
      rect.size.width -= 40;
      rect.size.height = 22;
      rect.origin.y = 30;
      rect.origin.x = 20;
      label = [[NSButton alloc] initWithFrame: rect];
      [label setBordered: NO];
      [label setTitle: _(@"No Type")];
      [contents addSubview: label];
      RELEASE(label);

      rect = windowRect;
      rect.size.height = 22;
      rect.origin.y = 0;
      value = [[NSTextField alloc] initWithFrame: rect];
      [contents addSubview: value];
      RELEASE(value);

      okButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,90,20)];
      [okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
      [okButton setAction: @selector(ok:)];
      [okButton setTarget: self];
      [okButton setTitle: _(@"OK")];
      [okButton setEnabled: NO];

      revertButton = nil;
    }
  return self;
}

- (void) ok: (id)sender
{
  NSString	*name = [[browser selectedCell] stringValue];
  unsigned	pos;

  if (name == nil || (pos = [sets indexOfObject: name]) == NSNotFound)
    {
      [label setTitle: _(@"No Type")];
      [value setStringValue: @""];
      [okButton setEnabled: NO];
    }
  else
    {
      SEL	set = NSSelectorFromString(name);
      NSString	*type = [types objectForKey: name];
      
      [super ok: sender];
      if (type == typeChar)
	{
	  char	v = [value intValue];
	  void	(*imp)(id,SEL,char);

	  imp = (void (*)(id,SEL,char))[object methodForSelector: set];
	  (*imp)(object, set, v);
	}
      else if (type == typeUChar)
	{
	  unsigned char	v = [value intValue];
	  void		(*imp)(id,SEL,unsigned char);

	  imp = (void (*)(id,SEL,unsigned char))[object methodForSelector: set];
	  (*imp)(object, set, v);
	}
      else if (type == typeInt)
	{
	  int	v = [value intValue];
	  void	(*imp)(id,SEL,int);

	  imp = (void (*)(id,SEL,int))[object methodForSelector: set];
	  (*imp)(object, set, v);
	}
      else if (type == typeUInt)
	{
	  unsigned int	v = [value intValue];
	  void		(*imp)(id,SEL,unsigned int);

	  imp = (void (*)(id,SEL,unsigned int))[object methodForSelector: set];
	  (*imp)(object, set, v);
	}
      else if (type == typeFloat)
	{
	  float	v = [value floatValue];
	  void	(*imp)(id,SEL,float);

	  imp = (void (*)(id,SEL,float))[object methodForSelector: set];
	  (*imp)(object, set, v);
	}
      else if (type == typeDouble)
	{
	  float	v = [value doubleValue];
	  void	(*imp)(id,SEL,double);

	  imp = (void (*)(id,SEL,double))[object methodForSelector: set];
	  (*imp)(object, set, v);
	}
      else
	{
	  id	v = [value stringValue];
	  IMP	imp = [object methodForSelector: set];

	  if (isString == YES)
	    {
	      (*imp)(object, set, v);
	    }
	  else
	    {
	      int	result;

	      v = [v stringByTrimmingSpaces];
	      result = NSRunAlertPanel(_(@"Settings"),
		[NSString stringWithFormat: _(@"Set object using '%@' as"), v],
				       _(@"Object name"),_( @"String"), _(@"Class name"));
	      if (result == NSAlertAlternateReturn)
		{
		  (*imp)(object, set, v);
		}
	      else if (result == NSAlertOtherReturn)
		{
		  Class	c = NSClassFromString(v);

		  if (c != 0)
		    {
		      (*imp)(object, set, [c new]);
		    }
		}
	      else
		{
		  id	o = [[(id<IB>)NSApp activeDocument] objectForName: v];

		  if (o != nil)
		    {
		      (*imp)(object, set, o);
		    }
		}
	    }
	}
      [self updateButtons];
    }
}

- (void) setObject: (id)anObject
{
  if (anObject != nil && anObject != object)
    {
      Class	c = [anObject class];

      ASSIGN(object, anObject);
      [sets removeAllObjects];
      [gets removeAllObjects];
      [types removeAllObjects];

      while (c != nil && c != [NSObject class])
	{
	  struct objc_method_list	*mlist = c->methods;

	  while (mlist != 0)
	    {
	      struct objc_method	*methods = &mlist->method_list[0];
	      int			count = mlist->method_count;
	      int			i;

	      for (i = 0; i < count; i++)
		{
		  SEL		sSel = methods[i].method_name;
		  NSString	*set = NSStringFromSelector(sSel);

		  /*
		   * We are interested in methods that set values - they have
		   * a 'set' prefic and a colon as the last character.
		   * we ignore duplicates from superclasses.
		   */
		  if ([set hasPrefix: @"set"] == YES
		    && [set rangeOfString: @":"].location == [set length] - 1
		    && [sets containsObject: set] == NO)
		    {
		      char		tmp[[set cStringLength]+1];
		      const char	*tInfo = methods[i].method_types;
		      NSString		*type = nil;
		      NSString		*get;
		      SEL		gSel;

		      /*
		       * see if we can find an appropriate method to get the
		       * current value for an attribute we want to set.
		       */
		      [set getCString: tmp];
		      tmp[3] = tolower(tmp[3]);
		      tmp[strlen(tmp)-1] = '\0';
		      get = [NSString stringWithCString: &tmp[3]];
		      gSel = NSSelectorFromString(get);
		      if (gSel == 0 || [object respondsToSelector: gSel] == NO)
			{
			  get = nil;
			}

		      /*
		       * Skip the return type and the receiver and
		       * selector specifications to the first (only) arg.
		       */
		      tInfo = objc_skip_typespec(tInfo);
		      if (*tInfo == '+')
			{
			  tInfo++;
			}
		      while (isdigit(*tInfo))
			{
			  tInfo++;
			}
		      tInfo = objc_skip_argspec(tInfo);
		      tInfo = objc_skip_argspec(tInfo);

		      /*
		       * Now find arguments whose types we can reasonably
		       * deal with.
		       */
		      switch (*tInfo)
			{
			  case _C_ID:
			    type = typeId;
			    break;
			  case _C_CHR:
			    type = typeChar;
			    break;
			  case _C_UCHR:
			    type = typeUChar;
			    break;
			  case _C_INT:
			    type = typeInt;
			    break;
			  case _C_UINT:
			    type = typeUInt;
			    break;
			  case _C_FLT:
			    type = typeFloat;
			    break;
			  case _C_DBL:
			    type = typeDouble;
			    break;
			  default:
			    type = nil;
			    break;
			}
		      if (type != nil)
			{
			  [sets addObject: set];
			  if (get != nil)
			    {
			      [gets setObject: get forKey: set];
			    }
			  [types setObject: type forKey: set];
			}
		    }
		}
	      mlist = mlist->method_next;
	    }
	  c = [c superclass]; 
	}
      [sets sortUsingSelector: @selector(compare:)];
      [browser loadColumnZero];
      [self updateButtons];
    }
}

- (void) updateButtons
{
  NSString	*name = [[browser selectedCell] stringValue];
  unsigned	pos;

  isString = NO;
  if (name == nil || (pos = [sets indexOfObject: name]) == NSNotFound)
    {
      [label setTitle: _(@"No Type")];
      [value setStringValue: @""];
      [okButton setEnabled: NO];
    }
  else if ([gets objectForKey: name] != nil)
    {
      SEL	get = NSSelectorFromString([gets objectForKey: name]);
      NSString	*type = [types objectForKey: name];

      [label setTitle: type];
      if (type == typeChar)
	{
	  char	v;
	  char	(*imp)();

	  imp = (char (*)())[object methodForSelector: get];
	  v = (*imp)(object, get);
	  [value setStringValue: [NSString stringWithFormat: @"%d", v]];
	}
      else if (type == typeUChar)
	{
	  unsigned char	v;
	  unsigned char	(*imp)();

	  imp = (unsigned char (*)())[object methodForSelector: get];
	  v = (*imp)(object, get);
	  [value setStringValue: [NSString stringWithFormat: @"%d", v]];
	}
      else if (type == typeInt)
	{
	  int	v;
	  int	(*imp)();

	  imp = (int (*)())[object methodForSelector: get];
	  v = (*imp)(object, get);
	  [value setStringValue: [NSString stringWithFormat: @"%d", v]];
	}
      else if (type == typeUInt)
	{
	  unsigned	v;
	  unsigned	(*imp)();

	  imp = (unsigned int (*)()) [object methodForSelector: get];
	  v = (*imp)(object, get);
	  [value setStringValue: [NSString stringWithFormat: @"%u", v]];
	}
      else if (type == typeFloat)
	{
	  float	v;
	  float	(*imp)();

	  imp = (float (*)())[object methodForSelector: get];
	  v = (*imp)(object, get);
	  [value setStringValue: [NSString stringWithFormat: @"%f", v]];
	}
      else if (type == typeDouble)
	{
	  double	v;
	  double	(*imp)();

	  imp = (double (*)())[object methodForSelector: get];
	  v = (*imp)(object, get);
	  [value setStringValue: [NSString stringWithFormat: @"%g", v]];
	}
      else
	{
	  id	v;
	  IMP	imp = [object methodForSelector: get];

	  v = (*imp)(object, get);
	  if (v != nil && [v isKindOfClass: [NSString class]] == YES)
	    {
	      isString = YES;	/* Existing value is a string. */
	    }
	  [value setStringValue: [v description]];
	}
      [okButton setEnabled: YES];
    }
  else
    {
      [label setTitle: [NSString stringWithFormat: _(@"%@ - value unknown"),
	[types objectForKey: name]]];
      [value setStringValue: @""];
      [okButton setEnabled: YES];
    }
}

- (BOOL) wantsButtons
{
  return YES;
}
@end

