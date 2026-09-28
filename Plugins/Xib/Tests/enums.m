/* Regression checks for XIB tokens emitted from real AppKit objects.
 * Run from the repository root after building Plugins/Xib. */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GormCore/GormCore.h>
#import "../GormXIBArchiver.h"

@interface GormXIBArchiver (EnumTests)
- (void) _addProperty: (NSString *)name withType: (NSString *)type
           toElement: (NSXMLElement *)element fromObject: (id)object;
@end

/* Supply only document metadata; all archived controls are real AppKit
 * objects and go through the full writer rather than a mock property path. */
@interface EnumDocument : NSObject
{
  NSSet *_objects;
}
- (id) initWithObjects: (NSSet *)objects;
@end
@implementation EnumDocument
- (id) initWithObjects: (NSSet *)objects
{
  self = [super init];
  if (self) _objects = [objects retain];
  return self;
}
- (void) dealloc { [_objects release]; [super dealloc]; }
- (NSSet *) topLevelObjects { return _objects; }
- (id) filesOwner { return nil; }
- (id) servicesMenu { return nil; }
- (NSString *) nameForObject: (id)object { return nil; }
- (NSArray *) connectorsForSource: (id)object ofClass: (Class)class { return nil; }
- (void) deactivateEditors {}
- (void) reactivateEditors {}
@end

