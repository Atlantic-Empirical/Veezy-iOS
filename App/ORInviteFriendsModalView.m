//
//  ORInviteFriendsModalView.m
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/8/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORInviteFriendsModalView.h"
#import <MessageUI/MessageUI.h>
#import <Social/Social.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ORPassthroughView.h"

@interface ORInviteFriendsModalView () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@end

@implementation ORInviteFriendsModalView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self) return nil;
	
	self.modalPresentationStyle = UIModalPresentationCustom;
	self.transitioningDelegate = self;
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.screenName = @"InviteFriendsModal";
	
	[AppDelegate.mixpanel track:@"InviteFriendsView-Loaded" properties:nil];
	[ORLoggingEngine logEvent:@"InviteFriendsView-Loaded" params:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self setupView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (IBAction)view_TouchUpInside:(id)sender
{
	[AppDelegate.mixpanel track:@"InviteFriendsView-Dismissed" properties:nil];
	[ORLoggingEngine logEvent:@"InviteFriendsView-Dismissed" params:nil];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnMessage_TouchUpInside:(id)sender {
	[self displaySmsComposer];
}

- (IBAction)btnMail_TouchUpInside:(id)sender {
	[self displayEmailComposer];
}

- (IBAction)btnTwitter_TouchUpInside:(id)sender {
	[self displayTwitterComposer];
}

- (IBAction)btnFacebook_TouchUpInside:(id)sender {
	[self displayFacebookComposer];
}

- (IBAction)btnWhatsApp_TouchUpInside:(id)sender {
	[self displayWhatsAppComposer];
}

#pragma mark - Whatsapp Sending

- (BOOL)whatsAppIsAvailable {
	NSURL *whatsappURL = [NSURL URLWithString:@"whatsapp://send?text=test"];
	return ([[UIApplication sharedApplication] canOpenURL: whatsappURL]);
}

- (void)setupView {
	CGRect f = self.viewContent.frame;
	float h;
	if ([self whatsAppIsAvailable]) {
		h = 447.0f;
	} else {
		h = 344.0f;
	}
	f.size.height = h;
	f.origin.y = (self.viewContent.superview.frame.size.height - f.size.height) / 2;
	self.viewContent.frame = f;
	
	self.btnClose.center = CGPointMake(f.origin.x + f.size.width, f.origin.y);
}

- (void)displayWhatsAppComposer
{
	NSString *shareString = [NSString stringWithFormat:@"Check out this app: %@", SERVICE_URL];
	NSURL *whatsappURL = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@", [shareString mk_urlEncodedString]]];
	if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
		[[UIApplication sharedApplication] openURL: whatsappURL];
	}
}

#pragma mark - Message (SMS) Sending

- (void)displaySmsComposer
{
	[AppDelegate nativeBarAppearance_nativeShare];
	NSString *result = [NSString stringWithFormat:@"Check out this app: %@", SERVICE_URL];
	
	MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if([MFMessageComposeViewController canSendText])
	{
		controller.body = result;
		controller.recipients = nil;
		controller.messageComposeDelegate = self;
		[self presentViewController:controller animated:YES completion:^{
			//
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
			[AppDelegate.mixpanel track:@"AppInviteSent-Sms" properties:nil];
			[ORLoggingEngine logEvent:@"AppInviteSent-Sms" params:nil];
		} else {
			NSLog(@"Message failed");
		}
	}];
}

#pragma mark - Email Sending

- (void)displayEmailComposer
{
	[AppDelegate nativeBarAppearance_nativeShare];
	NSString *result = [NSString stringWithFormat:@"Check out this app: %@", SERVICE_URL];
	
	MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
	if([MFMailComposeViewController canSendMail])
	{
		// [[[[controller viewControllers] lastObject] navigationItem] setTitle:@"Email"];
		
		[controller setMessageBody:result isHTML:NO];
		controller.mailComposeDelegate = self;
		[self presentViewController:controller animated:YES completion:^{
			//
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
				[AppDelegate.mixpanel track:@"AppInviteSent-Email" properties:nil];
				[ORLoggingEngine logEvent:@"AppInviteSent-Email" params:nil];
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

#pragma mark - Twitter Sending

- (void)displayTwitterComposer
{
	[AppDelegate nativeBarAppearance_nativeShare];
	NSString *result = [NSString stringWithFormat:@"Check out this app: %@", SERVICE_URL];
	
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
	{
		SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
		[mySLComposerSheet setInitialText:[NSString stringWithFormat:result, mySLComposerSheet.serviceType]];
		//for more instance methodes, go here:https://developer.apple.com/library/ios/#documentation/NetworkingInternet/Reference/SLComposeViewController_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40012205
		[self presentViewController:mySLComposerSheet animated:YES completion:^{
			//
		}];
		[mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
			[AppDelegate nativeBarAppearance_default];
			
			switch (result) {
				case SLComposeViewControllerResultCancelled:
					NSLog(@"Twitter post cancelled");
					break;
				case SLComposeViewControllerResultDone:
					NSLog(@"Twitter post succeeded");
					[AppDelegate.mixpanel track:@"AppInviteSent-Twitter" properties:nil];
					[ORLoggingEngine logEvent:@"AppInviteSent-Twitter" params:nil];
					break;
				default:
					break;
			}
		}];
	} else {
		[AppDelegate nativeBarAppearance_default];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter" message:@"Pair Twitter with iOS." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
	}
}

#pragma mark - Facebook Sending

- (void)displayFacebookComposer
{
	if ([FBDialogs canPresentShareDialog]) {
//		NSString *result = [NSString stringWithFormat:@"Check out this app: %@", SERVICE_URL];
//		NSURL* url = [NSURL URLWithString:self.video.playerUrlSelected];
		[FBDialogs presentShareDialogWithLink:[NSURL URLWithString:SERVICE_URL] handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
			if (error) {
				NSLog(@"Error: %@", error);
			} else {
				[AppDelegate.mixpanel track:@"AppInviteSent-Facebook" properties:nil];
				[ORLoggingEngine logEvent:@"AppInviteSent-Facebook" params:nil];
			}
		}];
		
		return;
	}
	
	[AppDelegate nativeBarAppearance_nativeShare];
	NSString *result = [NSString stringWithFormat:@"Check out this app: %@", SERVICE_URL];
	
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
		SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
		[mySLComposerSheet setInitialText:[NSString stringWithFormat:result, mySLComposerSheet.serviceType]];
		[mySLComposerSheet addURL:[NSURL URLWithString:SERVICE_URL]];
		
		[self presentViewController:mySLComposerSheet animated:YES completion:^{
			//
		}];
		
		[mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
			[AppDelegate nativeBarAppearance_default];
			
			switch (result) {
				case SLComposeViewControllerResultCancelled:
					NSLog(@"Facebook post cancelled");
					break;
				case SLComposeViewControllerResultDone:
					NSLog(@"Facebook post succeeded");
					[AppDelegate.mixpanel track:@"AppInviteSent-Facebook" properties:nil];
					[ORLoggingEngine logEvent:@"AppInviteSent-Facebook" params:nil];
					break;
				default:
					break;
			}
		}];
	} else {
		[AppDelegate nativeBarAppearance_default];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook" message:@"Pair Facebook with iOS." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[alert show];
	}
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
		self.viewContent.transform = CGAffineTransformMakeScale(1.6,1.6);
		v2.alpha = 0.0f;
		v1.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
		
		[UIView animateWithDuration:0.25 animations:^{
			v2.alpha = 1.0f;
			self.viewContent.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			[transitionContext completeTransition:YES];
		}];
	} else { // dismissing
		[UIView animateWithDuration:0.25 animations:^{
			self.viewContent.transform = CGAffineTransformMakeScale(0.5,0.5);
			v1.alpha = 0.0f;
		} completion:^(BOOL finished) {
			v2.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
			[transitionContext completeTransition:YES];
		}];
	}
}

@end
