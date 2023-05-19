#import <Foundation/Foundation.h>

@interface ORGooglePlacesMatchedSubstring : NSObject <NSCoding>

@property (nonatomic, copy) NSNumber *length;
@property (nonatomic, copy) NSNumber *offset;

+ (ORGooglePlacesMatchedSubstring *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
