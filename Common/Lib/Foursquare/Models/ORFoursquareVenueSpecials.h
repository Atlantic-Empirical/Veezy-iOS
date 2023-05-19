#import <Foundation/Foundation.h>

@interface ORFoursquareVenueSpecials : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *count;
@property (nonatomic, copy) NSArray *items;

+ (ORFoursquareVenueSpecials *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
