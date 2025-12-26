#import "NLIPMessage.h"

@implementation NLIPMessage

@synthesize format;
@synthesize subformat;
@synthesize content;
@synthesize messagetype;
@synthesize submessages;

- (id)init {
    self = [super init];
    if (self) {
        format = @"text";
        subformat = @"";
        content = @"";
        messagetype = nil;
        submessages = nil;
    }
    return self;
}

- (id)initWithContent: (NSString *)contentString {
    self = [self init];
    if (self) {
        [self setContent: contentString];
    }
    return self;
}

- (id)initWithContent: (NSString *)contentString messageType: (NSString *)msgType {
    self = [self initWithContent: contentString];
    if (self) {
        [self setMessagetype: msgType];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject: format forKey: @"format"];
    [dict setObject: subformat forKey: @"subformat"];
    [dict setObject: content forKey: @"content"];
    
    // Check for messagetype - must not be nil or NSNull, and must have length
    if (messagetype != nil && 
        messagetype != (id)[NSNull null] && 
        [messagetype isKindOfClass: [NSString class]] &&
        [messagetype length] > 0) {
        [dict setObject: messagetype forKey: @"messagetype"];
    }
    
    // Check for submessages - must not be nil or NSNull, and must be an array
    if (submessages != nil && 
        submessages != (id)[NSNull null] && 
        [submessages isKindOfClass: [NSArray class]]) {
        [dict setObject: submessages forKey: @"submessages"];
    }
    
    return dict;
}

- (NSData *)toJSON {
    NSDictionary *dict = [self toDictionary];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: dict
                                                       options: 0
                                                         error: &error];
    if (error) {
        NSLog(@"Error creating JSON: %@", error);
        return nil;
    }
    return jsonData;
}

+ (NLIPMessage *)messageFromJSON: (NSData *)jsonData {
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: jsonData
                                                        options: 0
                                                          error: &error];
    if (error) {
        NSLog(@"Error parsing JSON: %@", error);
        return nil;
    }
    
    if (![self isValidMessage: dict]) {
        return nil;
    }
    
    NLIPMessage *message = [[NLIPMessage alloc] init];
    [message setFormat: [dict objectForKey: @"format"]];
    [message setSubformat: [dict objectForKey: @"subformat"]];
    [message setContent: [dict objectForKey: @"content"]];
    
    // Handle messagetype - check for NSNull
    id messageTypeValue = [dict objectForKey: @"messagetype"];
    if (messageTypeValue != nil && messageTypeValue != [NSNull null]) {
        [message setMessagetype: messageTypeValue];
    }
    
    // Handle submessages - check for NSNull
    id submessagesValue = [dict objectForKey: @"submessages"];
    if (submessagesValue != nil && submessagesValue != [NSNull null]) {
        [message setSubmessages: submessagesValue];
    }
    
    return [message autorelease];
}

+ (BOOL)isValidMessage: (NSDictionary *)dict {
    return (dict != nil &&
            [dict objectForKey: @"format"] != nil &&
            [dict objectForKey: @"subformat"] != nil &&
            [dict objectForKey: @"content"] != nil);
}

- (void)dealloc {
    [format release];
    [subformat release];
    [content release];
    [messagetype release];
    [submessages release];
    [super dealloc];
}

@end
