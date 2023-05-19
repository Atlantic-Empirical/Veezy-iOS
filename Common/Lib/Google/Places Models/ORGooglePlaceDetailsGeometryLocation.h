#import <Foundation/Foundation.h>

@interface ORGooglePlaceDetailsGeometryLocation : NSObject <NSCoding>

@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lng;

+ (ORGooglePlaceDetailsGeometryLocation *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
