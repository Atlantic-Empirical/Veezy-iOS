#import <Foundation/Foundation.h>

@interface ORFoursquareVenueStats : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *checkinsCount;
@property (nonatomic, copy) NSNumber *tipCount;
@property (nonatomic, copy) NSNumber *usersCount;

+ (ORFoursquareVenueStats *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
