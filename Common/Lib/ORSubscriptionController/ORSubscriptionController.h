//
//  ORSubscriptionController.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 23/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct, SKPaymentTransaction;

typedef void (^ORSCBoolCompletion)(NSError *error, BOOL result);
typedef void (^ORSCTransaction)(SKPaymentTransaction *transaction);

@interface ORSubscriptionController : NSObject

+ (ORSubscriptionController *)sharedInstance;

- (SKProduct *)productWithID:(NSString *)productID;
- (void)loadProductsWithCompletion:(ORSCBoolCompletion)completion;
- (void)restorePurchasesWithTransaction:(ORSCTransaction)transaction completion:(ORSCBoolCompletion)completion;
- (void)purchaseProduct:(NSString *)productId completion:(ORSCTransaction)completion;
- (BOOL)canMakePurchases;
- (void)validateUserSubscription;

@end
