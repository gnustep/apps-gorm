#import "NSString+methods.h"

#import <Foundation/NSScanner.h>
#import <Foundation/NSCharacterSet.h>

// NSString category methods to add functionality to NSString

@implementation NSString (Methods)

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
