#import "NLIPClientAppDelegate.h"
#import "NLIPClientController.h"

@implementation NLIPClientAppDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)notification {
  // NSRect frame = NSMakeRect(100, 100, 800, 600);
  NSRect frame = NSMakeRect(0, 100, 400, 400);
    NSUInteger style = NSTitledWindowMask | NSClosableWindowMask | 
                       NSMiniaturizableWindowMask | NSResizableWindowMask;
    
    mainWindow = [[NSWindow alloc] initWithContentRect: frame
                                             styleMask: style
                                               backing: NSBackingStoreBuffered
                                                 defer: NO];
    
    [mainWindow setTitle: @"NLIP Message Client"];
    // [mainWindow setMinSize: NSMakeSize(600, 400)];
    
    controller = [[NLIPClientController alloc] init];
    
    NSView *contentView = [controller createView];
    [mainWindow setMinSize: [NSWindow frameRectForContentRect: contentView.frame
						    styleMask: [mainWindow styleMask]].size];
    
    [mainWindow setContentView: contentView];
    
    [mainWindow makeKeyAndOrderFront: self];
}

- (void)applicationWillTerminate: (NSNotification *)notification {
    [controller release];
    [mainWindow release];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender {
    return YES;
}

- (void)dealloc {
    [super dealloc];
}

@end
