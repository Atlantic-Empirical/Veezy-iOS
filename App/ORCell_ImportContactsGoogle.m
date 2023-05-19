//
//  ORHomeCell_FindAndInvite.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORCell_ImportContactsGoogle.h"

@interface ORCell_ImportContactsGoogle ()

//@property (nonatomic, strong) UIImage *originalImage;

@end

@implementation ORCell_ImportContactsGoogle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
//    self.originalImage = self.imgSourceLogo.image;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitles) name:@"ORGooglePaired" object:nil];
	self.aiLoading.color = APP_COLOR_PRIMARY;
}

- (void)updateTitles
{
    if (AppDelegate.ge.isAuthenticated && AppDelegate.ge.userEmail) {
        self.lblConnectedAs.text = AppDelegate.ge.userEmail;
//        self.imgSourceLogo.image = self.originalImage;
		self.imgSourceLogo.image = [UIImage imageNamed:@"gmail-icon-wire-black-selected-40x"];
    } else {
		self.lblConnectedAs.text = @"Tap to connect";
//		self.imgSourceLogo.image = [ORUtility toGrayscale:self.imgSourceLogo.image];
    }
}

- (void)btnFindFriends_TouchUpInside:(id)sender
{
    __weak ORCell_ImportContactsGoogle *weakSelf = self;

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
