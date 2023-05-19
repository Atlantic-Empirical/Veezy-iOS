//
//  ORFeedbackView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/16/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <sys/utsname.h>
#import "ORFeedbackView.h"

@interface ORFeedbackView ()

@end

@implementation ORFeedbackView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.title = @"Contact";
	self.screenName = @"Contact";

//    if (self.navigationController.childViewControllers.count == 1) {
//        // Camera as left bar button
//        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = camera;
//    }
	
	self.txtEmail.text = CurrentUser.emailAddress;
	self.txtName.text = CurrentUser.name;
	
	self.aiSend.color = APP_COLOR_PRIMARY;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doneAction:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UI

- (IBAction)btnSend_TouchUpInside:(id)sender
{
    // i18n repetative use
    NSString *okString = NSLocalizedStringFromTable(@"OK", @"UserSettingsSub", @"OK");
    
    if (!self.txtMessage.text || [self.txtMessage.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"noFeedback", @"UserSettingsSub", @"No Feedback")
                                                        message:NSLocalizedStringFromTable(@"noFeedbackMsg", @"UserSettingsSub", @"Please type a message before sending feedback.")
                                                       delegate:nil
                                              cancelButtonTitle:okString
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
	[self.aiSend startAnimating];
	
    struct utsname systemInfo;
    uname(&systemInfo);
    
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *ver = [infoDict objectForKey:@"CFBundleShortVersionString"]; // example: 1.0.0
	NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"]; // example: 42
    NSString *appVersion = [NSString stringWithFormat:@"v%@.%@", ver, buildNumber];
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    NSString *deviceName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];;
    
    NSString *feedback = [NSString stringWithFormat:@"%@:\n\n%@\n\nApp Version: %@\niOS Version: %@\nDevice: %@", NSLocalizedStringFromTable(@"Feedback", @"UserSettingsSub", @"Feedback"),
                          self.txtMessage.text, appVersion, iOSVersion, deviceName];
    
    [ApiEngine sendFeedback:feedback forUser:self.txtName.text andEmail:self.txtEmail.text cb:^(NSError *error, BOOL result) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message Sent"
                                                        message:@"Thanks for your message. If you asked a question we will get back to you soon."
                                                       delegate:nil
                                              cancelButtonTitle:okString
                                              otherButtonTitles:nil];
        [alert show];
        [self doneAction:nil];
		[self.aiSend stopAnimating];
    }];
}

- (IBAction)btnCloseKeyboard_TouchUpInside:(id)sender {
	[self.view endEditing:YES];
}

@end
