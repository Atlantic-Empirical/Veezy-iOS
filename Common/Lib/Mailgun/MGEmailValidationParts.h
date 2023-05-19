#import <Foundation/Foundation.h>

@interface MGEmailValidationParts : NSObject <NSCoding>

@property (nonatomic, strong) id displayName;
@property (nonatomic, copy) NSString *domain;
@property (nonatomic, copy) NSString *localPart;

+ (MGEmailValidationParts *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;

@end
