#import <Foundation/Foundation.h>

@interface ORFoursquareVenueLocation : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *cc;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *crossStreet;
@property (nonatomic, copy) NSNumber *distance;
@property (nonatomic, copy) NSNumber *lat;
@property (nonatomic, copy) NSNumber *lng;
@property (nonatomic, copy) NSString *postalCode;
@property (nonatomic, copy) NSString *state;

+ (ORFoursquareVenueLocation *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
