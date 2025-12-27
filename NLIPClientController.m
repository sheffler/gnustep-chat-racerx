#import "NLIPClientController.h"
#import "NLIPMessage.h"
#import <GNUstepGUI/GSTable.h>

@implementation NLIPClientController

- (id)init {
    self = [super init];
    if (self) {
        // Load server URL from user defaults, or use default if not set
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *savedUrl = [defaults stringForKey: @"NLIPServerURL"];
        
        NSLog(@"=== Initializing NLIPClientController ===");
        NSLog(@"Retrieved from defaults: %@", savedUrl ? savedUrl : @"(null)");
        
        if (savedUrl && [savedUrl length] > 0) {
            serverUrl = [savedUrl copy];
            NSLog(@"✓ Loaded server URL from preferences: %@", serverUrl);
        } else {
            serverUrl = [[NSString alloc] initWithString: @"http://localhost:8000"];
            NSLog(@"✓ Using default server URL: %@", serverUrl);
        }
        
        currentSessionUrl = nil;
        urlSession = nil;
        isSending = NO;
    }
    return self;
}

- (NSView *)createView {
    // Create main table with proper spacing
    GSTable *mainTable = [[GSTable alloc] initWithNumberOfRows: 8 numberOfColumns: 1];
    [mainTable setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    
    CGFloat margin = 10;
    [mainTable setXBorder: margin];
    [mainTable setYBorder: margin];
    
    // Row 7 (top): Title
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 600, 35)];
    [titleLabel setAutoresizingMask: NSViewWidthSizable];
    [titleLabel setStringValue: @"🚀 NLIP Message Client"];
    [titleLabel setFont: [NSFont boldSystemFontOfSize: 24]];
    [titleLabel setBezeled: NO];
    [titleLabel setDrawsBackground: NO];
    [titleLabel setEditable: NO];
    [titleLabel setSelectable: NO];
    [titleLabel setAlignment: NSCenterTextAlignment];
    [mainTable putView: titleLabel atRow: 7 column: 0 withMargins: 5];
    [titleLabel release];
    
    // Row 6: Server URL section
    GSTable *urlTable = [[GSTable alloc] initWithNumberOfRows: 2 numberOfColumns: 1];
    [urlTable setAutoresizingMask: NSViewWidthSizable];
    
    NSTextField *urlLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 150, 20)];
    [urlLabel setAutoresizingMask: NSViewWidthSizable];
    [urlLabel setStringValue: @"NLIP Server URL:"];
    [urlLabel setBezeled: NO];
    [urlLabel setDrawsBackground: NO];
    [urlLabel setEditable: NO];
    [urlLabel setSelectable: NO];
    [urlTable putView: urlLabel atRow: 1 column: 0 withMargins: 2];
    [urlLabel release];
    
    serverUrlField = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 600, 25)];
    [serverUrlField setAutoresizingMask: NSViewWidthSizable];
    [serverUrlField setStringValue: serverUrl];
    [serverUrlField setTarget: self];
    [serverUrlField setAction: @selector(serverUrlChanged:)];
    [urlTable putView: serverUrlField atRow: 0 column: 0 withMargins: 2];
    [urlTable setXResizingEnabled: YES forColumn: 0];
    [urlTable sizeToFit];
    
    [mainTable putView: urlTable atRow: 6 column: 0 withMargins: 5];
    [urlTable release];
    
    // Row 5: Message Type section
    GSTable *typeTable = [[GSTable alloc] initWithNumberOfRows: 2 numberOfColumns: 1];
    [typeTable setAutoresizingMask: NSViewWidthSizable];
    
    NSTextField *typeLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 200, 20)];
    [typeLabel setAutoresizingMask: NSViewWidthSizable];
    [typeLabel setStringValue: @"Message Type (optional):"];
    [typeLabel setBezeled: NO];
    [typeLabel setDrawsBackground: NO];
    [typeLabel setEditable: NO];
    [typeLabel setSelectable: NO];
    [typeTable putView: typeLabel atRow: 1 column: 0 withMargins: 2];
    [typeLabel release];
    
    messageTypeField = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 600, 25)];
    [messageTypeField setAutoresizingMask: NSViewWidthSizable];
    [messageTypeField setStringValue: @""];
    [typeTable putView: messageTypeField atRow: 0 column: 0 withMargins: 2];
    [typeTable setXResizingEnabled: YES forColumn: 0];
    [typeTable sizeToFit];
    
    [mainTable putView: typeTable atRow: 5 column: 0 withMargins: 5];
    [typeTable release];
    
    // Row 4: Status bar
    statusLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 600, 25)];
    [statusLabel setAutoresizingMask: NSViewWidthSizable];
    [statusLabel setStringValue: @"Ready to connect"];
    [statusLabel setBezeled: YES];
    [statusLabel setDrawsBackground: YES];
    [statusLabel setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.95 alpha: 1.0]];
    [statusLabel setEditable: NO];
    [statusLabel setSelectable: NO];
    [mainTable putView: statusLabel atRow: 4 column: 0 withMargins: 5];
    
    // Row 3: Chat view (expandable)
    NSScrollView *chatScrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, 600, 250)];
    [chatScrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [chatScrollView setHasVerticalScroller: YES];
    [chatScrollView setBorderType: NSBezelBorder];
    
    chatView = [[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 580, 250)];
    [chatView setEditable: NO];
    [chatView setRichText: YES];
    [chatView setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.98 alpha: 1.0]];
    [chatView setFont: [NSFont systemFontOfSize: 13]];
    [chatView setMinSize: NSMakeSize(0, 0)];
    [chatView setMaxSize: NSMakeSize(1e7, 1e7)];
    [chatView setVerticallyResizable: YES];
    [chatView setHorizontallyResizable: NO];
    [chatView setAutoresizingMask: NSViewWidthSizable];
    [[chatView textContainer] setContainerSize: NSMakeSize(1e7, 1e7)];
    [[chatView textContainer] setWidthTracksTextView: YES];
    
    [chatScrollView setDocumentView: chatView];
    [mainTable putView: chatScrollView atRow: 3 column: 0 withMargins: 5];
    [chatScrollView release];
    
    // Row 2: Message Input label
    NSTextField *inputLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 150, 20)];
    [inputLabel setAutoresizingMask: NSViewWidthSizable];
    [inputLabel setStringValue: @"Your Message:"];
    [inputLabel setBezeled: NO];
    [inputLabel setDrawsBackground: NO];
    [inputLabel setEditable: NO];
    [inputLabel setSelectable: NO];
    [mainTable putView: inputLabel atRow: 2 column: 0 withMargins: 2];
    [inputLabel release];
    
    // Row 1: Message Input (expandable)
    NSScrollView *inputScrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, 600, 100)];
    [inputScrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [inputScrollView setHasVerticalScroller: YES];
    [inputScrollView setBorderType: NSBezelBorder];
    
    messageInputView = [[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, 580, 100)];
    [messageInputView setFont: [NSFont systemFontOfSize: 13]];
    [messageInputView setMinSize: NSMakeSize(0, 0)];
    [messageInputView setMaxSize: NSMakeSize(1e7, 1e7)];
    [messageInputView setVerticallyResizable: YES];
    [messageInputView setHorizontallyResizable: NO];
    [messageInputView setAutoresizingMask: NSViewWidthSizable];
    [[messageInputView textContainer] setContainerSize: NSMakeSize(1e7, 1e7)];
    [[messageInputView textContainer] setWidthTracksTextView: YES];
    [messageInputView setDelegate: self];
    
    [inputScrollView setDocumentView: messageInputView];
    [mainTable putView: inputScrollView atRow: 1 column: 0 withMargins: 5];
    [inputScrollView release];
    
    // Row 0 (bottom): Buttons
    GSTable *buttonTable = [[GSTable alloc] initWithNumberOfRows: 1 numberOfColumns: 3];
    [buttonTable setAutoresizingMask: NSViewWidthSizable];
    
    sendButton = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 200, 32)];
    [sendButton setTitle: @"Send Message"];
    [sendButton setBezelStyle: NSRoundedBezelStyle];
    [sendButton setTarget: self];
    [sendButton setAction: @selector(sendMessage:)];
    [sendButton sizeToFit];
    [buttonTable putView: sendButton atRow: 0 column: 0 withMargins: 5];
    
    clearButton = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 200, 32)];
    [clearButton setTitle: @"Clear Chat"];
    [clearButton setBezelStyle: NSRoundedBezelStyle];
    [clearButton setTarget: self];
    [clearButton setAction: @selector(clearMessages:)];
    [clearButton sizeToFit];
    [buttonTable putView: clearButton atRow: 0 column: 1 withMargins: 5];
    
    NSButton *newChatButton = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 200, 32)];
    [newChatButton setTitle: @"New Chat"];
    [newChatButton setBezelStyle: NSRoundedBezelStyle];
    [newChatButton setTarget: self];
    [newChatButton setAction: @selector(newChat:)];
    [newChatButton sizeToFit];
    [buttonTable putView: newChatButton atRow: 0 column: 2 withMargins: 5];
    [newChatButton release];
    
    [buttonTable setXResizingEnabled: YES forColumn: 0];
    [buttonTable setXResizingEnabled: YES forColumn: 1];
    [buttonTable setXResizingEnabled: YES forColumn: 2];
    [buttonTable sizeToFit];
    
    [mainTable putView: buttonTable atRow: 0 column: 0 withMargins: 5];
    [buttonTable release];
    
    // Configure table resizing behavior
    [mainTable setXResizingEnabled: YES forColumn: 0];
    
    // Row 3 (chat view) should expand vertically
    [mainTable setYResizingEnabled: YES forRow: 3];
    
    // Row 1 (input view) should also expand but less than chat
    [mainTable setYResizingEnabled: YES forRow: 1];
    
    [mainTable sizeToFit];
    
    return [mainTable autorelease];
}

