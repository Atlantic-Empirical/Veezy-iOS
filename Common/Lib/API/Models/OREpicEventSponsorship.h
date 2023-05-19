#import <Foundation/Foundation.h>

@interface OREpicEventSponsorship : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *sponsorName;
@property (nonatomic, copy) NSDate *sponsorshipEnd;
@property (nonatomic, copy) NSString *sponsorshipGeoScope;
@property (nonatomic, copy) NSString *sponsorshipId;
@property (nonatomic, copy) NSDate *sponsorshipStart;

+ (OREpicEventSponsorship *)instanceFromDictionary:(NSDictionary *)aDictionary;
- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
