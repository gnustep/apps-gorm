// This file is under the terms of the LGPL version 2.1 or later, See COPYING.LIB for details

#ifndef INCLUDED_NSString_methods_H
#define INCLUDED_NSString_methods_H

#import <Foundation/NSString.h>

@interface NSString (Methods)

- (NSString *) capitalizedFirstCharacterString;
- (NSString *) splitCamelCaseString;
- (NSString *) splitCamelCaseStringStartingFromIndex: (NSUInteger)index;
- (NSString *) lowercaseFirstCharacterString;

@end

#endif
