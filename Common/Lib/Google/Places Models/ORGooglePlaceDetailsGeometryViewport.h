#import <Foundation/Foundation.h>

@class ORGooglePlaceDetailsGeometryViewportNortheast;
@class ORGooglePlaceDetailsGeometryViewportSouthwest;

@interface ORGooglePlaceDetailsGeometryViewport : NSObject <NSCoding>

@property (nonatomic, strong) ORGooglePlaceDetailsGeometryViewportNortheast *northeast;
@property (nonatomic, strong) ORGooglePlaceDetailsGeometryViewportSouthwest *southwest;

+ (ORGooglePlaceDetailsGeometryViewport *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
