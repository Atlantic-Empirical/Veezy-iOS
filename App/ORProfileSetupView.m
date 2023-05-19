//
//  ORProfileSetupView.m
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/5/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORProfileSetupView.h"

@interface ORProfileSetupView () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate>

@property (assign, nonatomic) BOOL isValidEmail;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) NSString *isDirtyText;
@property (assign, nonatomic) BOOL isDirty;

@end

@implementation ORProfileSetupView

- (void)dealloc
{
    self.imagePicker.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.title = @"Profile";
	self.screenName = @"ProfileMgr";

	[self refreshUser];
}

#pragma mark - UI

- (void)doneAction:(id)sender
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [RVC showCamera];
    }
}

- (void)btnAnonTapCatcher_TouchUpInside:(id)sender
{
	[RVC presentSignInWithMessage:NSLocalizedStringFromTable(@"signToEdit", @"UserSettings", @"Sign-in to edit your profile!") completion:^(BOOL success) {
		if (success) {
			[self refreshUser];
		}
	}];
}

- (IBAction)btnCancelSave_TouchUpInside:(id)sender
{
	self.viewWait.hidden = YES;
}

#pragma mark - Custom

- (void)setDirty
{
	if (!self.isDirty) {
		self.isDirty = YES;
        
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAction:)];
        self.navigationItem.leftBarButtonItem = save;
        
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(doneAction:)];
        cancel.tintColor = [UIColor redColor];
        self.navigationItem.rightBarButtonItem = cancel;
	}
}

- (void)saveAction:(id)sender
{
	self.viewWait.frame = self.view.bounds;
	self.viewWait.hidden = NO;
	
	if (!self.isValidEmail) {
		__weak ORProfileSetupView *weakSelf = self;
		
		[ApiEngine validateEmailAddress:self.txtEmail.text completion:^(NSError *error, BOOL result) {
			if (!weakSelf) return;
			
			if (!error) {
				weakSelf.lblInvalidEmailX.hidden = result;
				
				if (result) {
					CurrentUser.oldEmailAddress = CurrentUser.emailAddress;
					
					weakSelf.isValidEmail = YES;
					[weakSelf saveAction:nil];
				} else {
					weakSelf.isValidEmail = NO;
					[weakSelf alertInvalidEmail];
				}
			}
		}];
		
		return;
	}
	
	CurrentUser.name = self.txtUsername.text;
	CurrentUser.emailAddress = self.txtEmail.text;
	CurrentUser.bio	= self.txtBio.text;
	
	[ApiEngine saveUser:CurrentUser cb:^(NSError *error, OREpicUser *user) {
		if (error) {
			NSLog(@"Error: %@", error);
		} else {
			if (user) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ORProfileUpdated" object:nil];
				CurrentUser.oldEmailAddress = nil;
				[CurrentUser saveLocalUser];
			} else {
				CurrentUser.emailAddress = CurrentUser.oldEmailAddress;
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"EmailInUse", @"UserSettings", @"Email in use")
																message:NSLocalizedStringFromTable(@"EmainInUseMessage", @"UserSettings", @"This email address is already in use by another account.")
															   delegate:nil
													  cancelButtonTitle:NSLocalizedStringFromTable(@"EmailInUseCancelButton", @"UserSettings", @"Emain in Use cancel button title: OK")
													  otherButtonTitles:nil];
				[alert show];
			}
		}
		
		self.viewWait.hidden = YES;
        [self doneAction:nil];
	}];
}

- (void)refreshUser
{
	// AVATAR
	self.imgAvatar.image = [UIImage imageNamed:@"profile"];
	if (CurrentUser.profileImageUrl) {
		[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:CurrentUser.profileImageUrl] maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			if (error) {
				NSLog(@"Error: %@", error);
			} else {
				if (image) {
					self.imgAvatar.image = image;
				}
			}
		}];
	}
	
	// PROFILE
	self.txtUsername.text = CurrentUser.name;
//	self.txtLocation.text = CurrentUser.homeLocale;
	self.txtBio.text = CurrentUser.bio;
	self.txtEmail.text = CurrentUser.emailAddress;
//	self.txtUserHandle.text = CurrentUser.username;
	self.isValidEmail = YES;
	self.btnAnonTapCatcher.hidden = (CurrentUser.accountType != 3);
}

