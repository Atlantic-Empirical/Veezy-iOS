//
//  ORUnlimitedParentView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORUnlimitedParentView.h"
#import "ORSubscriptionManager.h"
#import "ORSubscriptionController.h"

@interface ORUnlimitedParentView ()

@property (strong, nonatomic) ORPitchView_free *pitchView_free;
@property (strong, nonatomic) ORPitchView_plus *pitchView_plus;

@property (strong, nonatomic) ORSubscriptionManager *subscriptionManager_plus;

@end

@implementation ORUnlimitedParentView

- (void)dealloc
{
    self.scrollerMain.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [AppDelegate unlockOrientation];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.aiLoading.color = APP_COLOR_PRIMARY;
	
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = NSLocalizedStringFromTable(@"Subscription", @"UserSettingsSub", @"Unlimited");
	self.screenName = @"UnlimitedParent";
	
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildScreen) name:@"ORSubscriptionsReload" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setup];
}

- (void)btnRestore_TouchUpInside:(id)sender
{
    __block NSData *lastReceipt;
    
    self.btnRestore.enabled = NO;
    [self.aiLoading startAnimating];
    [self clearScreen];
    
    [[ORSubscriptionController sharedInstance] restorePurchasesWithTransaction:^(SKPaymentTransaction *transaction) {
        NSData *receipt = [NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL];
        if (receipt) lastReceipt = receipt;
    } completion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        if (result && lastReceipt) {
            if (CurrentUser.subscriptionLevel == 0) {
                CurrentUser.isPendingSubscription = YES;
                CurrentUser.subscriptionLevel = 1;
                CurrentUser.expirationDate = [[NSDate date] dateByAddingTimeInterval:(30 * 24 * 60 * 60)];
            }

            CurrentUser.pendingSubscription = [lastReceipt base64EncodedStringWithOptions:kNilOptions];
            [[ORSubscriptionController sharedInstance] validateUserSubscription];
        } else {
            [self rebuildScreen];
        }
    }];
}

#pragma mark - Custom

- (void)setup
{
    self.btnRestore.hidden = YES;
    [self.aiLoading startAnimating];
    
    [[ORSubscriptionController sharedInstance] loadProductsWithCompletion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
        
        [self rebuildScreen];
    }];
}

- (void)clearScreen
{
    if (self.pitchView_free) { [self.pitchView_free.view removeFromSuperview]; self.pitchView_free = nil; }
    if (self.pitchView_plus) { [self.pitchView_plus.view removeFromSuperview]; self.pitchView_plus = nil; }
    if (self.subscriptionManager_plus) { [self.subscriptionManager_plus.view removeFromSuperview]; self.subscriptionManager_plus = nil; }
}

- (void)rebuildScreen
{
    [self clearScreen];
    
    self.btnRestore.hidden = NO;
    self.btnRestore.enabled = YES;
    CGFloat currentY = CGRectGetMaxY(self.btnRestore.frame) + CGRectGetMinY(self.btnRestore.frame);
    
    if (CurrentUser.subscriptionLevel == 0) {
        // Free Pitch
        self.pitchView_free = [[ORPitchView_free alloc] initWithNibName:@"ORPitchView_free" bundle:nil];
        self.pitchView_free.view.frame = CGRectMake(0, currentY, self.scrollerMain.frame.size.width, self.pitchView_free.view.frame.size.height);
        [self.scrollerMain addSubview:self.pitchView_free.view];
        currentY += self.pitchView_free.view.frame.size.height;

        // Plus Pitch
        self.pitchView_plus = [[ORPitchView_plus alloc] initWithNibName:@"ORPitchView_plus" bundle:nil];
        self.pitchView_plus.view.frame = CGRectMake(0, currentY, self.scrollerMain.frame.size.width, self.pitchView_plus.view.frame.size.height);
        [self.scrollerMain addSubview:self.pitchView_plus.view];
        currentY += self.pitchView_plus.view.frame.size.height;
        
//        // Pro Pitch
//        self.pitchView_pro = [[ORPitchView_pro alloc] initWithNibName:@"ORPitchView_pro" bundle:nil];
//        self.pitchView_pro.view.frame = CGRectMake(0, currentY, self.scrollerMain.frame.size.width, self.pitchView_pro.view.frame.size.height);
//        [self.scrollerMain addSubview:self.pitchView_pro.view];
//        currentY += self.pitchView_pro.view.frame.size.height;
    } else if (CurrentUser.subscriptionLevel == 1) {
        // Plus Manager
        self.subscriptionManager_plus = [[ORSubscriptionManager alloc] initWithNibName:@"ORSubscriptionManager_plus" bundle:nil];
        self.subscriptionManager_plus.view.frame = CGRectMake(0, currentY, self.scrollerMain.frame.size.width, self.subscriptionManager_plus.view.frame.size.height);
        [self.scrollerMain addSubview:self.subscriptionManager_plus.view];
        currentY += self.subscriptionManager_plus.view.frame.size.height;
        
//        // Pro Pitch
//        self.pitchView_pro = [[ORPitchView_pro alloc] initWithNibName:@"ORPitchView_pro" bundle:nil];
//        self.pitchView_pro.view.frame = CGRectMake(0, currentY, self.scrollerMain.frame.size.width, self.pitchView_pro.view.frame.size.height);
//        [self.scrollerMain addSubview:self.pitchView_pro.view];
//        currentY += self.pitchView_pro.view.frame.size.height;
    } else if (CurrentUser.subscriptionLevel == 2) {
//        // Pro Manager
//        self.subscriptionManager_pro = [[ORSubscriptionManager_pro alloc] initWithNibName:@"ORSubscriptionManager_pro" bundle:nil];
//        self.subscriptionManager_pro.view.frame = CGRectMake(0, currentY, self.scrollerMain.frame.size.width, self.subscriptionManager_pro.view.frame.size.height);
//        [self.scrollerMain addSubview:self.subscriptionManager_pro.view];
//        currentY += self.subscriptionManager_pro.view.frame.size.height;
    }
    
    self.scrollerMain.contentSize = CGSizeMake(self.scrollerMain.frame.size.width, currentY);
    [self.aiLoading stopAnimating];
}

@end
