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
#import "../../2Controls/inspectors.m"

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSButton *button = [NSButton alloc];

  START_SET("Button inspector selection")

  PASS([[button inspectorClassName]
         isEqual: @"GormButtonAttributesInspector"],
       "buttons select their dedicated attributes inspector")

  END_SET("Button inspector selection")

  RELEASE(button);
  RELEASE(pool);
  return 0;
}
