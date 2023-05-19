#import <Foundation/Foundation.h>

@interface ORGooglePlacesPhoto : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSArray *htmlAttributions;
@property (nonatomic, copy) NSString *photoReference;
@property (nonatomic, copy) NSNumber *width;

+ (ORGooglePlacesPhoto *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
