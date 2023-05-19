#import <Foundation/Foundation.h>

@interface ORGooglePlacesResults : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSArray *debugInfo;
@property (nonatomic, copy) NSArray *htmlAttributions;
@property (nonatomic, copy) NSArray *results;
@property (nonatomic, copy) NSString *status;

+ (ORGooglePlacesResults *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
