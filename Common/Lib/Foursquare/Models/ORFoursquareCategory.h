#import <Foundation/Foundation.h>

@class ORFoursquareCategoryIcon;

@interface ORFoursquareCategory : NSObject <NSCoding>

@property (nonatomic, copy) NSString *oRFoursquareCategoryId;
@property (nonatomic, strong) ORFoursquareCategoryIcon *icon;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pluralName;
@property (nonatomic, assign) BOOL primary;
@property (nonatomic, copy) NSString *shortName;

+ (ORFoursquareCategory *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
