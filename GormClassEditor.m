#import "Gorm.h"
#import "GormPrivate.h"

@implementation	GormClassEditor

- (GormClassEditor*) initWithDocument: (GormDocument*)doc
{
  self = [super init];
  if (self != nil)
    {
      document = doc; // loose connection
    }
  return self;
}

- (void) dealloc 
{
  RELEASE(selectedClassName);

  [super dealloc];
}

+ (GormClassEditor*) classEditorForDocument: (GormDocument*)doc
{
  return AUTORELEASE([[self alloc] initWithDocument: doc]);
}

- (void) setSelectedClassName: (NSString*)cn
{
  ASSIGN(selectedClassName, cn);
}

//--- IBSelectionOwners protocol ---
- (unsigned) selectionCount
{
  return (selectedClassName == nil)?0: 1;
}

- (NSArray*) selection
{
  // when asked for a selection, it returns a class proxy
  if (selectedClassName != nil) 
    {
      NSArray		*array;
      GormClassProxy	*classProxy;

      classProxy = [[GormClassProxy alloc] initWithClassName:
	selectedClassName];
      array = [NSArray arrayWithObject: classProxy];
      RELEASE(classProxy);
      return array;
    } 
  else
    {
      return [NSArray array];
    }
}

- (void) drawSelection
{

}

- (void) makeSelectionVisible: (BOOL)flag
{

}

- (void) selectObjects: (NSArray*)objects
{
}
@end


