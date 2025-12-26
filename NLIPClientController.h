#import <AppKit/AppKit.h>

@class NLIPMessage;

@interface NLIPClientController : NSObject
{
    // UI Components
    NSTextField *serverUrlField;
    NSTextField *messageTypeField;
    NSTextView *messageInputView;
    NSTextView *chatView;
    NSButton *sendButton;
    NSButton *clearButton;
    NSTextField *statusLabel;
    
    // State
    NSString *serverUrl;
    NSString *currentSessionUrl;
    NSURLSession *urlSession;
    BOOL isSending;
}

- (NSView *)createView;
- (void)sendMessage: (id)sender;
- (void)clearMessages: (id)sender;
- (void)serverUrlChanged: (id)sender;
- (void)ensureURLSessionForCurrentUrl;
- (void)appendMessage: (NSString *)message isSent: (BOOL)sent;
- (void)appendMessage: (NSString *)message 
               isSent: (BOOL)sent 
          nlipMessage: (NSDictionary *)nlipMsg;
- (void)appendError: (NSString *)errorMessage;
- (void)updateStatus: (NSString *)status;

@end
