#import <Foundation/Foundation.h>

@interface ORFoursquarePlacesResultMeta : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *code;

+ (ORFoursquarePlacesResultMeta *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
