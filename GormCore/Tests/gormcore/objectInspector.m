/* Regression coverage for the fallback inspector's actual controls. */
#import "Testing.h"
#import <AppKit/AppKit.h>
#import <GormCore/GormObjectInspector.h>
#include <limits.h>

@interface InspectorFixture : NSObject
{
  signed char small;
  unsigned char byte;
  short shortValue;
  unsigned short unsignedShort;
  int integer;
  unsigned int unsignedInteger;
  long longValue;
  unsigned long unsignedLong;
  long long wide;
  unsigned long long unsignedWide;
  _Bool boolean;
  BOOL enabled;
  float real;
  double precise;
  NSString *text;
  int writes;
  int reads;
}
- (int) writes;
- (int) reads;
@end

@implementation InspectorFixture
#define ACCESSORS(type, getter, setter, field) \
- (type) getter { return field; } \
- (void) setter: (type)v { field = v; writes++; }
ACCESSORS(signed char, small, setSmall, small)
ACCESSORS(unsigned char, byte, setByte, byte)
ACCESSORS(short, shortValue, setShortValue, shortValue)
ACCESSORS(unsigned short, unsignedShort, setUnsignedShort, unsignedShort)
ACCESSORS(int, integer, setInteger, integer)
ACCESSORS(unsigned int, unsignedInteger, setUnsignedInteger, unsignedInteger)
ACCESSORS(long, longValue, setLongValue, longValue)
ACCESSORS(unsigned long, unsignedLong, setUnsignedLong, unsignedLong)
ACCESSORS(long long, wide, setWide, wide)
ACCESSORS(unsigned long long, unsignedWide, setUnsignedWide, unsignedWide)
ACCESSORS(_Bool, boolean, setBoolean, boolean)
ACCESSORS(BOOL, isEnabled, setEnabled, enabled)
ACCESSORS(float, real, setReal, real)
ACCESSORS(double, precise, setPrecise, precise)
#undef ACCESSORS
- (NSString *) text { reads++; return text; }
- (int) reads { return reads; }
- (void) setText: (NSString *)v { ASSIGNCOPY(text, v); writes++; }
- (id) absent { return nil; }
- (void) setAbsent: (id)v { }
- (int) writes { return writes; }
- (void) setWriteOnly: (int)v { integer = v; writes++; }
- (double) mismatched { return 123.5; }
- (void) setMismatched: (int)v { integer = v; writes++; }
- (NSPoint) point { return NSZeroPoint; }
- (void) setPoint: (NSPoint)v { }
- (void) setPair: (int)a other: (int)b { }
- (int) setNonvoid: (int)v { return v; }
- (int) broken { [NSException raise: @"Test" format: @"Getter failed"]; return 0; }
- (void) setBroken: (int)v { }
- (int) rejected { return 0; }
- (void) setRejected: (int)v { [NSException raise: @"Test" format: @"Setter failed"]; }
- (void) dealloc { [text release]; [super dealloc]; }
@end

@interface InspectorChild : InspectorFixture
@end
@implementation InspectorChild
- (void) setInteger: (int)v { [super setInteger: v]; }
@end

@interface TestObjectInspector : GormObjectInspector
{
  int touches;
}
- (BOOL) select: (NSString *)setter;
- (void) enter: (NSString *)text;
- (NSString *) displayed;
- (NSString *) status;
- (NSArray *) setters;
- (NSDictionary *) getters;
- (int) touches;
- (id) tableValue: (NSString *)column setter: (NSString *)setter;
- (NSTableView *) table;
@end
@implementation TestObjectInspector
- (BOOL) select: (NSString *)setter
{
  NSUInteger row = [sets indexOfObject: setter];
  if (row == NSNotFound) return NO;
  [propertyTable selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
             byExtendingSelection: NO];
  [self update: self];
  return YES;
}
- (void) enter: (NSString *)text
{
  [value setStringValue: text];
  [self ok: self];
}
- (NSString *) displayed { return [value stringValue]; }
- (NSString *) status { return [label title]; }
- (NSArray *) setters { return sets; }
- (NSDictionary *) getters { return gets; }
- (int) touches { return touches; }
- (NSTableView *) table { return propertyTable; }
- (id) tableValue: (NSString *)column setter: (NSString *)setter
{
  return [(id)[propertyTable dataSource] tableView: propertyTable
    objectValueForTableColumn: [propertyTable tableColumnWithIdentifier: column]
    row: [sets indexOfObject: setter]];
}
- (void) touch: (id)sender { touches++; }
@end

