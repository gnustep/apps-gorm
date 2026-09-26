#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>

@interface NSMatrix (GSNixCompatibility)
- (id) gormNixInitWithCoder: (NSCoder *)coder;
@end


@implementation NSMatrix (GSNixCompatibility)

+ (void) gormInstallNixCodingCompatibility
{
  static BOOL installed = NO;
  if (!installed)
    {
      method_exchangeImplementations(
        class_getInstanceMethod(self, @selector(initWithCoder:)),
        class_getInstanceMethod(self, @selector(gormNixInitWithCoder:)));
      installed = YES;
    }
}

- (id) gormNixInitWithCoder: (NSCoder *)coder
{
  NSArray *cells;
  NSInteger rows;
  NSInteger columns;
  NSInteger index;
  NSRect frame;
  NSCell *prototype;
  Class cellClass;

  if (![NSStringFromClass([coder class])
        isEqualToString: @"GSNixKeyedDecodingCoder"])
    return [self gormNixInitWithCoder: coder];

  frame = [coder containsValueForKey: @"NSFrame"]
    ? [coder decodeRectForKey: @"NSFrame"] : NSZeroRect;
  prototype = [coder decodeObjectForKey: @"NSProtoCell"];
  if (prototype != nil)
    self = [self initWithFrame: frame mode: NSRadioModeMatrix
                     prototype: prototype numberOfRows: 0 numberOfColumns: 0];
  else
    {
      cellClass = NSClassFromString([coder decodeObjectForKey: @"NSCellClass"]);
      if (cellClass == Nil)
        cellClass = [NSActionCell class];
      self = [self initWithFrame: frame mode: NSRadioModeMatrix
                      cellClass: cellClass numberOfRows: 0 numberOfColumns: 0];
    }
  if (self == nil)
    return nil;

  if ([coder containsValueForKey: @"NSBackgroundColor"])
    [self setBackgroundColor: [coder decodeObjectForKey: @"NSBackgroundColor"]];
  if ([coder containsValueForKey: @"NSCellBackgroundColor"])
    [self setCellBackgroundColor:
      [coder decodeObjectForKey: @"NSCellBackgroundColor"]];
  if ([coder containsValueForKey: @"NSCellSize"])
    [self setCellSize: [coder decodeSizeForKey: @"NSCellSize"]];
  if ([coder containsValueForKey: @"NSIntercellSpacing"])
    [self setIntercellSpacing: [coder decodeSizeForKey: @"NSIntercellSpacing"]];
  if ([coder containsValueForKey: @"NSEnabled"])
    [self setEnabled: [coder decodeBoolForKey: @"NSEnabled"]];

  rows = [coder decodeIntForKey: @"NSNumRows"];
  columns = [coder decodeIntForKey: @"NSNumCols"];
  cells = [coder decodeObjectForKey: @"NSCells"];
  [self renewRows: 0 columns: columns];
  if ([cells count] == (NSUInteger)(rows * columns))
    for (index = 0; index < rows; index++)
      [self addRowWithCells: [cells subarrayWithRange:
        NSMakeRange(index * columns, columns)]];
  else
    [self renewRows: rows columns: columns];

  if ([coder containsValueForKey: @"NSSelectedRow"]
      && [coder containsValueForKey: @"NSSelectedCol"])
    {
      NSInteger selectedRow = [coder decodeIntForKey: @"NSSelectedRow"];
      NSInteger selectedColumn = [coder decodeIntForKey: @"NSSelectedCol"];
      if (selectedRow >= 0 && selectedRow < rows
          && selectedColumn >= 0 && selectedColumn < columns)
        [self selectCellAtRow: selectedRow column: selectedColumn];
    }
  return self;
}

@end
