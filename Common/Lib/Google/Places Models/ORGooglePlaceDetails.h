#import <Foundation/Foundation.h>

@class ORGooglePlaceDetailsGeometry;

@interface ORGooglePlaceDetails : NSObject <NSCoding>

@property (nonatomic, copy) NSArray *addressComponents;
@property (nonatomic, copy) NSString *adrAddress;
@property (nonatomic, copy) NSString *formattedAddress;
@property (nonatomic, strong) ORGooglePlaceDetailsGeometry *geometry;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *oRGooglePlaceDetailsId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *reference;
@property (nonatomic, copy) NSArray *types;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *vicinity;

+ (ORGooglePlaceDetails *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
