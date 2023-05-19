#import <Foundation/Foundation.h>

@interface ORGooglePlaceAddressComponent : NSObject <NSCoding>

@property (nonatomic, copy) NSString *longName;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSArray *types;

+ (ORGooglePlaceAddressComponent *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
