#import <Foundation/Foundation.h>

@interface NLIPMessage : NSObject
{
    NSString *format;
    NSString *subformat;
    NSString *content;
    NSString *messagetype;
    NSArray *submessages;
}

@property (retain) NSString *format;
@property (retain) NSString *subformat;
@property (retain) NSString *content;
@property (retain) NSString *messagetype;
@property (retain) NSArray *submessages;

- (id)initWithContent: (NSString *)contentString;
- (id)initWithContent: (NSString *)contentString messageType: (NSString *)msgType;
- (NSDictionary *)toDictionary;
- (NSData *)toJSON;
+ (NLIPMessage *)messageFromJSON: (NSData *)jsonData;
+ (BOOL)isValidMessage: (NSDictionary *)dict;

@end