static void check(id archiver, id object, NSString *key, NSString *expected)
{
  NSXMLElement *element = [NSXMLElement elementWithName: @"test"];
  [archiver _addProperty: key withType: @"unsigned long long"
              toElement: element fromObject: object];
  NSString *actual = [[element attributeForName: key] stringValue];
  if (!(actual == expected || [actual isEqual: expected]))
    [NSException raise: @"TestFailure" format: @"%@: expected %@, got %@",
                 key, expected, actual];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  @try
    {
  [NSApplication sharedApplication];
  /* Ensure GormCore is linked before loading the plugin. */
  [GormDocument class];
  NSBundle *bundle = [NSBundle bundleWithPath:
    [[[NSFileManager defaultManager] currentDirectoryPath]
      stringByAppendingPathComponent: @"Plugins/Xib/Xib.plugin"]];
  if (![bundle load]) return 1;
  id archiver = [[NSClassFromString(@"GormXIBArchiver") alloc]
    initForWritingWithGormDocument: nil classNameMappings: nil];
  NSButtonCell *cell = [[NSButtonCell alloc] initTextCell: @"Button"];
  [cell setControlSize: NSRegularControlSize];
  check(archiver, cell, @"controlSize", @"regular");
  [cell setControlSize: NSSmallControlSize];
  check(archiver, cell, @"controlSize", @"small");
  [cell setControlTint: NSGraphiteControlTint];
  check(archiver, cell, @"controlTint", @"graphite");
  [cell setAllowsMixedState: YES];
  [cell setState: NSMixedState];
  check(archiver, cell, @"state", @"mixed");
  [cell setState: NSOffState];
  check(archiver, cell, @"state", nil);
  [cell setFocusRingType: NSFocusRingTypeNone];
  check(archiver, cell, @"focusRingType", @"none");
  [cell setLineBreakMode: NSLineBreakByTruncatingTail];
  check(archiver, cell, @"lineBreakMode", @"truncatingTail");
  [cell setImageScaling: NSImageScaleNone];
  check(archiver, cell, @"imageScaling", nil);
  [cell setButtonType: NSMomentaryPushInButton];
  check(archiver, cell, @"type", @"push");
  NSPopUpButton *popup = [[NSPopUpButton alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 24) pullsDown: NO];
  [popup addItemsWithTitles: [NSArray arrayWithObjects: @"One", @"Two", nil]];
  [[popup cell] setArrowPosition: NSPopUpArrowAtCenter];
  check(archiver, [popup cell], @"arrowPosition", @"arrowAtCenter");
  [popup setPreferredEdge: NSMaxYEdge];
  check(archiver, popup, @"preferredEdge", @"maxY");
  check(archiver, popup, @"nextKeyView", nil);
  check(archiver, popup, @"previousKeyView", nil);
  check(archiver, [popup cell], @"controlView", nil);
  NSBox *box = [[NSBox alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  [box setBoxType: NSBoxPrimary];
  check(archiver, box, @"boxType", @"primary");
  [box setBorderType: NSGrooveBorder];
  check(archiver, box, @"borderType", @"groove");
  [cell setTag: 23];
  check(archiver, cell, @"tag", @"23");

  NSProgressIndicator *progress = [[NSProgressIndicator alloc]
    initWithFrame: NSMakeRect(0, 200, 100, 20)];
  [progress setStyle: NSProgressIndicatorBarStyle];
  check(archiver, progress, @"style", @"bar");
  [progress setStyle: NSProgressIndicatorSpinningStyle];
  check(archiver, progress, @"style", @"spinning");
  [progress setStyle: NSProgressIndicatorBarStyle];
  [progress setIndeterminate: NO];
  [progress setDoubleValue: 25];
  NSProgressIndicator *spinner = [[NSProgressIndicator alloc]
    initWithFrame: NSMakeRect(120, 200, 20, 20)];
  [spinner setStyle: NSProgressIndicatorSpinningStyle];
  [spinner setIndeterminate: YES];

  NSView *view = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 400, 300)];
  NSSlider *verticalSlider = [[NSSlider alloc]
    initWithFrame: NSMakeRect(350, 20, 20, 100)];
  [verticalSlider setNumberOfTickMarks: 5];
  [verticalSlider setTickMarkPosition: NSTickMarkLeft];
  check(archiver, [verticalSlider cell], @"sliderType", @"linear");
  check(archiver, [verticalSlider cell], @"tickMarkPosition", @"below");
  NSSlider *horizontalSlider = [[NSSlider alloc]
    initWithFrame: NSMakeRect(200, 270, 100, 20)];
  [horizontalSlider setNumberOfTickMarks: 3];
  [horizontalSlider setTickMarkPosition: NSTickMarkAbove];
  check(archiver, [horizontalSlider cell], @"tickMarkPosition", @"above");
  [[horizontalSlider cell] setSliderType: NSCircularSlider];
  check(archiver, [horizontalSlider cell], @"sliderType", @"circular");
  [[horizontalSlider cell] setSliderType: NSLinearSlider];
  [view addSubview: verticalSlider];
  [view addSubview: horizontalSlider];
  [view addSubview: progress];
  [view addSubview: spinner];
  [view addSubview: popup];
  [view addSubview: box];
  NSBrowser *browser = [[NSBrowser alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)];
  [browser setColumnResizingType: NSBrowserAutoColumnResizing];
  check(archiver, browser, @"columnResizingType", @"auto");
  [browser setColumnResizingType: NSBrowserUserColumnResizing];
  check(archiver, browser, @"columnResizingType", @"user");
  [browser setColumnResizingType: NSBrowserNoColumnResizing];
  check(archiver, browser, @"columnResizingType", nil);
  if ([[browser subviews] count] == 0)
    [NSException raise: @"TestFailure" format: @"Browser must have internal views for this test"];
  [view addSubview: browser];
  NSScrollView *outlineScroll = [[NSScrollView alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)];
  [outlineScroll setHasVerticalScroller: YES];
  [outlineScroll setHasHorizontalScroller: YES];
  NSOutlineView *outline = [[NSOutlineView alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)];
  NSTableColumn *outlineColumn = [[NSTableColumn alloc] initWithIdentifier: @"name"];
  [[outlineColumn headerCell] setStringValue: @"Name"];
  [[outlineColumn headerCell] setFont: [NSFont boldSystemFontOfSize: 14]];
  [outline addTableColumn: outlineColumn];
  [outline setOutlineTableColumn: outlineColumn];
  /* GNUstep currently stubs this accessor to NoColumnAutoresizing. */
  [outline setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
  check(archiver, outline, @"columnAutoresizingStyle", @"none");
  [outline setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleNone];
  check(archiver, outline, @"selectionHighlightStyle", @"none");
  [outline setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleSourceList];
  check(archiver, outline, @"selectionHighlightStyle", @"sourceList");
  [outline setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleRegular];
  check(archiver, outline, @"selectionHighlightStyle", @"regular");
  [outlineScroll setHorizontalScrollElasticity: NSScrollElasticityNone];
  check(archiver, outlineScroll, @"horizontalScrollElasticity", @"none");
  [outlineScroll setVerticalScrollElasticity: NSScrollElasticityAllowed];
  check(archiver, outlineScroll, @"verticalScrollElasticity", @"allowed");
  [outlineScroll setHorizontalScrollElasticity: NSScrollElasticityAutomatic];
  [outlineScroll setVerticalScrollElasticity: NSScrollElasticityAutomatic];
  check(archiver, outlineScroll, @"horizontalScrollElasticity", nil);
  check(archiver, outlineScroll, @"verticalScrollElasticity", nil);
  NSScroller *testScroller = [outlineScroll verticalScroller];
  /* GNUstep exposes only legacy/default scroller styles at runtime. */
  check(archiver, testScroller, @"scrollerStyle", @"legacy");
  check(archiver, testScroller, @"knobStyle", nil);
  [outlineScroll setDocumentView: outline];
  [view addSubview: outlineScroll];
  NSTextView *textView = [[NSTextView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 100)];
  [textView setString: @"Text view contents"];
  [textView setSelectionGranularity: NSSelectByWord];
  check(archiver, textView, @"selectionGranularity", @"word");
  [textView setSelectionGranularity: NSSelectByParagraph];
  check(archiver, textView, @"selectionGranularity", @"paragraph");
  [textView setSelectionGranularity: NSSelectByCharacter];
  check(archiver, textView, @"selectionGranularity", nil);
  [view addSubview: textView];
  NSImageView *imageView = [[NSImageView alloc]
    initWithFrame: NSMakeRect(0, 0, 80, 80)];
  NSArray *imageAlignments = [@"center top topLeft topRight left bottom bottomLeft bottomRight right"
    componentsSeparatedByString: @" "];
  for (NSUInteger i = 0; i < [imageAlignments count]; ++i)
    {
      [imageView setImageAlignment: i];
      check(archiver, imageView, @"imageAlignment", [imageAlignments objectAtIndex: i]);
      check(archiver, [imageView cell], @"imageAlignment", [imageAlignments objectAtIndex: i]);
    }
  NSArray *imageFrames = [@"none photo grayBezel groove button" componentsSeparatedByString: @" "];
  for (NSUInteger i = 0; i < [imageFrames count]; ++i)
    {
      [imageView setImageFrameStyle: i];
      check(archiver, imageView, @"imageFrameStyle", [imageFrames objectAtIndex: i]);
      check(archiver, [imageView cell], @"imageFrameStyle", [imageFrames objectAtIndex: i]);
    }
  [imageView setImageAlignment: NSImageAlignCenter];
  [imageView setImageFrameStyle: NSImageFramePhoto];
  [view addSubview: imageView];
  NSComboBox *comboBox = [[NSComboBox alloc]
    initWithFrame: NSMakeRect(0, 0, 120, 24)];
  [comboBox addItemsWithObjectValues: [NSArray arrayWithObjects:
    @"One", @"A & B < C", @"", nil]];
  [view addSubview: comboBox];
  NSComboBox *emptyComboBox = [[NSComboBox alloc]
    initWithFrame: NSMakeRect(0, 30, 120, 24)];
  [view addSubview: emptyComboBox];
  NSTextView *wordTextView = [[NSTextView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 100)];
  [wordTextView setSelectionGranularity: NSSelectByWord];
  [view addSubview: wordTextView];
  NSTextView *paragraphTextView = [[NSTextView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 100)];
  [paragraphTextView setSelectionGranularity: NSSelectByParagraph];
  [view addSubview: paragraphTextView];
  NSButton *button = [[NSButton alloc] initWithFrame: NSMakeRect(0, 100, 90, 24)];
  [button setButtonType: NSMomentaryPushInButton];
  [button setFont: [NSFont systemFontOfSize: 13]];
  [view addSubview: button];
  NSTextField *textField = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 150, 100, 24)];
  [textField setBezeled: YES];
  [view addSubview: textField];
  NSForm *form = [[NSForm alloc] initWithFrame: NSMakeRect(150, 150, 180, 46)];
  [[form addEntry: @"Name:"] setStringValue: @"Alice"];
  [[form addEntry: @"City:"] setStringValue: @"Boston"];
  [form setCellSize: NSMakeSize(180, 22)];
  [form setIntercellSpacing: NSMakeSize(0, 2)];
  [view addSubview: form];
  [button setAlphaValue: 0.0]; // Legacy unkeyed palette archive default.
  [popup setAlphaValue: 0.5]; // Preserve a meaningful opacity setting.
  NSMatrix *matrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(120, 100, 100, 48)
    mode: NSRadioModeMatrix cellClass: [NSButtonCell class]
    numberOfRows: 2 numberOfColumns: 1];
  for (NSButtonCell *radioCell in [matrix cells])
    {
      [radioCell setButtonType: NSRadioButton];
      [radioCell setFont: [NSFont systemFontOfSize: 12]];
    }
  [view addSubview: matrix];
  [matrix setCellSize: NSMakeSize(88, 19)];
  [matrix setIntercellSpacing: NSMakeSize(3, 2)];
  [view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSView *editor = [[NSView alloc] initWithFrame: NSZeroRect];
  [editor setToolTip: @"EDITOR_MUST_NOT_BE_ARCHIVED"];
  [popup setNextKeyView: editor];
  EnumDocument *document = [[EnumDocument alloc]
    initWithObjects: [NSSet setWithObject: view]];
  NSString *error = nil;
  NSData *data = [NSClassFromString(@"GormXIBArchiver")
    dataWithGormDocument: (id)document classNameMappings: nil errorDescription: &error];
  if (data == nil)
    [NSException raise: @"TestFailure" format: @"%@", error];
  NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData: data options: 0 error: NULL];
  if ([[xml nodesForXPath: @"//comboBox/comboBoxCell[@key='cell']/objectValues/string"
                    error: NULL] count] != 3
      || [[xml nodesForXPath: @"//comboBox/comboBoxCell/objectValues[string='A & B < C']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//comboBox/comboBoxCell/objectValues[not(*)]"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//comboBox[@cell or @numberOfVisibleItems or @bezelStyle or @buttonBordered]"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid combo-box structure: %@", xml];
  if ([[xml nodesForXPath: @"//imageView[@imageAlignment='center' and @imageFrameStyle='photo']/imageCell[@key='cell' and @imageAlignment='center' and @imageFrameStyle='photo' and @imageScaling='proportionallyDown']"
                    error: NULL] count] != 1
      || [[xml nodesForXPath: @"//*[@imageAlignment='0' or @imageFrameStyle='1']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid image view enums: %@", xml];
  if ([[xml nodesForXPath: @"//textView[not(@selectionGranularity) and @string='Text view contents']"
                    error: NULL] count] != 1
      || [[xml nodesForXPath: @"//textView[@selectionGranularity='word']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//textView[@selectionGranularity='paragraph']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//textView[@selectionGranularity='0' or @selectionGranularity='1' or @selectionGranularity='2']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid text selection granularity: %@", xml];
  /* Header cells are inline values. IDs/references make Xcode try to find
   * an NSTableHeaderCell integrator during delayed archive verification. */
  if ([[xml nodesForXPath: @"//tableColumn/tableHeaderCell[@key='headerCell' and @title='Name' and not(@id)]/font[@size='14']"
                    error: NULL] count] != 1
      || [[xml nodesForXPath: @"//tableColumn[@headerCell] | //tableHeaderCell[@id] | //tableHeaderCell/connections"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//tableColumn/textFieldCell[@key='dataCell' and @id]"
                       error: NULL] count] != 1)
    [NSException raise: @"TestFailure" format: @"Invalid header-cell identity: %@", xml];
  if ([[xml nodesForXPath: @"//outlineView[@columnAutoresizingStyle='none' and @selectionHighlightStyle='regular']/tableColumns/tableColumn"
                    error: NULL] count] != 1
      || [[xml nodesForXPath: @"//scrollView/clipView/subviews/outlineView"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//scrollView/scroller[@scrollerStyle='legacy' and @arrowsPosition='default']"
                       error: NULL] count] != 2
      || [[xml nodesForXPath: @"//rulerView | //outlineView/cell | //scroller/cell"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//*[@columnAutoresizingStyle='0' or @selectionHighlightStyle='0' or @horizontalScrollElasticity='0' or @verticalScrollElasticity='0' or @scrollerStyle='0' or @scrollerKnobStyle='0' or @knobStyle='0' or @arrowsPosition='0']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid outline/scroll view output: %@", xml];
  if ([[xml nodesForXPath: @"//browser" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//browser/subviews | //browser/scrollView | //browser/scroller"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//browser[@columnResizingType or @cell or @cellPrototype]"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//browser/rect[@key='frame' and @width='300' and @height='200']"
                       error: NULL] count] != 1)
    [NSException raise: @"TestFailure" format: @"Invalid browser output: %@", xml];
  if (xml == nil
      || [[xml nodesForXPath: @"//popUpButton" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//buttonCell[@type='push']" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//button[@alphaValue='1.0']" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//popUpButton[@alphaValue='0.5']" error: NULL] count] != 1
      || [[xml nodesForXPath: @"//matrix/cells/column/buttonCell[@type='radio']"
                       error: NULL] count] != 2
      || [[xml nodesForXPath: @"//matrix/cells/column/buttonCell[@imagePosition='left']"
                       error: NULL] count] != 2
      || [[xml nodesForXPath: @"//textFieldCell[@borderStyle='bezel' or @borderStyle='borderAndBezel']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//form/cells/column/formCell"
                       error: NULL] count] != 2
      || [[xml nodesForXPath: @"//form/cells/column/formCell[@title='Name:' and @stringValue='Alice']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//form/cells/column/formCell[@title='City:' and @stringValue='Boston']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//form/size[@key='cellSize' and @width='180' and @height='22']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//matrix/size[@key='cellSize' and @width='88' and @height='19']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//matrix/size[@key='intercellSpacing' and @width='3' and @height='2']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//matrix/cells/column/buttonCell/behavior[@key='behavior' and @changeContents='YES' and @lightByContents='YES']"
                       error: NULL] count] != 2
      || [[xml nodesForXPath: @"//matrix/*[@key='cell'] | //matrix/@cell"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//font[not(@name) and not(@metaFont)]"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//buttonCell/font[@metaFont='system' and @size='13']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//autoresizingMask[@key='autoresizingMask']"
                       error: NULL] count] == 0
      || [[xml nodesForXPath: @"//*[@key='autoresizeMask']"
                       error: NULL] count] != 0
      || [[xml nodesForXPath: @"//*[@toolTip='EDITOR_MUST_NOT_BE_ARCHIVED']" error: NULL] count] != 0
      || [[xml nodesForXPath: @"//*[@controlSize='0' or @state='0' or @focusRingType='0' or @type='1']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid full XIB output: %@", xml];
  if ([button alphaValue] != 0.0 || [popup alphaValue] != 0.5)
    [NSException raise: @"TestFailure" format: @"Export mutated view opacity"];
  if ([[xml nodesForXPath: @"//progressIndicator[@style='bar' and @doubleValue='25.0']"
                    error: NULL] count] != 1
      || [[xml nodesForXPath: @"//progressIndicator[@style='spinning']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//progressIndicator[@style='0' or @style='1']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid progress indicator output: %@", xml];
  if ([[xml nodesForXPath: @"//slider/sliderCell[@sliderType='linear' and @tickMarkPosition='left' and @numberOfTickMarks='5']"
                    error: NULL] count] != 1
      || [[xml nodesForXPath: @"//slider/sliderCell[@sliderType='linear' and @tickMarkPosition='above' and @numberOfTickMarks='3']"
                       error: NULL] count] != 1
      || [[xml nodesForXPath: @"//*[@sliderType='0' or @sliderType='1' or @tickMarkPosition='0' or @tickMarkPosition='1']"
                       error: NULL] count] != 0)
    [NSException raise: @"TestFailure" format: @"Invalid slider output: %@", xml];
  [xml release];
  [verticalSlider release];
  [horizontalSlider release];
  [document release];
  [editor release];
  [button release];
  [textField release];
  [form release];
  [browser release];
  [outlineColumn release];
  [outline release];
  [outlineScroll release];
  [textView release];
  [imageView release];
  [comboBox release];
  [emptyComboBox release];
  [wordTextView release];
  [paragraphTextView release];
  [progress release];
  [spinner release];
  [matrix release];
  [view release];
  NSLog(@"XIB enum regression checks passed");
  id loader = [[NSClassFromString(@"GormXibWrapperLoader") alloc] init];
  [cell setButtonType: NSRadioButton];
  [cell setAlternateImage: [cell image]];
  [loader unarchiver: nil didDecodeObject: cell];
  if ([cell alternateImage] == nil || [cell alternateImage] == [cell image])
    [NSException raise: @"TestFailure" format: @"Radio state images are not distinct"];
  [loader release];
  [box release];
  [popup release];
  [cell release];
  [archiver release];
    }
  @catch (NSException *exception)
    {
      NSLog(@"XIB regression failed: %@", exception);
      [pool drain];
      return 1;
    }
  [pool drain];
  return 0;
}
