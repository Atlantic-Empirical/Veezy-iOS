#import <Foundation/Foundation.h>

@interface ORGooglePlacesResultGeometryLocation : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lng;

+ (ORGooglePlacesResultGeometryLocation *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
