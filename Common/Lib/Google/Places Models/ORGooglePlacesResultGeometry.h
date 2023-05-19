#import <Foundation/Foundation.h>

@class ORGooglePlacesResultGeometryLocation;

@interface ORGooglePlacesResultGeometry : NSObject <NSCoding> {

}

@property (nonatomic, strong) ORGooglePlacesResultGeometryLocation *location;

+ (ORGooglePlacesResultGeometry *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
