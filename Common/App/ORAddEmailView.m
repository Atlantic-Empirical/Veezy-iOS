//
//  ORAddEmailView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORAddEmailView.h"

@interface ORAddEmailView () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@end

@implementation ORAddEmailView

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
	
	self.screenName = @"AddEmail";

    self.viewBox.layer.cornerRadius = 2.0f;
	self.btnDone.layer.cornerRadius = 2.0f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	self.aiLoading.color = APP_COLOR_PRIMARY;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.txtEmail becomeFirstResponder];
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
        self.viewBox.transform = CGAffineTransformMakeScale(1.6,1.6);
        v2.alpha = 0.0f;
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            v2.alpha = 1.0f;
            self.viewBox.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
            self.viewBox.transform = CGAffineTransformMakeScale(0.5,0.5);
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

- (void)btnTapCatcher_TouchUpInside:(id)sender
{
    [self.view endEditing:YES];
}

- (void)btnDone_TouchUpInside:(id)sender
{
    if (!self.txtEmail.text || [self.txtEmail.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Email"
                                                        message:@"Please type a valid email address."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [self.txtEmail becomeFirstResponder];
        [alert show];
        return;
    }
    
    self.btnDone.enabled = NO;
    [self.aiLoading startAnimating];
    
    [ApiEngine validateEmailAddress:self.txtEmail.text completion:^(NSError *error, BOOL result) {
        if (error) {
            NSLog(@"Error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Error"
                                                            message:@"A server error has ocurred. Please try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [self.txtEmail becomeFirstResponder];
            [self.aiLoading stopAnimating];
            self.btnDone.enabled = YES;

            [alert show];
            return;
        }
       
        if (!result) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Email"
                                                            message:@"This email address seems to be invalid, please make sure it's correct."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [self.txtEmail becomeFirstResponder];
            [self.aiLoading stopAnimating];
            self.btnDone.enabled = YES;

            [alert show];
            return;
        }
        
        CurrentUser.oldEmailAddress = CurrentUser.emailAddress ?: @"empty";
        CurrentUser.emailAddress = self.txtEmail.text;
        
        [ApiEngine saveUser:CurrentUser cb:^(NSError *error, OREpicUser *user) {
            if (error) {
                NSLog(@"Error: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Error"
                                                                message:@"A server error has ocurred. Please try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                
                [self.txtEmail becomeFirstResponder];
                [self.aiLoading stopAnimating];
                self.btnDone.enabled = YES;

                [alert show];
                return;
            }
            
            if (!user) {
                // E-mail already exists
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email in use"
                                                                message:@"This email address is already being used by another account."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];

                [self.txtEmail becomeFirstResponder];
                [self.aiLoading stopAnimating];
                self.btnDone.enabled = YES;
                
                [alert show];
                return;
            }
            
            // All fine :)
            [CurrentUser saveLocalUser];
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }];
}

- (IBAction)btnSignout_TouchUpInside:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserWillSignOut" object:nil];
    
	[self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedOut" object:nil];
    }];
}

- (IBAction)btnPrivacy_TouchUpInside:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy"
													message:@"We will not share your email address. It is used only for essential messages regarding your account, your videos, your subscription - and occassional information about our service."
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

#pragma mark - Keyboard

-(void)keyboardWillShow:(NSNotification*)notify
{
	NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat keyboardHeight = (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) ? [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.width : [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    CGFloat delta = keyboardHeight - (CGRectGetMaxY(self.view.bounds) - CGRectGetMaxY(self.viewBox.frame));
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.viewBox.center = CGPointMake(self.viewBox.center.x, self.view.center.y - delta);
    }];
    
    self.btnTapCatcher.enabled = YES;
}

-(void)keyboardWillHide:(NSNotification*)notify
{
	NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.viewBox.center = self.view.center;
    }];
    
    self.btnTapCatcher.enabled = NO;
}

@end
