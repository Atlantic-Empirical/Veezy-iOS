//
//  ORInviteUserCell.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import "ORInviteUserCell.h"
#import "ORContact.h"

@interface ORInviteUserCell () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@end

@implementation ORInviteUserCell

- (void)awakeFromNib
{
    self.imgAvatar.layer.cornerRadius = 20.0f;
}

- (void)setUserId:(NSString*)userId
{
    _userId = userId;
    
    __weak ORInviteUserCell *weakSelf = self;
    
	[ApiEngine friendWithId:userId completion:^(NSError *error, OREpicFriend *user) {
		if (error) {
            NSLog(@"Error: %@", error);
		} else {
			weakSelf.user = user;
		}
	}];
}

- (void)setUser:(OREpicFriend *)user
{
    _user = user;
    _contact = nil;
    
    self.lblTitle.text = user.name;
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
	
    if (user.profileImageUrl) {
        if ([user.profileImageUrl hasPrefix:@"http"]) {
            __weak OREpicFriend *weakUser = user;
            __weak ORInviteUserCell *weakCell = self;
            
            NSURL *url = [NSURL URLWithString:user.profileImageUrl];
            
            if (url) {
                [[ORCachedEngine sharedInstance] imageAtURL:url size:CGSizeMake(40.0f, 40.0f) fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                    if (error) NSLog(@"Error: %@", error);
                    
                    if (image && weakUser == weakCell.user) {
                        weakCell.imgAvatar.image = image;
                    }
                }];
            }
        } else {
            self.imgAvatar.image = [UIImage imageNamed:user.profileImageUrl];
        }
    }
}

- (void)setContact:(ORContact *)contact
{
    _contact = contact;
    _user = nil;
    
    self.lblTitle.text = contact.contactTitle;
    self.lblSubtitle.text = contact.typeName;
    self.imgAvatar.image = [UIImage imageNamed:@"profile"];
    self.btnInvite.hidden = (contact.user != nil);
    self.btnInvite.selected = (contact.selected);
    
    if (contact.imageURL) {
        __weak ORContact *weakContact = contact;
        __weak ORInviteUserCell *weakCell = self;
        
        NSURL *url = [NSURL URLWithString:contact.imageURL];
        [[ORCachedEngine sharedInstance] imageAtURL:url size:CGSizeMake(40.0f, 40.0f) fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (error) NSLog(@"Error: %@", error);
            
            if (image && weakContact == weakCell.contact) {
                weakCell.imgAvatar.image = image;
            }
        }];
    }
    
    [self setNeedsLayout];
}

- (void)btnInvite_TouchUpInside:(id)sender
{
    [self.parent.view endEditing:YES];
    
    switch (self.contact.type) {
        case ORContactTypeFacebook: {
            NSString *msg = [NSString stringWithFormat:@"I'm using %@. Check it out!", APP_NAME];
            NSDictionary *params = @{@"to": self.contact.internalId};
            
            [FBWebDialogs presentRequestsDialogModallyWithSession:nil message:msg title:APP_NAME parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                if (error) {
                    NSLog(@"Error: %@", error);
                } else {
                    if (result == FBWebDialogResultDialogNotCompleted) {
                        NSLog(@"User canceled request.");
                    } else {
                        self.contact.selected = YES;
                        self.btnInvite.selected = YES;
                        NSLog(@"Request Sent.");
                    }
                }
            } friendCache:nil];
            
            break;
        }
        
        case ORContactTypeTwitter: {
            if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
                SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                [tweetSheet setInitialText:[NSString stringWithFormat: @"%@ I'm using %@. Check it out! http://appstore.com/veezy", self.contact.im, APP_NAME]];
                
                [tweetSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            NSLog(@"Twitter post cancelled");
                            break;
                        case SLComposeViewControllerResultDone:
                            self.contact.selected = YES;
                            self.btnInvite.selected = YES;
                            NSLog(@"Twitter post succeeded");
                            break;
                        default:
                            break;
                    }
                }];

                [self.parent presentViewController:tweetSheet animated:YES completion:nil];
            }
            
            break;
        }
            
        default:
            
            if (self.contact.emails.count > 0) {
                [AppDelegate nativeBarAppearance_nativeShare];
                MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
                if ([MFMailComposeViewController canSendMail]) {
                    [[[[controller viewControllers] lastObject] navigationItem] setTitle:@"Email"];
                    [controller setSubject:[NSString stringWithFormat:@"Check out %@!", APP_NAME]];
                    [controller setMessageBody:[NSString stringWithFormat:@"I'm using %@. Check it out! http://appstore.com/%@", APP_NAME, APP_URL_SCHEME] isHTML:NO];
                    [controller setToRecipients:@[[self.contact.emails firstObject]]];
                    [controller setMailComposeDelegate:self];
                    
                    [self.parent presentViewController:controller animated:YES completion:nil];
                } else {
                    [AppDelegate nativeBarAppearance_default];
                    NSLog(@"Can't send email");
                }
            } else if (self.contact.phones.count > 0) {
                [AppDelegate nativeBarAppearance_nativeShare];
                MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
                if ([MFMessageComposeViewController canSendText]) {
                    controller.body = [NSString stringWithFormat:@"I'm using %@. Check it out! http://appstore.com/%@", APP_NAME, APP_URL_SCHEME];;
                    controller.recipients = @[[self.contact.phones firstObject]];
                    controller.messageComposeDelegate = self;

                    [self.parent presentViewController:controller animated:YES completion:nil];
                } else {
                    [AppDelegate nativeBarAppearance_default];
                    NSLog(@"Can't send text");
                }
            } else {
                NSLog(@"Contact doesn't have email or phone");
            }
            
            break;
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [AppDelegate nativeBarAppearance_default];
    
	[self.parent dismissViewControllerAnimated:YES completion:^{
		switch (result) {
			case MessageComposeResultCancelled:
				NSLog(@"Message cancelled");
				break;
			case MessageComposeResultSent:
                self.contact.selected = YES;
                self.btnInvite.selected = YES;
				NSLog(@"Message sent");
				break;
			case MessageComposeResultFailed:
				NSLog(@"Message failed");
				break;
		}
	}];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [AppDelegate nativeBarAppearance_default];
    
	[self.parent dismissViewControllerAnimated:YES completion:^{
		switch (result) {
			case MFMailComposeResultSent:
                self.contact.selected = YES;
                self.btnInvite.selected = YES;
				NSLog(@"Email sent");
				break;
                
			case MFMailComposeResultCancelled:
				NSLog(@"Email cancelled");
				break;
                
			case MFMailComposeResultSaved:
                NSLog(@"Email saved");
				break;
                
			case MFMailComposeResultFailed:
				NSLog(@"Email failed");
				break;
		}
	}];
}

@end