- (void)alertInvalidEmail
{
	if (!self.isValidEmail) {
		self.viewWait.hidden = YES;
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"invalidEmail", @"UserSettings", @"Invalid Email")
														message:NSLocalizedStringFromTable(@"seemsInvalid", @"UserSettings", @"The email address seems to be invalid.")
													   delegate:nil
											  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"UserSettings", @"OK")
											  otherButtonTitles:nil];
		[alert show];
	}
}

#pragma mark - Avatar

- (IBAction)btnAvatar_TouchUpInside:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedStringFromTable(@"AvatarTouchTakePhoto", @"UserSettings", @"Avatar Touch: Take Photo With Camera"), NSLocalizedStringFromTable(@"AvatarTouchSelectPhoto", @"UserSettings", @"Avatar Touch: Select Photo From Library"), NSLocalizedStringFromTable(@"AvatarTouchCancel", @"UserSettings", @"Avatar Touch: Cancel"), nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.destructiveButtonIndex = 2;
    [actionSheet showInView:AppDelegate.viewController.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
		[self startImagePicker:0];
	else if (buttonIndex == 1)
		[self startImagePicker:1];
	else if (buttonIndex == 2)
		NSLog(@"cancel");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:^{
		[RVC startPreview];
	}];
}

- (void)startImagePicker:(int)type
{
	[RVC stopPreview];
	
	if (type == 0 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		self.imagePicker = [[UIImagePickerController alloc] init];
		self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
		self.imagePicker.allowsEditing = YES;
		self.imagePicker.delegate = self;
		[AppDelegate.viewController presentViewController:self.imagePicker animated:YES completion:nil];
	} else if (type == 1 && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		self.imagePicker = [[UIImagePickerController alloc]init];
		self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		self.imagePicker.allowsEditing = YES;
		self.imagePicker.delegate = self;
		[AppDelegate.viewController presentViewController:self.imagePicker animated:YES completion:nil];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self.imagePicker dismissViewControllerAnimated:YES completion:^{
		[RVC startPreview];
		UIImage * img = [info objectForKey:@"UIImagePickerControllerEditedImage"];
		[self setAvatarToImage:img];
	}];
}

-(void)setAvatarToImage:(UIImage *)img
{
    self.btnAvatar.enabled = NO;
    self.viewWait.hidden = NO;
    [self.aiUploading startAnimating];
    
	// Reduce avatar size if needed
	if (img.size.height > 100.0f || img.size.width > 100.0f) {
        img = [[ORCachedEngine sharedInstance] resampleImage:img size:CGSizeMake(100.0f, 100.0f) fill:YES];
	}

    self.imgAvatar.image = img;

    [ApiEngine saveUserAvatar:img cb:^(NSError *error, NSString *result) {
        if (error) NSLog(@"Error: %@", error);
        NSString *url = [result stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        if (!ORIsEmpty(url)) {
            [[ORCachedEngine sharedInstance] expireCacheForURL:[NSURL URLWithString:CurrentUser.profileImageUrl]];
            CurrentUser.profileImageUrl = url;
            [CurrentUser saveLocalUser];

            self.viewWait.hidden = YES;
            self.btnAvatar.enabled = YES;
            [self.aiUploading stopAnimating];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORProfileUpdated" object:nil];
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.isDirtyText = textField.text;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self setDirty];
	if (textField == self.txtEmail) self.isValidEmail = NO;
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if ([textField.text isEqualToString:self.isDirtyText]) return; // user didn't change anything
	
	if (textField == self.txtEmail) {
		__weak ORProfileSetupView *weakSelf = self;
		self.isValidEmail = NO;
		
		[ApiEngine validateEmailAddress:self.txtEmail.text completion:^(NSError *error, BOOL result) {
			if (!weakSelf) return;
			
			if (!error) {
				weakSelf.lblInvalidEmailX.hidden = result;
				
				if (result) {
					weakSelf.isValidEmail = YES;
					CurrentUser.oldEmailAddress = CurrentUser.emailAddress;
					[weakSelf setDirty];
				} else {
					weakSelf.isValidEmail = NO;
					[weakSelf alertInvalidEmail];
				}
			}
		}];
	} else {
		[self setDirty];
	}
}

@end
