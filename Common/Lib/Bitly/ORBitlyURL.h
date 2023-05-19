#import <Foundation/Foundation.h>

@interface ORBitlyURL : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *globalHash;
@property (nonatomic, copy) NSString *bitlyHash;
@property (nonatomic, copy) NSString *longUrl;
@property (nonatomic, copy) NSNumber *nHash;
@property (nonatomic, copy) NSString *url;

+ (ORBitlyURL *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
