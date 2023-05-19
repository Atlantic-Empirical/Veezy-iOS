//
//  ORHomeCell_FindAndInvite.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORCell_ImportContactsADB.h"
#import "AddressBook.h"

@interface ORCell_ImportContactsADB ()

@property (nonatomic, strong) UIImage *originalImage;

@end

@implementation ORCell_ImportContactsADB

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    self.originalImage = self.imgSourceLogo.image;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitles) name:@"ORAddressBookPaired" object:nil];
	self.aiLoading.color = APP_COLOR_PRIMARY;
}

- (void)updateTitles
{
    if (CurrentUser.accountType != 3) {
        if (ABAddressBookGetAuthorizationStatus != NULL) {
            ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
            
            if (status == kABAuthorizationStatusAuthorized) {
                self.lblConnectedAs.text = @"Tap to refresh";
                self.imgSourceLogo.image = self.originalImage;
                return;
            }
        }
    }
    
	self.imgSourceLogo.image = [ORUtility toGrayscale:self.imgSourceLogo.image];
    self.lblConnectedAs.text = @"Tap to connect";
}

- (void)btnFindFriends_TouchUpInside:(id)sender
{
    __weak ORCell_ImportContactsADB *weakSelf = self;

    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to find your Twitter and Facebook friends!" completion:^(BOOL success) {
            if (success) {
                [weakSelf btnFindFriends_TouchUpInside:sender];
            }
        }];
        
        return;
    }

//    [self.aiLoading startAnimating];
    
//    [[ORDataController sharedInstance] findAndInviteFriendsWithCompletion:^(NSError *error, NSUInteger friends, NSUInteger contacts) {
//        if (error) NSLog(@"Error: %@", error);
//        
//        [weakSelf.aiLoading stopAnimating];
//        weakSelf.viewBackground.userInteractionEnabled = YES;
//        weakSelf.btnFindFriends.hidden = NO;
//        
//        if (friends == 0 && contacts == 0) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Friends Found"
//                                                            message:@"Sorry, we couldn't find any of your friends."
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
//        }
//    }];
}

@end