- (void)serverUrlChanged: (id)sender {
    NSString *newUrl = [[serverUrlField stringValue] stringByTrimmingCharactersInSet: 
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Save to user defaults
    if ([newUrl length] > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSLog(@"=== Saving URL to preferences ===");
        NSLog(@"URL to save: %@", newUrl);
        [defaults setObject: newUrl forKey: @"NLIPServerURL"];
        BOOL syncResult = [defaults synchronize];
        NSLog(@"✓ Saved to preferences (sync result: %d)", syncResult);
        
        // Verify it was saved
        NSString *verification = [defaults stringForKey: @"NLIPServerURL"];
        NSLog(@"✓ Verification read: %@", verification);
    }
    
    // Check if URL has actually changed
    if (currentSessionUrl == nil || ![currentSessionUrl isEqualToString: newUrl]) {
        // Invalidate old session if it exists
        if (urlSession != nil) {
            [urlSession finishTasksAndInvalidate];
            [urlSession release];
            urlSession = nil;
            
            [currentSessionUrl release];
            currentSessionUrl = nil;
            
            [self updateStatus: [NSString stringWithFormat: @"New session created for: %@", newUrl]];
            NSLog(@"Session invalidated due to URL change");
        }
    }
}

- (void)ensureURLSessionForCurrentUrl {
    NSString *currentUrl = [[serverUrlField stringValue] stringByTrimmingCharactersInSet: 
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Create new session if needed
    if (urlSession == nil || currentSessionUrl == nil || 
        ![currentSessionUrl isEqualToString: currentUrl]) {
        
        // Clean up old session
        if (urlSession != nil) {
            [urlSession finishTasksAndInvalidate];
            [urlSession release];
            urlSession = nil;
        }
        
        [currentSessionUrl release];
        currentSessionUrl = [currentUrl copy];
        
        // Create new session with cookie storage
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [config setHTTPCookieStorage: [NSHTTPCookieStorage sharedHTTPCookieStorage]];
        [config setHTTPCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];
        [config setHTTPShouldSetCookies: YES];
        
        urlSession = [[NSURLSession sessionWithConfiguration: config] retain];
        
        NSLog(@"=== Created new NSURLSession ===");
        NSLog(@"URL: %@", currentSessionUrl);
        NSLog(@"Cookie storage: %@", [config HTTPCookieStorage]);
        NSLog(@"Cookie accept policy: %lu", (unsigned long)[config HTTPCookieAcceptPolicy]);
        NSLog(@"Should set cookies: %d", [config HTTPShouldSetCookies]);
    }
}

- (void)logCookiesForURL: (NSURL *)url {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookiesForURL: url];
    
    NSLog(@"=== Cookies for URL: %@ ===", url);
    if ([cookies count] == 0) {
        NSLog(@"  No cookies found");
    } else {
        for (NSHTTPCookie *cookie in cookies) {
            NSLog(@"  Cookie: %@ = %@", [cookie name], [cookie value]);
            NSLog(@"    Domain: %@", [cookie domain]);
            NSLog(@"    Path: %@", [cookie path]);
            NSLog(@"    Expires: %@", [cookie expiresDate]);
            NSLog(@"    Secure: %d", [cookie isSecure]);
            NSLog(@"    HTTPOnly: %d", [cookie isHTTPOnly]);
        }
    }
    
    // Also log ALL cookies
    NSArray *allCookies = [cookieStorage cookies];
    NSLog(@"=== Total cookies in storage: %lu ===", (unsigned long)[allCookies count]);
}

- (void)manuallyParseCookiesFromResponse: (NSHTTPURLResponse *)response forURL: (NSURL *)url {
    NSDictionary *headers = [response allHeaderFields];
    NSString *setCookieHeader = nil;
    
    // Try different case variations
    for (NSString *key in headers) {
        if ([[key lowercaseString] isEqualToString: @"set-cookie"]) {
            setCookieHeader = [headers objectForKey: key];
            NSLog(@"Found Set-Cookie header (key: %@): %@", key, setCookieHeader);
            break;
        }
    }
    
    if (setCookieHeader == nil) {
        NSLog(@"No Set-Cookie header found");
        return;
    }
    
    // Try to manually parse and store cookies
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields: headers forURL: url];
    NSLog(@"Parsed %lu cookies from response", (unsigned long)[cookies count]);
    
    if ([cookies count] > 0) {
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookies) {
            NSLog(@"  Manually storing cookie: %@ = %@", [cookie name], [cookie value]);
            NSLog(@"    Domain: %@", [cookie domain]);
            NSLog(@"    Path: %@", [cookie path]);
            [storage setCookie: cookie];
        }
        
        // Verify storage
        NSLog(@"After manual storage:");
        [self logCookiesForURL: url];
    } else {
        NSLog(@"WARNING: cookiesWithResponseHeaderFields returned no cookies!");
        NSLog(@"This might indicate the Set-Cookie header format is incompatible");
    }
}

