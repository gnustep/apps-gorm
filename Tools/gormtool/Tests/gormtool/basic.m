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
#import "ArgPair.h"
#import "../../ArgPair.m"

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  ArgPair *pair;
  ArgPair *copy;

  START_SET("gormtool")

  pair = AUTORELEASE([[ArgPair alloc] init]);
  PASS([pair argument] == nil && [pair value] == nil,
       "ArgPair starts empty")
  [pair setArgument: @"--input"];
  [pair setValue: @"Model.gorm"];
  PASS([[pair argument] isEqual: @"--input"] &&
       [[pair value] isEqual: @"Model.gorm"],
       "ArgPair stores its argument and value")

  copy = AUTORELEASE([pair copy]);
  PASS(copy != pair &&
       [[copy argument] isEqual: [pair argument]] &&
       [[copy value] isEqual: [pair value]],
       "ArgPair copies its stored argument and value")

  [pair setArgument: @"--output"];
  [pair setValue: @"Model.nib"];
  PASS([[copy argument] isEqual: @"--input"] &&
       [[copy value] isEqual: @"Model.gorm"],
       "ArgPair copies are independent after mutation")

  END_SET("gormtool")

  RELEASE(pool);
  return 0;
}
