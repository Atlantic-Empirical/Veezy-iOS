//
//  ORPostCaptureUpsell.m
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 10/20/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "ORSubscriptionUpsell.h"
#import "ORSubscriptionController.h"

@interface ORSubscriptionUpsell () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@end

@implementation ORSubscriptionUpsell

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
    
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.screenName = @"SubscriptionUpsell";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORSubscriptionsReload:) name:@"ORSubscriptionsReload" object:nil];
	
	[AppDelegate.mixpanel track:@"Upsell-Loaded" properties:@{@"location": @"ORSubscriptionUpsell"}];
	[ORLoggingEngine logEvent:@"Upsell-Loaded" params:[@[@"ORSubscriptionUpsell"] mutableCopy]];

	[self.viewContent bringSubviewToFront:self.viewLoading];
    [self loadSubscriptionData];
	
	self.viewContent.backgroundColor = APP_COLOR_PRIMARY_ALPHA(1.0f);
    [self.imgLogo setImage:[UIImage imageNamed:@"veezy-center-nav-icon-66x.png"]];
}

- (void)handleORSubscriptionsReload:(NSNotification *)n
{
    if (CurrentUser.subscriptionLevel > 0) {
        [self view_TouchUpInside:nil];
        return;
    }

    [self loadSubscriptionData];
}

#pragma mark - Transition and Presentation

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* vc1 = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* vc2 = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* con = [transitionContext containerView];
    UIView* v1 = vc1.view;
    UIView* v2 = vc2.view;
    
    if (vc2 == self) { // presenting
        [con addSubview:v2];
        v2.frame = v1.frame;
        self.viewContent.transform = CGAffineTransformMakeScale(1.6,1.6);
        v2.alpha = 0.0f;
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            v2.alpha = 1.0f;
            self.viewContent.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
            self.viewContent.transform = CGAffineTransformMakeScale(0.5,0.5);
            v1.alpha = 0.0f;
        } completion:^(BOOL finished) {
            v2.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [transitionContext completeTransition:YES];
        }];
    }
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UI