- (void)sendMessage: (id)sender {
    if (isSending) return;
    
    NSString *content = [[messageInputView string] stringByTrimmingCharactersInSet: 
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([content length] == 0) {
        [self appendError: @"Please enter a message"];
        return;
    }
    
    NSString *url = [[serverUrlField stringValue] stringByTrimmingCharactersInSet: 
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([url length] == 0) {
        [self appendError: @"Please enter a server URL"];
        return;
    }
    
    // Ensure we have a session for the current URL
    [self ensureURLSessionForCurrentUrl];
    
    // Create NLIP message
    NSString *msgType = [[messageTypeField stringValue] stringByTrimmingCharactersInSet: 
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NLIPMessage *message;
    if ([msgType length] > 0) {
        message = [[NLIPMessage alloc] initWithContent: content messageType: msgType];
    } else {
        message = [[NLIPMessage alloc] initWithContent: content];
    }
    
    // Display sent message
    [self appendMessage: content isSent: YES nlipMessage: [message toDictionary]];
    
    // Clear input
    [messageInputView setString: @""];
    
    // Disable send button
    isSending = YES;
    [sendButton setEnabled: NO];
    [self updateStatus: @"Sending message..."];
    
    // Build URL
    NSString *fullUrl = url;
    if (![fullUrl hasSuffix: @"/nlip"]) {
        if ([fullUrl hasSuffix: @"/"]) {
            fullUrl = [fullUrl stringByAppendingString: @"nlip"];
        } else {
            fullUrl = [fullUrl stringByAppendingString: @"/nlip"];
        }
    }
    
    // Send request
    [self sendRequestToURL: fullUrl withMessage: message];
    [message release];
}

- (void)sendRequestToURL: (NSString *)urlString withMessage: (NLIPMessage *)message {
    NSURL *url = [NSURL URLWithString: urlString];
    
    NSLog(@"=== BEFORE REQUEST ===");
    [self logCookiesForURL: url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    [request setHTTPMethod: @"POST"];
    [request setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    [request setHTTPBody: [message toJSON]];
    
    // Log request headers
    NSLog(@"=== REQUEST HEADERS ===");
    NSDictionary *headers = [request allHTTPHeaderFields];
    for (NSString *key in headers) {
        NSLog(@"  %@: %@", key, [headers objectForKey: key]);
    }
    
    // Use the maintained session
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest: request
        completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
            // Log response on background thread
            if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"=== RESPONSE HEADERS ===");
                NSLog(@"Status Code: %ld", (long)[httpResponse statusCode]);
                NSDictionary *responseHeaders = [httpResponse allHeaderFields];
                for (NSString *key in responseHeaders) {
                    NSLog(@"  %@: %@", key, [responseHeaders objectForKey: key]);
                }
                
                // Try manual cookie parsing
                NSLog(@"=== ATTEMPTING MANUAL COOKIE PARSING ===");
                [self manuallyParseCookiesFromResponse: httpResponse forURL: url];
            }
            
            NSLog(@"=== AFTER RESPONSE ===");
            [self logCookiesForURL: url];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleResponse: data error: error];
            });
        }];
    [task resume];
}

