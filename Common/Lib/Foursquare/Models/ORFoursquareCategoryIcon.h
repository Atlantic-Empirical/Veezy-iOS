#import <Foundation/Foundation.h>

@interface ORFoursquareCategoryIcon : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *suffix;

+ (ORFoursquareCategoryIcon *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