- (IBAction)view_TouchUpInside:(id)sender
{
	[AppDelegate.mixpanel track:@"Upsell-Dismissed" properties:@{@"location": @"ORSubscriptionUpsell"}];
	[ORLoggingEngine logEvent:@"Upsell-Dismissed" params:[@[@"ORSubscriptionUpsell"] mutableCopy]];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnPurchase_TouchUpInside:(id)sender
{
	[AppDelegate.mixpanel track:@"Upsell-1moPressed" properties:@{@"location": @"ORSubscriptionUpsell"}];
	[ORLoggingEngine logEvent:@"Upsell-1moPressed" params:[@[@"ORSubscriptionUpsell"] mutableCopy]];

	self.viewPurchase.hidden = YES;
    self.viewTrial.hidden = YES;
    self.btnRestore.hidden = YES;
	[self.aiPurchasing startAnimating];
	
	if (!ORIsEmpty(CurrentUser.pendingSubscription)) {
		[[ORSubscriptionController sharedInstance] validateUserSubscription];
		return;
	}
	
	if ([[ORSubscriptionController sharedInstance] canMakePurchases]) {
		[[ORSubscriptionController sharedInstance] purchaseProduct:IAP_1MO completion:^(SKPaymentTransaction *transaction) {
			if (transaction.transactionState == SKPaymentTransactionStateFailed) {
				self.viewPurchase.hidden = NO;
                self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
                self.btnRestore.hidden = NO;
				[self.aiPurchasing stopAnimating];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
																message:[NSString stringWithFormat:@"Unable to complete the purchase. The returned error was: %@.\n\nIf you are already subscribed, please use 'Restore Purchases' in User Settings.", transaction.error.localizedDescription]
															   delegate:nil
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
				
				[AppDelegate.mixpanel track:@"Upsell-1moFailed" properties:@{@"location": @"ORSubscriptionUpsell", @"Error": transaction.error.localizedDescription}];
				[ORLoggingEngine logEvent:@"Upsell-1moFailed" params:[@[@"ORSubscriptionUpsell", transaction.error.localizedDescription] mutableCopy]];

			} else if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
				NSData *receipt = [NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL];
				
				if (CurrentUser.subscriptionLevel == 0) {
					CurrentUser.isPendingSubscription = YES;
					CurrentUser.subscriptionLevel = 1;
                    CurrentUser.subscriptionIsTrial = NO;
					CurrentUser.expirationDate = [[NSDate date] dateByAddingTimeInterval:(30 * 24 * 60 * 60)];
				}
				
				CurrentUser.pendingSubscription = [receipt base64EncodedStringWithOptions:kNilOptions];
				
				[AppDelegate.mixpanel track:@"Upsell-1moConverted" properties:@{@"location": @"ORSubscriptionUpsell"}];
				[ORLoggingEngine logEvent:@"Upsell-1moConverted" params:[@[@"ORSubscriptionUpsell"] mutableCopy]];

				[CurrentUser saveLocalUser];
				[[ORSubscriptionController sharedInstance] validateUserSubscription];
			}
		}];
	} else {
		self.viewPurchase.hidden = NO;
        self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
        self.btnRestore.hidden = NO;
		[self.aiPurchasing stopAnimating];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Disabled"
														message:@"In-app purchasing is disabled on this device."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)btnPurchase_annual_TouchUpInside:(id)sender
{
	[AppDelegate.mixpanel track:@"Upsell-1yrPressed" properties:@{@"location": @"ORSubscriptionUpsell"}];
	[ORLoggingEngine logEvent:@"Upsell-1yrPressed" params:[@[@"ORSubscriptionUpsell"] mutableCopy]];

	self.viewPurchase.hidden = YES;
    self.viewTrial.hidden = YES;
    self.btnRestore.hidden = YES;
	[self.aiPurchasing startAnimating];
	
	if (!ORIsEmpty(CurrentUser.pendingSubscription)) {
		[[ORSubscriptionController sharedInstance] validateUserSubscription];
		return;
	}
	
	if ([[ORSubscriptionController sharedInstance] canMakePurchases]) {
		[[ORSubscriptionController sharedInstance] purchaseProduct:IAP_1YR completion:^(SKPaymentTransaction *transaction) {
			if (transaction.transactionState == SKPaymentTransactionStateFailed) {
				self.viewPurchase.hidden = NO;
                self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
                self.btnRestore.hidden = NO;
				[self.aiPurchasing stopAnimating];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
																message:[NSString stringWithFormat:@"Unable to complete the purchase. The returned error was: %@.\n\nIf you are already subscribed, please use 'Verify Subscription' in User Settings.", transaction.error.localizedDescription]
															   delegate:nil
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
				
				[AppDelegate.mixpanel track:@"Upsell-1yrFailed" properties:@{@"location": @"ORSubscriptionUpsell", @"Error": transaction.error.localizedDescription}];
				[ORLoggingEngine logEvent:@"Upsell-1yrFailed" params:[@[@"ORSubscriptionUpsell", transaction.error.localizedDescription] mutableCopy]];

			} else if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
				NSData *receipt = [NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL];
				
				if (CurrentUser.subscriptionLevel == 0) {
					CurrentUser.isPendingSubscription = YES;
					CurrentUser.subscriptionLevel = 1;
                    CurrentUser.subscriptionIsTrial = NO;
					CurrentUser.expirationDate = [[NSDate date] dateByAddingTimeInterval:(365 * 24 * 60 * 60)];
				}
				
				CurrentUser.pendingSubscription = [receipt base64EncodedStringWithOptions:kNilOptions];
				
				[AppDelegate.mixpanel track:@"Upsell-1yrConverted" properties:@{@"location": @"ORSubscriptionUpsell"}];
				[ORLoggingEngine logEvent:@"Upsell-1yrConverted" params:[@[@"ORSubscriptionUpsell"] mutableCopy]];

				[CurrentUser saveLocalUser];
				[[ORSubscriptionController sharedInstance] validateUserSubscription];
			}
		}];
	} else {
		self.viewPurchase.hidden = NO;
        self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
        self.btnRestore.hidden = NO;
		[self.aiPurchasing stopAnimating];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Disabled"
														message:@"In-app purchasing is disabled on this device."
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)btnRestore_TouchUpInside:(id)sender
{

	[AppDelegate.mixpanel track:@"SubscriptionRestore-Attempt" properties:nil];
	[ORLoggingEngine logEvent:@"SubscriptionRestore-Attempt" params:nil];

	__block NSData *lastReceipt;
	
    self.viewPurchase.hidden = YES;
    self.viewTrial.hidden = YES;
	self.btnRestore.hidden = YES;
	[self.aiPurchasing startAnimating];
	
	[[ORSubscriptionController sharedInstance] restorePurchasesWithTransaction:^(SKPaymentTransaction *transaction) {
		NSData *receipt = [NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL];
		if (receipt) lastReceipt = receipt;
	} completion:^(NSError *error, BOOL result) {
		if (error) {
			NSLog(@"Error: %@", error);
			[AppDelegate.mixpanel track:@"SubscriptionRestore-Failed" properties:@{@"Error": error.localizedDescription}];
			[ORLoggingEngine logEvent:@"SubscriptionRestore-Failed" params:[@[error.localizedDescription] mutableCopy]];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                            message:[NSString stringWithFormat:@"Unable to restore purchases right now. Please try again later."]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
		}
		
		if (result && lastReceipt) {
			NSString *receiptString = [lastReceipt base64EncodedStringWithOptions:kNilOptions];
			
			[ApiEngine validateSubscription:receiptString cb:^(NSError *error, OREpicUser *user) {
				if (error) NSLog(@"Error: %@", error);
				
				if (user && [user.userId isEqualToString:CurrentUser.userId]) {
					CurrentUser.subscriptionLevel = user.subscriptionLevel;
					CurrentUser.expirationDate = user.expirationDate;
                    CurrentUser.subscriptionIsTrial = user.subscriptionIsTrial;
                    CurrentUser.trialExpired = user.trialExpired;
					[AppDelegate.mixpanel track:@"SubscriptionRestore-Success" properties:nil];
					[ORLoggingEngine logEvent:@"SubscriptionRestore-Success" params:nil];
				}
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORSubscriptionsReload" object:nil];
			}];
		} else {
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                                message:[NSString stringWithFormat:@"Sorry, no previous subscription found. Unable to restore."]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }

            self.viewPurchase.hidden = NO;
            self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
			self.btnRestore.hidden = NO;
			[self.aiPurchasing stopAnimating];
		}
	}];
}