- (void)handleResponse: (NSData *)data error: (NSError *)error {
    isSending = NO;
    [sendButton setEnabled: YES];
    
    if (error) {
        [self appendError: [NSString stringWithFormat: @"Network error: %@", [error localizedDescription]]];
        [self updateStatus: [NSString stringWithFormat: @"Error: %@", [error localizedDescription]]];
        return;
    }
    
    NLIPMessage *responseMsg = [NLIPMessage messageFromJSON: data];
    if (responseMsg == nil) {
        [self appendError: @"Invalid response format"];
        [self updateStatus: @"Error: Invalid response"];
        return;
    }
    
    [self appendMessage: [responseMsg content] isSent: NO nlipMessage: [responseMsg toDictionary]];
    [self updateStatus: @"Message sent successfully"];
}

- (void)appendMessage: (NSString *)message isSent: (BOOL)sent {
    [self appendMessage: message isSent: sent nlipMessage: nil];
}

- (void)appendMessage: (NSString *)message 
               isSent: (BOOL)sent 
          nlipMessage: (NSDictionary *)nlipMsg {
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
    
    // Header
    NSString *header = sent ? @"You:\n" : @"Server:\n";
    NSMutableAttributedString *headerStr = [[NSMutableAttributedString alloc] 
                                            initWithString: header];
    [headerStr addAttribute: NSFontAttributeName
                      value: [NSFont boldSystemFontOfSize: 12]
                      range: NSMakeRange(0, [header length])];
    [headerStr addAttribute: NSForegroundColorAttributeName
                      value: [NSColor grayColor]
                      range: NSMakeRange(0, [header length])];
    [attrStr appendAttributedString: headerStr];
    [headerStr release];
    
    // Content
    NSString *content = [message stringByAppendingString: @"\n"];
    NSMutableAttributedString *contentStr = [[NSMutableAttributedString alloc] 
                                             initWithString: content];
    [contentStr addAttribute: NSFontAttributeName
                       value: [NSFont systemFontOfSize: 13]
                       range: NSMakeRange(0, [content length])];
    [attrStr appendAttributedString: contentStr];
    [contentStr release];
    
    // Submessages
    if (nlipMsg && [nlipMsg objectForKey: @"submessages"]) {
        NSArray *submessages = [nlipMsg objectForKey: @"submessages"];
        if ([submessages count] > 0) {
            NSString *submsgHeader = [NSString stringWithFormat: @"\nSubmessages (%lu):\n", 
                                     (unsigned long)[submessages count]];
            NSMutableAttributedString *submsgHeaderStr = [[NSMutableAttributedString alloc] 
                                                          initWithString: submsgHeader];
            [submsgHeaderStr addAttribute: NSFontAttributeName
                                    value: [NSFont boldSystemFontOfSize: 11]
                                    range: NSMakeRange(0, [submsgHeader length])];
            [submsgHeaderStr addAttribute: NSForegroundColorAttributeName
                                    value: [NSColor blueColor]
                                    range: NSMakeRange(0, [submsgHeader length])];
            [attrStr appendAttributedString: submsgHeaderStr];
            [submsgHeaderStr release];
            
            for (NSUInteger i = 0; i < [submessages count]; i++) {
                NSDictionary *submsg = [submessages objectAtIndex: i];
                NSString *format = [submsg objectForKey: @"format"] ?: @"unknown";
                NSString *subformat = [submsg objectForKey: @"subformat"] ?: @"";
                NSString *submsgContent = [submsg objectForKey: @"content"] ?: @"(empty)";
                
                NSString *submsgText = [NSString stringWithFormat: @"  %lu. %@%@\n  %@\n", 
                                       i + 1, format, 
                                       [subformat length] > 0 ? [NSString stringWithFormat: @" (%@)", subformat] : @"",
                                       submsgContent];
                
                NSMutableAttributedString *submsgStr = [[NSMutableAttributedString alloc] 
                                                        initWithString: submsgText];
                [submsgStr addAttribute: NSFontAttributeName
                                  value: [NSFont systemFontOfSize: 12]
                                  range: NSMakeRange(0, [submsgText length])];
                [submsgStr addAttribute: NSForegroundColorAttributeName
                                  value: [NSColor darkGrayColor]
                                  range: NSMakeRange(0, [submsgText length])];
                [attrStr appendAttributedString: submsgStr];
                [submsgStr release];
            }
        }
    }
    
    // Add separator
    NSAttributedString *separator = [[NSAttributedString alloc] initWithString: @"\n---\n\n"];
    [attrStr appendAttributedString: separator];
    [separator release];
    
    // Append to chat view
    [[chatView textStorage] appendAttributedString: attrStr];
    [attrStr release];
    
    // Scroll to bottom
    [chatView scrollRangeToVisible: NSMakeRange([[chatView string] length], 0)];
}

