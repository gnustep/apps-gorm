/* Run in a fresh Cappuccino process; no replacement decoder or mock classes. */
@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation CibTestOwner : CPObject
{
    id firstButton;
    id secondButton;
}
- (void)clicked:(id)sender {}
@end

@implementation CibTestButton : CPButton
@end

function check(condition, message)
{
    if (!condition)
        throw new Error(message);
}

function main(args)
{
    try
    {
        [CPApplication sharedApplication];
        var fs = require("fs"),
            data = [CPData dataWithRawString:fs.readFileSync(args[1], "utf8")],
            decoder = [[CPKeyedUnarchiver alloc] initForReadingWithData:data],
            root = [decoder decodeObjectForKey:@"CPCibObjectDataKey"],
            owner = [CibTestOwner new],
            top = [];
        check([root isKindOfClass:[_CPCibObjectData class]], "CIB root class");
        [root instantiateWithOwner:owner topLevelObjects:top];
        [root establishConnectionsWithOwner:owner topLevelObjects:top];
        [root awakeWithOwner:owner topLevelObjects:top];
        check(top.length === 1 && [top[0] isKindOfClass:[CPWindow class]], "top-level ownership");
        check([top[0] title] === "CIB graph", "window title");
        var content = [top[0] contentView],
            first = owner.firstButton,
            second = owner.secondButton;
        var scroll = [content subviews][2],
            scrollDocument = [scroll documentView],
            label = [scrollDocument subviews][0];
        check([[scroll contentView] superview] === scroll, "scroll clip hierarchy");
        check([scrollDocument superview] === [scroll contentView], "scroll document hierarchy");
        check([label stringValue] === "Scrolled" && ![label isEditable], "text field coding");
        check([scroll hasVerticalScroller], "scroll control state");
        check(first !== second && first && second, "distinct outlet objects");
        check([first isKindOfClass:[CibTestButton class]], "custom control class");
        check([first superview] === content && [second superview] === content, "view ownership");
        check([first title] === "First" && [second title] === "Second", "button titles");
        check([first tag] === 7 && [second tag] === 8, "numeric tags");
        check([first state] === CPOnState && ![second isEnabled], "control state");
        check([first target] === owner && [first action] === @selector(clicked:), "owner action");
        check([second target] === nil && [second action] === @selector(performClose:), "responder action");
        check(CGRectEqualToRect([first frame], CGRectMake(20, 148, 120, 32)), "frame decoding");
        check(CGRectEqualToRect([first bounds], CGRectMake(0, 0, 120, 32)), "bounds decoding");
        check([[first image] isKindOfClass:[_CPCibCustomResource class]], "image resource class");
        check([first image]._resourceName === "cib-test.png", "image resource name");
        check(CGSizeEqualToSize([[first image] size], CGSizeMake(16, 12)), "image size");
        check(![first autoresizesSubviews], "autoresizes subviews");
        check([first autoresizingMask] === CPViewMaxYMargin, "flipped autoresizing margins");
        // Exercise CPCib's full entry point as well. Keep external image loading
        // disabled: the resource belongs in the consuming application's bundle.
        var cib = [[CPCib alloc] _initWithData:data bundle:[CPBundle mainBundle] cibName:@"graph"],
            loaded = [];
        [cib _setAwakenCustomResources:NO];
        check([cib instantiateCibWithOwner:owner topLevelObjects:loaded], "CPCib instantiation");
        check(loaded.length === 1 && [loaded[0] title] === "CIB graph", "CPCib top-level window");
        console.log("PASS: Cappuccino decoded, instantiated and connected the exported CIB");
    }
    catch (error)
    {
        console.error(error.reason || error.message || String(error));
        process.exit(1);
    }
}
