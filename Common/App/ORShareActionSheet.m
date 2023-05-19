//
//  ORShareActionSheet.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORShareActionSheet.h"
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ORPopDownView.h"
#import "ORNavigationController.h"
#import "ORDirectSendView.h"
#import "ORTwitterPostView.h"
#import "ORTwitterConnectView.h"
#import "ORFacebookPostView.h"
#import "ORFacebookConnectView.h"

@interface ORShareActionSheet () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, ORContactSelectViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) OREpicVideo *video;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSString *tempString;
@property (nonatomic, strong) NSString *tempAction;
@property (nonatomic, strong) ORDirectSendView *directSend;
@property (nonatomic, assign) BOOL showFbAndTw;

@end

@implementation ORShareActionSheet

- (id)initWithVideo:(OREpicVideo*)video andImage:(UIImage*)image showFacebookAndTwitter:(BOOL)showFbAndTw
{
    self = [super initWithNibName:@"ORShareActionSheet" bundle:nil];
    if (!self) return nil;
    
    _video = video;
    _image = image;
	_showFbAndTw = showFbAndTw;
	
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	self.screenName = @"ShareActionSheet";
	
	self.btnMail.enabled = [MFMailComposeViewController canSendMail];
	self.btnMessage.enabled = [MFMessageComposeViewController canSendText];

	// FACEBOOK & TWITTER
//	CGRect f = self.viewMain.frame;
//	float h = (self.showFbAndTw) ? 390.0f : 262.0f;
//	f.size.height = h;
//	f.origin.y = self.viewMain.superview.frame.size.height - h;
//	self.viewMain.frame = f;

	if (self.showFbAndTw) {
		[self setupFacebookAndTwitter];
	} else {
		self.viewFacebookTile.hidden = YES;
		self.viewTwitterTile.hidden = YES;
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hide
{
	self.view.hidden = YES;
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
        CGRect f = self.viewMain.frame;
        f.origin.y = CGRectGetMaxY(v2.frame);
        self.viewMain.frame = f;
        f.origin.y -= f.size.height;
        v2.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.viewMain.frame = f;
            v2.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
            self.viewMain.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else { // dismissing
        [UIView animateWithDuration:0.25 animations:^{
            CGRect f = self.viewMain.frame;
            f.origin.y += f.size.height;
            self.viewMain.frame = f;
            v1.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
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

- (IBAction)btnMessage_TouchUpInside:(id)sender
{
	[self displaySmsComposer];
}

- (IBAction)btnMail_TouchUpInside:(id)sender
{
	[self displayEmailComposer];
}

- (IBAction)btnTwitter_TouchUpInside:(id)sender
{
	[self displayTwitterComposer];
}

- (IBAction)btnFacebook_TouchUpInside:(id)sender
{
	[self displayFacebookComposer];
}

- (IBAction)btnCancel_TouchUpInside:(id)sender
{
	[self close];
}

- (IBAction)btnWhatsApp_TouchUpInside:(id)sender
{
	[self displayWhatsAppComposer];
}

- (IBAction)btnUrl_TouchUpInside:(id)sender
{
	[self putVideoUrlInPasteboard];
}

- (IBAction)btnEmbed_TouchUpInside:(id)sender
{
	[self putVideoEmbedCodeInPasteboard];
}

- (IBAction)btnVeezyDirect_TouchUpInside:(id)sender
{
    if (!self.directSend) {
        self.directSend = [[ORDirectSendView alloc] initWithVideo:self.video andSelectedContacts:nil];
        self.directSend.willSendDirectly = YES;
        self.directSend.parent = self;
        self.directSend.delegate = self;
    }
    
    self.directSend.focusOnDisplay = YES;
    
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:self.directSend];
    [self presentViewController:nav animated:YES completion:^{
		[self hide];
	}];
}

#pragma mark - Custom

- (void)setupFacebookAndTwitter
{
	// FACEBOOK
	self.viewTwitterTile.hidden = NO;
	
	// TWITTER
	self.viewFacebookTile.hidden = NO;
}

- (void)putVideoEmbedCodeInPasteboard
{
	self.tempString = self.video.videoEmbedCodeString;
	self.tempAction = @"Embed";
	
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = self.tempString;

	ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Embed code copied to clipboard"
													 subtitle:@""];
    
    UIView *view = (self.parentVC) ? self.parentVC.view : self.presentingViewController.view;
    if (!self.parentVC && [self.presentingViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)self.presentingViewController;
        view = nav.topViewController.view;
    }
	
	[pop displayInView:view hideAfter:3.0f];
	[self close];
}

- (NSString*)videoUrlString
{
	NSString *theLink;
	
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
		theLink = self.video.playerUrlSelected;
	} else {
		theLink = self.video.playerUrlPublic;
	}
	return theLink;
}

- (void)putVideoUrlInPasteboard
{
	self.tempString = [self videoUrlString];
	self.tempAction = @"URL";
	
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	pasteboard.string = self.tempString;

	ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Video Link Copied"
													 subtitle:@""];

    UIView *view = (self.parentVC) ? self.parentVC.view : self.presentingViewController.view;
    if (!self.parentVC && [self.presentingViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)self.presentingViewController;
        view = nav.topViewController.view;
    }

	[pop displayInView:view hideAfter:3.0f];
	[self close];
}

#pragma mark - ORContactSelectViewDelegate

- (void)contactSelectViewDidCancel:(ORDirectSendView *)contactSelect
{
    __weak ORShareActionSheet *weakSelf = self;
    
    [self dismissViewControllerAnimated:YES completion:^{
        weakSelf.directSend = nil;
        [weakSelf close];
    }];
}

- (void)contactSelectView:(ORDirectSendView *)contactSelect didSelectContact:(ORContact *)contact
{
    // NADA
}

- (void)contactSelectView:(ORDirectSendView *)contactSelect didSelectContacts:(NSArray *)contacts
{
    [contactSelect prepareDirectForContacts:contacts];
    [contactSelect sendDirect];
}

- (void)contactSelectView:(ORDirectSendView *)contactSelect didFinishSending:(BOOL)sent
{
    __weak ORShareActionSheet *weakSelf = self;
    
    [self dismissViewControllerAnimated:YES completion:^{
        weakSelf.directSend = nil;

        ORPopDownView *pop = [[ORPopDownView alloc] initWithTitle:@"Video sent successfully"
                                                         subtitle:@""];
        
        UIView *view = (weakSelf.parentVC) ? weakSelf.parentVC.view : weakSelf.presentingViewController.view;
        if (!weakSelf.parentVC && [weakSelf.presentingViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)weakSelf.presentingViewController;
            view = nav.topViewController.view;
        }
        
        [pop displayInView:view hideAfter:3.0f];
        [weakSelf close];
    }];
}

#pragma mark - Whatsapp Sending

- (BOOL)whatsAppIsAvailable
{
	NSURL *whatsappURL = [NSURL URLWithString:@"whatsapp://send?text=test"];
	return ([[UIApplication sharedApplication] canOpenURL: whatsappURL]);
}

- (void)displayWhatsAppComposer
{
	NSString *shareString = [NSString stringWithFormat:@"%@ %@", [self.video shareStringWithMaxLength:0], self.video.playerUrlSelected];
	NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@", [shareString mk_urlEncodedString]]];
	if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
		[[UIApplication sharedApplication] openURL: whatsappURL];
		[self close];
	}
}

#pragma mark - Message (SMS) Sending

- (void)displaySmsComposer
{
    [AppDelegate nativeBarAppearance_nativeShare];
	NSString *result = [NSString stringWithFormat:@"%@ %@", [self.video shareStringWithMaxLength:0], self.video.playerUrlSelected];

	MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if([MFMessageComposeViewController canSendText])
	{
		controller.body = result;
		controller.recipients = nil;
		if (self.image) {
			NSData *d = UIImagePNGRepresentation(self.image);
			[controller addAttachmentData:d typeIdentifier:(NSString *)kUTTypePNG filename:@"image.png"];
		}
		controller.messageComposeDelegate = self;
		[self presentViewController:controller animated:YES completion:^{
			[self hide];
		}];
	} else {
        [AppDelegate nativeBarAppearance_default];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [AppDelegate nativeBarAppearance_default];
    
	[self dismissViewControllerAnimated:YES completion:^{
		if (result == MessageComposeResultCancelled) {
			NSLog(@"Message cancelled");
		} else if (result == MessageComposeResultSent) {
			NSLog(@"Message sent");
            BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
            [AppDelegate.mixpanel track:@"Video Sent" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"com.apple.UIKit.activity.Message"}];
            [ORLoggingEngine logEvent:@"VideoShared" params:[@[self.video.videoId, @"Message", @(isSelf)] mutableCopy]];
        } else {
			NSLog(@"Message failed");
        }
        
		[self close];
	}];
}

#pragma mark - Email Sending

- (void)displayEmailComposer
{
    [AppDelegate nativeBarAppearance_nativeShare];
	NSString *result = [NSString stringWithFormat:@"%@ %@", [self.video shareStringWithMaxLength:0], self.video.playerUrlSelected];
	
	MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
	if([MFMailComposeViewController canSendMail])
	{
		// [[[[controller viewControllers] lastObject] navigationItem] setTitle:@"Email"];
		
		if (self.image) {
			// need to build html email body
			// http://stackoverflow.com/questions/12210571/how-to-add-a-image-in-email-body-using-mfmailcomposeviewcontroller
		}
		
		[controller setMessageBody:result isHTML:NO];
		controller.mailComposeDelegate = self;
		[self presentViewController:controller animated:YES completion:^{
			[self hide];
		}];
	} else {
        [AppDelegate nativeBarAppearance_default];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [AppDelegate nativeBarAppearance_default];
    
	[self dismissViewControllerAnimated:YES completion:^{
		switch (result) {
			case MFMailComposeResultSent:
				NSLog(@"Email sent");
                BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
                [AppDelegate.mixpanel track:@"Video Sent" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"com.apple.UIKit.activity.Mail"}];
                [ORLoggingEngine logEvent:@"VideoShared" params:[@[self.video.videoId, @"Mail", @(isSelf)] mutableCopy]];
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
		[self close];
	}];
}

#pragma mark - Twitter Sending

- (void)displayTwitterComposer
{
    if (self.video.privacy != OREpicVideoPrivacyPublic) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Share"
                                                        message:@"Sorry, this video is private and can't be shared on Twitter."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in so you can post your videos to Twitter." completion:^(BOOL success) {
            if (success) {
                [self displayTwitterComposer];
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

	NSString *result = [self.video shareStringWithMaxLength:TWITTER_MAX_CHARS];
    
    ORTwitterPostView *vc = [[ORTwitterPostView alloc] initWithVideo:self.video andShareString:result];
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
    
    [vc setCompletionBlock:^(BOOL success) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (success) {
                NSLog(@"Twitter post succeeded");
                BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
                [AppDelegate.mixpanel track:@"Video Sent" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"com.apple.UIKit.activity.PostToTwitter"}];
                [ORLoggingEngine logEvent:@"VideoShared" params:[@[self.video.videoId, @"Twitter", @(isSelf)] mutableCopy]];
            } else {
                NSLog(@"Twitter post cancelled");
            }
            
            [self close];
        }];
    }];
    
    [self presentViewController:nav animated:YES completion:^{
        [self hide];
    }];
}

