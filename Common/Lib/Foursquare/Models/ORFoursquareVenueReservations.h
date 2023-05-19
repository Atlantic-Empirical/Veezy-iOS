#import <Foundation/Foundation.h>

@interface ORFoursquareVenueReservations : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *url;

+ (ORFoursquareVenueReservations *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
