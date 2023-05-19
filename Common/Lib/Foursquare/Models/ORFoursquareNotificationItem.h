#import <Foundation/Foundation.h>

@interface ORFoursquareNotificationItem : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *unreadCount;

+ (ORFoursquareNotificationItem *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
