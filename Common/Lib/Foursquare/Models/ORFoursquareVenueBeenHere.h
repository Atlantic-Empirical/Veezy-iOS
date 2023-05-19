#import <Foundation/Foundation.h>

@interface ORFoursquareVenueBeenHere : NSObject <NSCoding>

@property (nonatomic, copy) NSNumber *count;
@property (nonatomic, assign) BOOL marked;

+ (ORFoursquareVenueBeenHere *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
