//
//  ORHomeCell_FindAndInvite.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORCell_ImportContactsFacebook.h"

@interface ORCell_ImportContactsFacebook ()

//@property (nonatomic, strong) UIImage *originalImage;

@end

@implementation ORCell_ImportContactsFacebook

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
//    self.originalImage = self.imgSourceLogo.image;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitles) name:@"ORFacebookPaired" object:nil];
}

- (void)updateTitles
{
    if (CurrentUser.isFacebookAuthenticated) {
        if (!CurrentUser.facebookName) {
            __weak ORCell_ImportContactsFacebook *weakSelf = self;
            self.lblConnectedAs.text = @"Updating...";
            
            [FBRequestConnection startWithGraphPath:@"me?fields=id,name" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    CurrentUser.facebookName = result[@"name"];
                    [CurrentUser saveLocalUser];
                    
                    weakSelf.lblConnectedAs.text = CurrentUser.facebookName;
//                    weakSelf.imgSourceLogo.image = weakSelf.originalImage;
					weakSelf.imgSourceLogo.image = [UIImage imageNamed:@"facebook-icon-wire-black-selected-40x"];
                } else {
                    [FBSession.activeSession closeAndClearTokenInformation];
                    weakSelf.lblConnectedAs.text = @"Tap to connect";
//                    weakSelf.imgSourceLogo.image = [ORUtility toGrayscale:weakSelf.imgSourceLogo.image];
					self.imgSourceLogo.image = [UIImage imageNamed:@"facebook-icon-wire-black-40x"];
                }
            }];
            
            return;
        }
        
        self.lblConnectedAs.text = CurrentUser.facebookName;
//        self.imgSourceLogo.image = self.originalImage;
		self.imgSourceLogo.image = [UIImage imageNamed:@"facebook-icon-wire-black-selected-40x"];
    } else {
        self.lblConnectedAs.text = @"Tap to connect";
//		self.imgSourceLogo.image = [ORUtility toGrayscale:self.imgSourceLogo.image];
		self.imgSourceLogo.image = [UIImage imageNamed:@"facebook-icon-wire-black-40x"];
    }
}

- (void)btnFindFriends_TouchUpInside:(id)sender
{
    __weak ORCell_ImportContactsFacebook *weakSelf = self;

    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to find your Twitter and Facebook friends!" completion:^(BOOL success) {
            if (success) {
                [weakSelf btnFindFriends_TouchUpInside:sender];
            }
        }];
        
        return;
    }
}

@end
