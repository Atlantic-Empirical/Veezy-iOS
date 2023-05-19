//
//  ORAfterFirstCaptureView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 20/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORMessageOverlayView.h"

@interface ORMessageOverlayView () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *buttonTitle;
@property (nonatomic, copy) void (^completionBlock)(void);

@end

@implementation ORMessageOverlayView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.title = title;
    self.message = message;
    self.buttonTitle = buttonTitle;
    
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    return self;
}

- (void)presentInViewController:(UIViewController *)vc completion:(void (^)(void))completion
{
    self.completionBlock = completion;
    [vc presentViewController:self animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIToolbar *blur = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    blur.barTintColor = nil;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blur.barStyle = UIBarStyleDefault;
    blur.alpha = 0.99f;
    [self.view insertSubview:blur atIndex:0];
    
    self.btnContinue.layer.cornerRadius = 5.0f;
    self.viewMessageHost.layer.cornerRadius = 5.0f;
	self.viewMessageHost.layer.borderColor = [UIColor whiteColor].CGColor;
	self.viewMessageHost.layer.borderWidth = 1.0f;
    
    self.lblTitle.text = self.title;
    self.lblMessage.text = self.message;
    [self.btnContinue setTitle:self.buttonTitle forState:UIControlStateNormal];
	
	CGSize size = [self.lblMessage sizeThatFits:CGSizeMake(self.lblMessage.frame.size.width, CGFLOAT_MAX)];
	CGRect frame = self.lblMessage.frame;
	float delta = size.height - frame.size.height;
	frame.size.height = size.height;
	self.lblMessage.frame = frame;
	
	frame = self.viewCenteringHost.frame;
	frame.size.height += delta + 14;
	self.viewCenteringHost.frame = frame;
	
	self.viewCenteringHost.center = self.view.center;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
//	CGSize size = [self.lblMessage.text sizeWithFont:self.lblMessage.font
//						 constrainedToSize:CGSizeMake(self.lblMessage.frame.size.width, MAXFLOAT)
//							 lineBreakMode:UILineBreakModeWordWrap];
//	CGRect labelFrame = self.lblMessage.frame;
//	labelFrame.size.height = size.height;
//	self.lblMessage.frame = labelFrame;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.enableButtonBlock) {
        self.btnContinue.hidden = !self.enableButtonBlock();
    } else {
        self.btnContinue.hidden = NO;
    }
}

- (void)handleDidBecomeActive:(NSNotification *)n
{
    [self viewWillAppear:NO];
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
        v2.alpha = 0.0f;
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            v2.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
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

#pragma mark - Custom

- (void)btnContinue_TouchUpInside:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.completionBlock) {
            self.completionBlock();
            self.completionBlock = nil;
        }
    }];
}

@end
