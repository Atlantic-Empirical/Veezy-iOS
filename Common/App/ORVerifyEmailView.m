//
//  ORVerifyEmailView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORVerifyEmailView.h"

@interface ORVerifyEmailView () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@end

@implementation ORVerifyEmailView

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
	
	self.screenName = @"VerifyEmail";

    self.viewBox.layer.cornerRadius = 2.0f;
	self.btnNoThanks.layer.cornerRadius = 2.0f;
	self.btnSend.layer.cornerRadius = 2.0f;
    
    self.txtEmail.text = CurrentUser.emailAddress;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	self.aiLoading.color = APP_COLOR_PRIMARY;
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

#pragma mark - Custom

- (void)btnTapCatcher_TouchUpInside:(id)sender
{
    [self.view endEditing:YES];
}

- (void)btnNoThanks_TouchUpInside:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnSend_TouchUpInside:(id)sender
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
    
    self.btnSend.enabled = NO;
    self.btnNoThanks.enabled = NO;
    [self.aiLoading startAnimating];
    
    if ([self.txtEmail.text isEqualToString:CurrentUser.emailAddress]) {
        OREpicUser *user = [OREpicUser new];
        user.userId = CurrentUser.userId;
        
        [ApiEngine verifyEmail:user cb:^(NSError *error, BOOL result) {
            if (error) NSLog(@"Error: %@", error);
            
            if (error || !result) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Error"
                                                                message:@"A server error has ocurred. Please try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                
                [self.txtEmail becomeFirstResponder];
                [self.aiLoading stopAnimating];
                self.btnSend.enabled = YES;
                self.btnNoThanks.enabled = YES;
                
                [alert show];
                return;
            }
            
            // All fine :)
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
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
                self.btnSend.enabled = YES;
                self.btnNoThanks.enabled = YES;
                
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
                self.btnSend.enabled = YES;
                self.btnNoThanks.enabled = YES;
                
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
                    self.btnSend.enabled = YES;
                    self.btnNoThanks.enabled = YES;
                    
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
                    self.btnSend.enabled = YES;
                    self.btnNoThanks.enabled = YES;
                    
                    [alert show];
                    return;
                }
                
                // All fine :)
                [CurrentUser saveLocalUser];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];
    }
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