static void
roundTrip(TestObjectInspector *inspector, NSString *setter, NSString *text)
{
  int before = [inspector touches];
  PASS([inspector select: setter], "supported setter appears in table");
  [inspector enter: text];
  PASS_EQUAL([inspector displayed], text, "scalar value displays without truncation");
  PASS([inspector touches] == before + 1, "successful edit touches document once");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  TestObjectInspector *inspector;
  InspectorFixture *fixture;
  NSArray *invalid;
  NSUInteger i;
  int before, touches;

  [NSApplication sharedApplication];
  inspector = [TestObjectInspector new];
  fixture = [InspectorChild new];
  PASS(inspector != nil && [inspector window] != nil,
       "fallback inspector loads its real archived UI");
  NSLog(@"Inspector resource bundle: %@", [NSBundle bundleForClass:
    [GormObjectInspector class]]);
  [fixture setText: @"original"];
  [inspector setObject: fixture];
  PASS([[inspector setters] count] == 20,
       "inherited setters are unique and unsupported signatures are excluded");
  PASS_EQUAL([[inspector getters] objectForKey: @"setEnabled:"], @"isEnabled",
             "Boolean getter naming is recognized");
  PASS([[inspector getters] objectForKey: @"setMismatched:"] == nil,
       "incompatible getter is never invoked");

  PASS([[inspector table] numberOfRows] == 20
       && [[[inspector table] tableColumns] count] == 3,
       "table presents property, type and value columns for every setter");
  PASS_EQUAL([inspector tableValue: @"property" setter: @"setText:"], @"text",
             "table displays property names instead of setter selectors");
  PASS_EQUAL([inspector tableValue: @"type" setter: @"setPrecise:"], @"Double",
             "table displays the property's type");
  PASS_EQUAL([inspector tableValue: @"value" setter: @"setText:"], @"original",
             "unselected rows show current values");
  PASS_EQUAL([inspector tableValue: @"value" setter: @"setBroken:"],
             @"Unable to read value", "getter errors are isolated to their row");
  PASS_EQUAL([inspector tableValue: @"value" setter: @"setWriteOnly:"],
             @"Value unknown", "write-only rows are explicitly marked");
  PASS([fixture reads] == 1,
       "drawing table cells uses cached values instead of repeatedly invoking getters");
  {
    CGFloat total = 0;
    NSEnumerator *columns = [[[inspector table] tableColumns] objectEnumerator];
    NSTableColumn *column;
    while ((column = [columns nextObject]) != nil)
      total += [column width];
    PASS(total <= [[[inspector table] enclosingScrollView] contentSize].width,
         "all three columns fit within the inspector at its default width");
  }
  PASS([fixture writes] == 1 && [inspector touches] == 0,
       "populating the table does not call setters or mark the document edited");

  roundTrip(inspector, @"setSmall:", @"-128");
  roundTrip(inspector, @"setByte:", @"255");
  roundTrip(inspector, @"setShortValue:", @"-32768");
  roundTrip(inspector, @"setUnsignedShort:", @"65535");
  roundTrip(inspector, @"setInteger:", @"-2147483648");
  roundTrip(inspector, @"setUnsignedInteger:", @"4294967295");
  roundTrip(inspector, @"setLongValue:", [NSString stringWithFormat: @"%ld", LONG_MIN]);
  roundTrip(inspector, @"setUnsignedLong:", [NSString stringWithFormat: @"%lu", ULONG_MAX]);
  roundTrip(inspector, @"setWide:", @"-9223372036854775808");
  roundTrip(inspector, @"setUnsignedWide:", @"18446744073709551615");
  roundTrip(inspector, @"setBoolean:", @"1");
  roundTrip(inspector, @"setEnabled:", @"1");
  roundTrip(inspector, @"setReal:", @"1.25");
  roundTrip(inspector, @"setPrecise:", @"1.2345678901234567");
  PASS([fixture precise] == 1.2345678901234567,
       "double setter preserves more than float precision");

  [inspector select: @"setByte:"];
  invalid = [NSArray arrayWithObjects: @"256", @"-1", @"abc", @"12 trailing",
    @"", @"1.5", @"18446744073709551616", nil];
  before = [fixture writes];
  touches = [inspector touches];
  for (i = 0; i < [invalid count]; i++)
    [inspector enter: [invalid objectAtIndex: i]];
  PASS([fixture writes] == before && [inspector touches] == touches,
       "invalid, overflowing and negative unsigned input never changes document");
  [inspector select: @"setSmall:"];
  [inspector enter: @"-129"];
  [inspector select: @"setBoolean:"];
  [inspector enter: @"2"];
  [inspector select: @"setReal:"];
  [inspector enter: @"1e100"];
  [inspector enter: @"1e-100"];
  [inspector select: @"setPrecise:"];
  [inspector enter: @"nan"];
  [inspector enter: @"inf"];
  [inspector enter: @"1e999"];
  PASS([fixture writes] == before && [inspector touches] == touches,
       "signed range, Boolean range and nonfinite or overflowing floats are rejected");
  [inspector enter: @" 2.5 "];
  PASS([fixture precise] == 2.5, "valid edit succeeds after rejected input");
  [inspector setObject: fixture];
  PASS_EQUAL([inspector displayed], @"2.5", "refreshing same object preserves selected setter");
  [fixture setPrecise: 3.5];
  [inspector revert: nil];
  PASS_EQUAL([inspector displayed], @"3.5", "revert refreshes the current value");

  [inspector select: @"setText:"];
  [inspector enter: @"  new text  "];
  PASS_EQUAL([fixture text], @"  new text  ", "string edit preserves whitespace");
  [inspector select: @"setAbsent:"];
  PASS_EQUAL([inspector displayed], @"", "nil object value displays safely");
  [inspector select: @"setWriteOnly:"];
  [inspector enter: @"42"];
  PASS([fixture integer] == 42, "write-only attributes remain editable");
  PASS_EQUAL([inspector tableValue: @"value" setter: @"setInteger:"], @"42",
             "applying a setter refreshes other dependent rows");
  [inspector select: @"setBroken:"];
  PASS(![[inspector okButton] isEnabled], "throwing getter disables apply");
  [inspector select: @"setRejected:"];
  touches = [inspector touches];
  [inspector enter: @"1"];
  PASS([inspector touches] == touches, "throwing setter does not report success");
  roundTrip(inspector, @"setInteger:", @"42");
  [inspector setObject: nil];
  PASS([inspector object] == nil && [[inspector setters] count] == 0
       && ![[inspector okButton] isEnabled], "clearing selection releases stale inspected object");
  PASS_EQUAL([inspector displayed], @"", "clearing selection clears old value");
  PASS([[inspector table] numberOfRows] == 0,
       "clearing selection removes all table rows");
  [inspector setObject: fixture];
  PASS([[inspector table] selectedRow] == -1 && ![[inspector okButton] isEnabled],
       "a newly inspected object never inherits a stale property selection");
  [inspector setObject: nil];
  [fixture release];
  [inspector release];
  [pool drain];
  return 0;
}