#pragma mark - Facebook Sending

- (void)displayFacebookComposer
{
    if (self.video.privacy != OREpicVideoPrivacyPublic) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Share"
                                                        message:@"Sorry, this video is private and can't be shared on Facebook."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in so you can post your videos to Facebook." completion:^(BOOL success) {
            if (success) {
                [self displayFacebookComposer];
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
        self.alertView.tag = 2;
        [self.alertView show];
        
        return;
    }
    
    if (![FBSession.activeSession.permissions containsObject:@"publish_actions"]) {
        [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
            if (error) NSLog(@"Error: %@", error);
            if (!error) [RVC updateFacebookPairing];
        }];
    }
    
    NSString *result = [self.video shareStringWithMaxLength:0];
    
    ORFacebookPostView *vc = [[ORFacebookPostView alloc] initWithVideo:self.video andShareString:result];
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
    
    [vc setCompletionBlock:^(BOOL success) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (success) {
                NSLog(@"Facebook post succeeded");
                BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
                [AppDelegate.mixpanel track:@"Video Sent" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"com.apple.UIKit.activity.PostToFacebook"}];
                [ORLoggingEngine logEvent:@"VideoShared" params:[@[self.video.videoId, @"Facebook", @(isSelf)] mutableCopy]];
            } else {
                NSLog(@"Facebook post cancelled");
            }
            
            [self close];
        }];
    }];
    
    [self presentViewController:nav animated:YES completion:^{
        [self hide];
    }];
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
            
        case 2: // Pair FB
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self connectFacebook];
            }
            break;
            
        default:
            break;
    }
}

- (void)connectTwitter
{
    ORTwitterConnectView *vc = [ORTwitterConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        if (success) {
            [self displayTwitterComposer];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)connectFacebook
{
    ORFacebookConnectView *vc = [ORFacebookConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        if (success) {
            [self displayFacebookComposer];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self presentViewController:vc animated:YES completion:nil];
}

@end