- (void)appendError: (NSString *)errorMessage {
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
    
    NSString *header = @"⚠️ Error:\n";
    NSMutableAttributedString *headerStr = [[NSMutableAttributedString alloc] 
                                            initWithString: header];
    [headerStr addAttribute: NSFontAttributeName
                      value: [NSFont boldSystemFontOfSize: 12]
                      range: NSMakeRange(0, [header length])];
    [headerStr addAttribute: NSForegroundColorAttributeName
                      value: [NSColor redColor]
                      range: NSMakeRange(0, [header length])];
    [attrStr appendAttributedString: headerStr];
    [headerStr release];
    
    NSString *content = [errorMessage stringByAppendingString: @"\n\n---\n\n"];
    NSMutableAttributedString *contentStr = [[NSMutableAttributedString alloc] 
                                             initWithString: content];
    [contentStr addAttribute: NSForegroundColorAttributeName
                       value: [NSColor redColor]
                       range: NSMakeRange(0, [content length])];
    [attrStr appendAttributedString: contentStr];
    [contentStr release];
    
    [[chatView textStorage] appendAttributedString: attrStr];
    [attrStr release];
    
    [chatView scrollRangeToVisible: NSMakeRange([[chatView string] length], 0)];
}

- (void)newChat: (id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"New Chat"];
    [alert setInformativeText: @"Start a new chat session? This will clear the chat history and reset the server session."];
    [alert addButtonWithTitle: @"New Chat"];
    [alert addButtonWithTitle: @"Cancel"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        // Clear chat view
        [chatView setString: @""];
        
        // Clear cookies
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSString *currentUrl = [[serverUrlField stringValue] stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([currentUrl length] > 0) {
            NSURL *url = [NSURL URLWithString: currentUrl];
            if (url) {
                NSArray *cookies = [cookieStorage cookiesForURL: url];
                for (NSHTTPCookie *cookie in cookies) {
                    NSLog(@"Deleting cookie: %@", [cookie name]);
                    [cookieStorage deleteCookie: cookie];
                }
            }
        }
        
        // Also clear all cookies to be thorough
        NSArray *allCookies = [cookieStorage cookies];
        for (NSHTTPCookie *cookie in allCookies) {
            [cookieStorage deleteCookie: cookie];
        }
        
        // Invalidate and recreate the URL session
        if (urlSession != nil) {
            [urlSession finishTasksAndInvalidate];
            [urlSession release];
            urlSession = nil;
        }
        
        [currentSessionUrl release];
        currentSessionUrl = nil;
        
        [self updateStatus: @"New chat session started"];
        NSLog(@"New chat session created - cookies cleared");
    }
    [alert release];
}

