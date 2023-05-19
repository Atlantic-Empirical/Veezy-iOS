#import <Foundation/Foundation.h>

@class ORGooglePlaceDetailsGeometryLocation;
@class ORGooglePlaceDetailsGeometryViewport;

@interface ORGooglePlaceDetailsGeometry : NSObject <NSCoding>

@property (nonatomic, strong) ORGooglePlaceDetailsGeometryLocation *location;
@property (nonatomic, strong) ORGooglePlaceDetailsGeometryViewport *viewport;

+ (ORGooglePlaceDetailsGeometry *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
