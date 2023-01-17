#import "NSString+methods.h"

#import <Foundation/NSScanner.h>
#import <Foundation/NSCharacterSet.h>

// NSString category methods to add functionality to NSString

@implementation NSString (Methods)

// Return a string with the first character capitalized
- (NSString *) capitalizedFirstCharacterString
{
    if ([self length] == 0)
      {
        return self;
      }
    
    return [NSString stringWithFormat: @"%@%@", 
                     [[self substringToIndex: 1] uppercaseString],
                     [self substringFromIndex: 1]];
}

- (NSString *) splitCamelCaseStringStartingFromIndex: (NSUInteger)index
{
    NSString *newString = [self substringFromIndex: index];
    NSString *firstPartOfString = [newString substringToIndex: index];

    NSString *result = [newString splitCamelCaseString];
    return [NSString stringWithFormat: @"%@%@", firstPartOfString, result];
}

// Split a camel case string into a string with spaces
// e.g. "camelCaseString" becomes "camel Case String"
- (NSString *) splitCamelCaseString
{
    NSMutableString *result = [NSMutableString string];
    NSScanner *scanner = [NSScanner scannerWithString: self];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *lowercase = [NSCharacterSet lowercaseLetterCharacterSet];
    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
    NSString *buffer;

    while (![scanner isAtEnd]) 
      {
        if ([scanner scanCharactersFromSet: uppercase intoString: &buffer])
          {
            [result appendString: buffer];
          }
        
        if ([scanner scanCharactersFromSet: lowercase intoString: &buffer])
          {
            if ([result length] > 0)
              {
                [result appendString: @" "];
              }
            
            [result appendString: [buffer capitalizedString]];
        }
        if ([scanner scanCharactersFromSet: letters intoString: &buffer])
          {
            [result appendString: buffer];
          }
      }
    
    return result;
}

@end