- (void)clearMessages: (id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Clear Messages"];
    [alert setInformativeText: @"Clear all messages?"];
    [alert addButtonWithTitle: @"Clear"];
    [alert addButtonWithTitle: @"Cancel"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [chatView setString: @""];
        [self updateStatus: @"Ready to connect"];
    }
    [alert release];
}

- (void)updateStatus: (NSString *)status {
    [statusLabel setStringValue: status];
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    // Handle ENTER key to submit message
    if (commandSelector == @selector(insertNewline:) ||
	sel_isEqual(commandSelector, @selector(insertNewline:))) {
        NSEvent *currentEvent = [NSApp currentEvent];
        
        // Check if Shift key is pressed
        if ([currentEvent modifierFlags] & NSShiftKeyMask) {
            // Shift-Enter: insert newline (default behavior)
            return NO;
        } else {
            // Plain Enter: send message
            [self sendMessage: self];
            return YES; // Suppress default behavior
        }
    }
    
    return NO; // Let other commands be handled normally
}

- (void)dealloc {
    [serverUrl release];
    [currentSessionUrl release];
    if (urlSession != nil) {
        [urlSession finishTasksAndInvalidate];
        [urlSession release];
    }
    [serverUrlField release];
    [messageTypeField release];
    [messageInputView release];
    [chatView release];
    [sendButton release];
    [clearButton release];
    [statusLabel release];
    [super dealloc];
}

@end
