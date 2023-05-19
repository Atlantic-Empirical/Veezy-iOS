#import <Foundation/Foundation.h>

@class MGEmailValidationParts;

@interface MGEmailValidation : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *address;
@property (nonatomic, strong) id didYouMean;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong) MGEmailValidationParts *parts;

+ (MGEmailValidation *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
