#import <AppKit/AppKit.h>

@class NLIPClientController;

@interface NLIPClientAppDelegate : NSObject
{
    NSWindow *mainWindow;
    NLIPClientController *controller;
}

- (void)applicationDidFinishLaunching: (NSNotification *)notification;
- (void)applicationWillTerminate: (NSNotification *)notification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender;

@end
