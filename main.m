#import <AppKit/AppKit.h>
#import "NLIPClientAppDelegate.h"

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [NSApplication sharedApplication];
    
    NLIPClientAppDelegate *delegate = [[NLIPClientAppDelegate alloc] init];
    [NSApp setDelegate: delegate];
    
    [NSApp run];
    
    [pool release];
    return 0;
}
