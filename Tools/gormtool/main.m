// main.m

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <GormCore/GormCore.h>
#import <InterfaceBuilder/InterfaceBuilder.h>

#import "AppDelegate.h"


int main(int argc, char **argv)
{
  NSApplication *app = [NSApplication sharedApplication];
  AppDelegate *delegate = [[AppDelegate alloc] init];
  extern char **environ;

  [NSProcessInfo initializeWithArguments: (char **)argv
				   count: argc
			     environment: environ];
  
  [app setDelegate: delegate];
  [app run];

  return 0;
}
