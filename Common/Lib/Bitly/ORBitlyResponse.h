#import <Foundation/Foundation.h>

@class ORBitlyURL;

@interface ORBitlyResponse : NSObject <NSCoding>

@property (nonatomic, strong) ORBitlyURL *bitlyUrl;
@property (nonatomic, copy) NSNumber *statusCode;
@property (nonatomic, copy) NSString *statusTxt;

+ (ORBitlyResponse *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
