#import <Foundation/Foundation.h>

@interface ORFoursquareVenueContact : NSObject <NSCoding>

@property (nonatomic, copy) NSString *formattedPhone;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *twitter;
@property (nonatomic, copy) NSString *facebook;

+ (ORFoursquareVenueContact *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
