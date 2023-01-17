// This file is under the terms of the GPLv3, See COPYING for details

#ifndef INCLUDED_NSString_methods_H
#define INCLUDED_NSString_methods_H

#import <Foundation/NSString.h>

@interface NSString (Methods)

- (NSString *) capitalizedFirstCharacterString;
- (NSString *) splitCamelCaseString;

@end

#endif
