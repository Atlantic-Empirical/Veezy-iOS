#import <Foundation/Foundation.h>

@class ORFoursquareNotificationItem;

@interface ORFoursquareNotification : NSObject <NSCoding> {

}

@property (nonatomic, strong) ORFoursquareNotificationItem *item;
@property (nonatomic, copy) NSString *type;

+ (ORFoursquareNotification *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
