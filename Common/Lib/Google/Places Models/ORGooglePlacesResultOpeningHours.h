#import <Foundation/Foundation.h>

@interface ORGooglePlacesResultOpeningHours : NSObject <NSCoding> {

}

@property (nonatomic, assign) BOOL openNow;

+ (ORGooglePlacesResultOpeningHours *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
