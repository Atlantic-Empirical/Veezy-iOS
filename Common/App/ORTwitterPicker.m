//
//  ORTwitterPicker.m
//  Veezy
//
//  Created by Rodrigo Sieiro on 29/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORTwitterPicker.h"
#import "ORTwitterConnectView.h"
#import "ORTwitterAccount.h"

@interface ORTwitterPicker () <UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSArray *twitterAccounts;

@end

@implementation ORTwitterPicker

- (void)dealloc
{
    self.alertView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateState];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    switch (alertView.tag) {
            
        case 1: // Pair TW
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self connectTwitter];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 1: {
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                CurrentUser.selectedTwitterAccount = nil;
                [CurrentUser saveLocalUser];
                [self updateState];
            } else if (buttonIndex < self.twitterAccounts.count) {
                [self setTwitterAccount:self.twitterAccounts[buttonIndex]];
            }
            
            break;
        }
    }
}

#pragma mark - Custom

- (void)connectTwitter
{
    ORTwitterConnectView *vc = [ORTwitterConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        if (success) {
            self.selected = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTwitterPickerStateChanged" object:self];
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
    [self.aiLoading stopAnimating];
    self.btnMain.backgroundColor = APP_COLOR_TWITTER;
    
    if (self.isSelected) {
        self.btnConnect.backgroundColor = APP_COLOR_TWITTER;
        self.btnConnect.titleLabel.textColor = [UIColor whiteColor];
        self.btnConnect.selected = YES;
    } else {
        self.btnConnect.backgroundColor = [UIColor lightGrayColor];
        self.btnConnect.selected = NO;
    }
    
    if (CurrentUser.isTwitterAuthenticated) {
        if (CurrentUser.selectedTwitterAccount) {
            NSString *name = [NSString stringWithFormat:@"@%@", CurrentUser.selectedTwitterAccount.screenName];
            [self.btnConnect setTitle:name forState:UIControlStateNormal];
        } else {
            NSString *name = [NSString stringWithFormat:@"@%@", AppDelegate.twitterEngine.screenName];
            [self.btnConnect setTitle:name forState:UIControlStateNormal];
        }
    } else {
        [self.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    }
}

- (void)selectAccountToPost
{
    [AppDelegate.twitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
        if (error) NSLog(@"Error: %@", error);
        
        if (items.count > 1) {
            NSString *name = [NSString stringWithFormat:@"@%@", AppDelegate.twitterEngine.screenName];
            NSMutableArray *accounts = [NSMutableArray arrayWithCapacity:items.count];
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select a Twitter account to post as:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            sheet.tag = 1;
            
            for (ACAccount *account in items) {
                if ([account.accountDescription isEqualToString:name]) continue;
                [sheet addButtonWithTitle:account.accountDescription];
                [accounts addObject:account];
            }
            
            self.twitterAccounts = accounts;
            sheet.cancelButtonIndex = [sheet addButtonWithTitle:[NSString stringWithFormat:@"Post as %@", name]];
            [sheet showInView:self.view];
        } else {
            if (error && error.code == 403) {
                // Not authorized
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access to Twitter denied"
                                                                message:[NSString stringWithFormat:@"Please authorize %@ to use your Twitter accounts in iOS Settings > Twitter then try again.", APP_NAME]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }];
}

- (void)setTwitterAccount:(ACAccount *)originalAccount
{
    [self.btnConnect setTitle:nil forState:UIControlStateNormal];
    [self.aiLoading startAnimating];
    
    [AppDelegate.twitterEngine reverseTokenForAccount:originalAccount completion:^(NSError *error, ORTwitterAccount *account) {
        if (error) NSLog(@"Error: %@", error);
        
        if (account) {
            CurrentUser.selectedTwitterAccount = account;
            [CurrentUser saveLocalUser];
        }

        [self updateState];
    }];
}

#pragma mark - UI

- (void)btnMain_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in so you can post your videos to Twitter." completion:^(BOOL success) {
            if (success) {
                [self btnMain_TouchUpInside:self.btnMain];
            }
        }];
        
        return;
    }
    
    if (!CurrentUser.isTwitterAuthenticated) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Twitter"
                                                    message:@"You need to connect Twitter before posting. Connect now?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 1;
        [self.alertView show];
        
        return;
    }
    
    if (self.forceSelected) {
        [self btnConnect_TouchUpInside:self.btnConnect];
    } else {
        self.selected = !self.selected;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTwitterPickerStateChanged" object:self];
    }
}

- (void)btnConnect_TouchUpInside:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in so you can post your videos to Twitter." completion:^(BOOL success) {
            if (success) {
                [self btnConnect_TouchUpInside:self.btnMain];
            }
        }];
        
        return;
    }
    
    if (!CurrentUser.isTwitterAuthenticated) {
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Twitter"
                                                    message:@"You need to connect Twitter before posting. Connect now?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 1;
        [self.alertView show];
        
        return;
    }
    
    self.selected = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTwitterPickerStateChanged" object:self];
    [self selectAccountToPost];
}

@end
