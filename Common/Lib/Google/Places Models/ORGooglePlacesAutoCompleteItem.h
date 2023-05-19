#import <Foundation/Foundation.h>

@interface ORGooglePlacesAutoCompleteItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSArray *matchedSubstrings;
@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *placeId;
@property (nonatomic, copy) NSString *reference;
@property (nonatomic, copy) NSArray *terms;
@property (nonatomic, copy) NSArray *types;

+ (ORGooglePlacesAutoCompleteItem *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
