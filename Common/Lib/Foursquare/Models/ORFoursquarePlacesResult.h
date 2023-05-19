#import <Foundation/Foundation.h>

@class ORFoursquarePlacesResultMeta;
@class ORFoursquarePlaces;

@interface ORFoursquarePlacesResult : NSObject <NSCoding> {

}

@property (nonatomic, strong) ORFoursquarePlacesResultMeta *meta;
@property (nonatomic, copy) NSArray *notifications;
@property (nonatomic, strong) ORFoursquarePlaces *response;

+ (ORFoursquarePlacesResult *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
