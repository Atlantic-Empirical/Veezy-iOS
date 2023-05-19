#import <Foundation/Foundation.h>

@interface ORGooglePlacesTerm : NSObject <NSCoding>

@property (nonatomic, copy) NSNumber *offset;
@property (nonatomic, copy) NSString *value;

+ (ORGooglePlacesTerm *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
