#import <Foundation/Foundation.h>

@interface ORFoursquarePlaces : NSObject <NSCoding> {

}

@property (nonatomic, assign) BOOL confident;
@property (nonatomic, copy) NSArray *neighborhoods;
@property (nonatomic, copy) NSArray *venues;

+ (ORFoursquarePlaces *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
