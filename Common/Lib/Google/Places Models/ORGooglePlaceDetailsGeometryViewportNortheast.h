#import <Foundation/Foundation.h>

@interface ORGooglePlaceDetailsGeometryViewportNortheast : NSObject <NSCoding>

@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lng;

+ (ORGooglePlaceDetailsGeometryViewportNortheast *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
