#import <Foundation/Foundation.h>

@class ORGooglePlaceDetails;

@interface ORGooglePlaceDetailsResult : NSObject <NSCoding>

@property (nonatomic, copy) NSArray *htmlAttributions;
@property (nonatomic, strong) ORGooglePlaceDetails *result;
@property (nonatomic, copy) NSString *status;

+ (ORGooglePlaceDetailsResult *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
