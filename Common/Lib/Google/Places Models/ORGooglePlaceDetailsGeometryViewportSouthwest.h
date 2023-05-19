#import <Foundation/Foundation.h>

@interface ORGooglePlaceDetailsGeometryViewportSouthwest : NSObject <NSCoding>

@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lng;

+ (ORGooglePlaceDetailsGeometryViewportSouthwest *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
