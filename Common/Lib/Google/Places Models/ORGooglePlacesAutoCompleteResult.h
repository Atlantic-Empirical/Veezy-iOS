#import <Foundation/Foundation.h>

@interface ORGooglePlacesAutoCompleteResult : NSObject <NSCoding>

@property (nonatomic, copy) NSArray *predictions;
@property (nonatomic, copy) NSString *status;

+ (ORGooglePlacesAutoCompleteResult *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
