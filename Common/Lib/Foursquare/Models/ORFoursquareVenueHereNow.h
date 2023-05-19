#import <Foundation/Foundation.h>

@interface ORFoursquareVenueHereNow : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *count;
@property (nonatomic, copy) NSArray *groups;

+ (ORFoursquareVenueHereNow *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
