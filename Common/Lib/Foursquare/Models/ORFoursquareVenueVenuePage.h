#import <Foundation/Foundation.h>

@interface ORFoursquareVenueVenuePage : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *oRFoursquareVenueVenuePageId;

+ (ORFoursquareVenueVenuePage *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
