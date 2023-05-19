//
//  ORFacebookPickerViewController.m
//  Veezy
//
//  Created by Rodrigo Sieiro on 29/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORFacebookPicker.h"
#import "ORFacebookPage.h"
#import "ORFacebookConnectView.h"
#import "ORFacebookEngine.h"
#import "ORFacebookPagesView.h"
#import "ORNavigationController.h"

@interface ORFacebookPicker () <UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSArray *ownPages;
@property (nonatomic, strong) NSArray *likedPages;
@property (nonatomic, assign) BOOL loadedOwnPages;
@property (nonatomic, assign) BOOL loadedLikedPages;
@property (nonatomic, assign) BOOL isLoadingOwnPages;
@property (nonatomic, assign) BOOL isLoadingLikedPages;
@property (nonatomic, assign) BOOL shouldTryPages;

@end

@implementation ORFacebookPicker

- (void)dealloc
{
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORFacebookPageSelected:) name:@"ORFacebookPageSelected" object:nil];
    
    [self updateState];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    switch (alertView.tag) {
            
        case 1: // Pair FB
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self connectFacebook];
            }
            break;
            
        case 2: // Page Permission
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                if (![FBSession.activeSession.permissions containsObject:@"user_likes"]) {
                    [FBSession.activeSession requestNewReadPermissions:@[@"user_likes"] completionHandler:^(FBSession *session, NSError *error) {
                        if (error) NSLog(@"Error: %@", error);
                        
                        if (![FBSession.activeSession.permissions containsObject:@"publish_actions"] || ![FBSession.activeSession.permissions containsObject:@"manage_pages"]) {
                            [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"manage_pages"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                                if (error) NSLog(@"Error: %@", error);
                                [RVC updateFacebookPairing];
                                [self selectPageToPost];
                            }];
                        } else {
                            if (!error) [RVC updateFacebookPairing];
                            [self selectPageToPost];
                        }
                    }];
                } else {
                    [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"manage_pages"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                        if (error) NSLog(@"Error: %@", error);
                        if (!error) [RVC updateFacebookPairing];
                        [self selectPageToPost];
                    }];
                }
            } else {
                if (![FBSession.activeSession.permissions containsObject:@"publish_actions"]) {
                    [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
                        if (error) NSLog(@"Error: %@", error);
                        if (!error) [RVC updateFacebookPairing];
                    }];
                }
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - Custom

- (void)handleORFacebookPageSelected:(NSNotification *)n
{
    if (n.object && [n.object isKindOfClass:[ORFacebookPage class]]) {
        ORFacebookPage *page = (ORFacebookPage *)n.object;
        CurrentUser.selectedFacebookPage = page;
    } else {
        CurrentUser.selectedFacebookPage = nil;
    }

    [CurrentUser saveLocalUser];
    [self updateState];
}

- (void)connectFacebook
{
    ORFacebookConnectView *vc = [ORFacebookConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        if (success) {
            self.selected = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookPickerStateChanged" object:self];
            if (self.shouldTryPages) {
                self.shouldTryPages = NO;
                [self btnConnect_TouchUpInside:self.btnConnect];
            }
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    [self updateState];
}

- (void)updateState
{
    self.btnMain.backgroundColor = APP_COLOR_FACEBOOK;
    [self.aiLoading stopAnimating];
    
    if (self.isSelected) {
        self.btnConnect.backgroundColor = APP_COLOR_FACEBOOK;
        self.btnConnect.titleLabel.textColor = [UIColor whiteColor];
        self.btnConnect.selected = YES;
    } else {
        self.btnConnect.backgroundColor = [UIColor lightGrayColor];
        self.btnConnect.selected = NO;
    }
    
    if (CurrentUser.isFacebookAuthenticated) {
        if (CurrentUser.selectedFacebookPage) {
            [self.btnConnect setTitle:CurrentUser.selectedFacebookPage.pageName forState:UIControlStateNormal];
        } else {
            NSString *fbName = [CurrentUser.facebookName componentsSeparatedByString:@" "][0];
            if (ORIsEmpty(fbName)) {
                NSLog(@"Warning: Facebook Name empty, this shouldn't happen");
                fbName = CurrentUser.name;
            }
            
            [self.btnConnect setTitle:fbName forState:UIControlStateNormal];
        }
    } else {
        [self.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    }
}

- (void)selectPageToPost
{
    if (self.loadedOwnPages && self.loadedLikedPages) {
        if (self.ownPages.count > 0 || self.likedPages.count > 0) [self showSelectPagesUI];
        return;
    }
    
    [self.btnConnect setTitle:nil forState:UIControlStateNormal];
    [self.aiLoading startAnimating];
    
    self.isLoadingOwnPages = YES;
    [ORFacebookEngine pagesWithCompletion:^(NSError *error, NSArray *items) {
        if (error) NSLog(@"Error: %@", error);
        if (!error) self.loadedOwnPages = YES;
        
        [self updateState];

        self.isLoadingOwnPages = NO;
        self.ownPages = items;
        [self showSelectPagesUI];
    }];

    self.isLoadingLikedPages = YES;
    [ORFacebookEngine likedPagesWithCompletion:^(NSError *error, NSArray *items) {
        if (error) NSLog(@"Error: %@", error);
        if (!error) self.loadedLikedPages = YES;
        
        [self updateState];
        
        self.isLoadingLikedPages = NO;
        self.likedPages = items;
        [self showSelectPagesUI];
    }];
}

- (void)showSelectPagesUI
{
    if (self.isLoadingOwnPages || self.isLoadingLikedPages) return;
    if (self.ownPages.count == 0 && self.likedPages.count == 0) return;
    
    ORFacebookPagesView *vc = [[ORFacebookPagesView alloc] initWithOwnPages:self.ownPages LikedPages:self.likedPages];
    
    if (self.navigationController) {
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark - UI

- (void)btnMain_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in so you can post your videos to Facebook." completion:^(BOOL success) {
            if (success) {
                [self btnMain_TouchUpInside:self.btnMain];
            }
        }];
        
        return;
    }
    
    if (!CurrentUser.isFacebookAuthenticated) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Facebook"
                                                    message:@"You need to connect Facebook before posting. Connect now?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.shouldTryPages = NO;
        self.alertView.tag = 1;
        [self.alertView show];
        
        return;
    }
    
    if (![FBSession.activeSession.permissions containsObject:@"publish_actions"]) {
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (error) NSLog(@"Error: %@", error);
            if (!error) [RVC updateFacebookPairing];
        }];
    }
    
    if (self.forceSelected) {
        [self btnConnect_TouchUpInside:self.btnConnect];
    } else {
        self.selected = !self.selected;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookPickerStateChanged" object:self];
    }
}

- (void)btnConnect_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in so you can post your videos to Facebook." completion:^(BOOL success) {
            if (success) {
                [self btnConnect_TouchUpInside:self.btnMain];
            }
        }];
        
        return;
    }
    
    if (!CurrentUser.isFacebookAuthenticated) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Facebook"
                                                    message:@"You need to connect Facebook before posting. Connect now?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.shouldTryPages = YES;
        self.alertView.tag = 1;
        [self.alertView show];
        
        return;
    }

    self.selected = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookPickerStateChanged" object:self];
    
    if (![FBSession.activeSession.permissions containsObject:@"publish_actions"] || ![FBSession.activeSession.permissions containsObject:@"manage_pages"] || ![FBSession.activeSession.permissions containsObject:@"user_likes"]) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Post to a Facebook Page"
                                                    message:@"Would you like to post as a page you manage or to a page you like?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 2;
        [self.alertView show];
    } else {
        [self selectPageToPost];
    }
}

@end