- (IBAction)btnTrial_TouchUpInside:(id)sender
{
    self.viewPurchase.hidden = YES;
    self.viewTrial.hidden = YES;
    self.btnRestore.hidden = YES;
    [self.aiPurchasing startAnimating];
    
    [ApiEngine startTrialWithCompletion:^(NSError *error, OREpicUser *user) {
        if (error) NSLog(@"Error: %@", error);
        if (user) {
            CurrentUser.subscriptionLevel = user.subscriptionLevel;
            CurrentUser.expirationDate = user.expirationDate;
            CurrentUser.subscriptionIsTrial = user.subscriptionIsTrial;
            CurrentUser.trialExpired = user.trialExpired;
            [CurrentUser saveLocalUser];
        }
        
        if (CurrentUser.subscriptionLevel > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORSubscriptionStarted" object:nil];
        } else {
            self.viewPurchase.hidden = NO;
            self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
            self.btnRestore.hidden = NO;
            [self.aiPurchasing stopAnimating];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Start Trial"
                                                            message:@"Unable to start your trial right now. Please try again later."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORSubscriptionsReload" object:nil];
    }];
}

#pragma mark - Custom

- (void)loadSubscriptionData
{
    self.viewTrial.hidden = (CurrentUser.trialExpired || (CurrentUser.subscriptionLevel > 0 && CurrentUser.subscriptionIsTrial));
    self.viewLoading.hidden = NO;
    self.viewPurchase.hidden = NO;
    self.btnRestore.hidden = NO;
    [self.aiPurchasing stopAnimating];
	
    [[ORSubscriptionController sharedInstance] loadProductsWithCompletion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        [self updateSubscriptionData];
    }];
}

- (void)updateSubscriptionData
{
    self.viewLoading.hidden = YES;
	
	// MONTHLY
	
    SKProduct *product = [[ORSubscriptionController sharedInstance] productWithID:IAP_1MO];
    NSString *price = @"$9.99";
    
    if (product) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:product.priceLocale];
        price = [numberFormatter stringFromNumber:product.price];
    }
    
    self.lblPrice_monthly.text = [self.lblPrice_monthly.text stringByReplacingOccurrencesOfString:@"*|PRICE|*" withString:price];

	// ANNUAL
	
	product = [[ORSubscriptionController sharedInstance] productWithID:IAP_1YR];
	price = @"$9.99";
	
	if (product) {
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[numberFormatter setLocale:product.priceLocale];
		price = [numberFormatter stringFromNumber:product.price];
	}
	
	self.lblPrice_annual.text = [self.lblPrice_annual.text stringByReplacingOccurrencesOfString:@"*|PRICE|*" withString:price];
}

@end
