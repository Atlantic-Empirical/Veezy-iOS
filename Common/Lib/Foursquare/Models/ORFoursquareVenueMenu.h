#import <Foundation/Foundation.h>

@interface ORFoursquareVenueMenu : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *anchor;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *mobileUrl;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *url;

+ (ORFoursquareVenueMenu *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
