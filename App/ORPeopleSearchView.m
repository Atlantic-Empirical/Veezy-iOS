//
//  OREpicSearch.m
//  Epic
//
//  Created by Thomas Purnell-Fisher on 10/29/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORPeopleSearchView.h"
#import "ORUserCell.h"
#import "ORUserProfileView.h"
#import "ORMapView.h"
#import "ORContactsListView.h"
#import "ORPushNotificationPermissionView.h"
#import "ORCell_ImportContactsFacebook.h"
#import "ORCell_ImportContactsTwitter.h"
#import "ORCell_ImportContactsGoogle.h"
#import "ORCell_ImportContactsADB.h"
#import "ORFindCCFriendsView.h"
#import "ORNavigationController.h"
#import "AddressBook.h"
#import "ORWebView.h"
#import "ORContact.h"
#import "ORFacebookConnectView.h"
#import "ORTwitterConnectView.h"
#import "ORInviteFriendsModalView.h"

@interface ORPeopleSearchView () <UITextFieldDelegate, UIAlertViewDelegate, ORGoogleEngineDelegate, ORWebViewDelegate>

@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, weak) OREpicFriend *selectedUser;
@property (nonatomic, strong) ORUserProfileView *userView;
@property (nonatomic, strong) UIAlertView *alertView;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL didCancel;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isSigningIn;

@end

@implementation ORPeopleSearchView

static NSString *userCell = @"UserCell";
static NSString *cell_Facebook = @"cell_Facebook";
static NSString *cell_Twitter = @"cell_Twitter";
static NSString *cell_Google = @"cell_Google";
static NSString *cell_ADB = @"cell_ADB";

- (void)dealloc
{
    AppDelegate.ge.delegate = nil;
    self.tblResults.delegate = nil;
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Connect";
	self.screenName = @"PeopleSearch";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    self.viewLoadingInner.layer.cornerRadius = 10.0f;

    if (self.navigationController.childViewControllers.count == 1) {
//        // Camera as left bar button
//        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = camera;
    }
    
    [self.tblResults registerNib:[UINib nibWithNibName:@"ORCell_ImportContactsFacebook" bundle:nil] forCellReuseIdentifier:cell_Facebook];
    [self.tblResults registerNib:[UINib nibWithNibName:@"ORCell_ImportContactsTwitter" bundle:nil] forCellReuseIdentifier:cell_Twitter];
    [self.tblResults registerNib:[UINib nibWithNibName:@"ORCell_ImportContactsGoogle" bundle:nil] forCellReuseIdentifier:cell_Google];
    [self.tblResults registerNib:[UINib nibWithNibName:@"ORCell_ImportContactsADB" bundle:nil] forCellReuseIdentifier:cell_ADB];
	[self registerForNotifications];
	
	self.txtSearch.placeholder = [NSString stringWithFormat:@"Search for %@ users", APP_NAME];
    [self clearResults];
	self.aiSearch.color = APP_COLOR_PRIMARY;
	self.aiLoading.color = APP_COLOR_PRIMARY;

}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tblResults setContentOffset:CGPointMake(0.0f, -self.tblResults.contentInset.top) animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.isVisible = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.isVisible = NO;
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.users.count > 0) {
        return 44.0f;
    } else {
        return 74.0f;
    }
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.users.count == 0 ? 4 : self.users.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.users.count == 0) {
		switch (indexPath.row) {
			case 0: {
				ORCell_ImportContactsFacebook *cell = [tableView dequeueReusableCellWithIdentifier:cell_Facebook forIndexPath:indexPath];
                [cell updateTitles];
				return cell;
			}
			case 1: {
				ORCell_ImportContactsADB *cell = [tableView dequeueReusableCellWithIdentifier:cell_ADB forIndexPath:indexPath];
                [cell updateTitles];
				return cell;
			}
			case 2: {
				ORCell_ImportContactsGoogle *cell = [tableView dequeueReusableCellWithIdentifier:cell_Google forIndexPath:indexPath];
                [cell updateTitles];
				return cell;
			}
			case 3: {
				ORCell_ImportContactsTwitter *cell = [tableView dequeueReusableCellWithIdentifier:cell_Twitter forIndexPath:indexPath];
                [cell updateTitles];
				return cell;
			}
				
			default:
				break;
		}
    }

	ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:userCell];
    if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:userCell];
    
    OREpicFriend *user = self.users[indexPath.row];
    cell.user = user;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.txtSearch resignFirstResponder];
    
    if (self.users.count == 0) {
		switch (indexPath.row) {
			case 0: { // Facebook
                [self startFacebookConnect];
				break;
			}
			case 1: { // Address Book
                [self loadAddressBookContactsForceReload:YES];
				break;
			}
			case 2: { // Google
                if (AppDelegate.ge.isAuthenticated) {
                    [self loadGoogleContactsForceReload:YES];
                } else {
                    [self startGoogleSignIn];
                }
				break;
			}
			case 3: { // Twitter
                [self startTwitterConnect];
				break;
			}
				
			default:
				break;
		}
		
		return;
	}
	
    self.selectedUser = self.users[indexPath.row];
    
    ORUserProfileView *profile = [[ORUserProfileView alloc] initWithFriend:self.selectedUser];
    [self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	
    switch (alertView.tag) {
        case 1: {
			switch (buttonIndex) {
				case 0: // Allow Access
					[self requestAddressBookPermissionNative];
					break;
				case 1: // Learn More
				{
					ORWebView *wv = [[ORWebView alloc] initWithURLString:@"http://cnn.com"];
					[self.navigationController pushViewController:wv animated:YES];
					break;
				}
				case 2: // Cancel
					break;
				default:
					break;
			}
            break;
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	[self clearResults];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self searchForUsers];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchForUsers) object:nil];
    [self performSelector:@selector(searchForUsers) withObject:nil afterDelay:1.0f];
    
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if ([self.txtSearch.text isEqualToString:@""]) {
		[self clearResults];
	}
}

#pragma mark - UI

- (void)btnCancel_TouchUpInside:(id)sender
{
    self.didCancel = YES;
    self.viewLoading.hidden = YES;
}

- (IBAction)btnInviteFriends_TouchUpInside:(id)sender {
	ORInviteFriendsModalView *vc = [ORInviteFriendsModalView new];
	[self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Custom

- (void)searchForUsers
{
    if (!self.txtSearch.text || [self.txtSearch.text isEqualToString:@""]) {
		[self clearResults];
        return;
    }
    
    // Don't search less than 3 characters
    if (self.txtSearch.text.length < 3) return;
    
    [self.aiSearch startAnimating];
    
    [ApiEngine searchUsers:self.txtSearch.text completion:^(NSError *error, NSArray *result) {
        [self.aiSearch stopAnimating];
        
        self.users = [NSMutableArray arrayWithCapacity:result.count];
        for (OREpicFriend *user in result) {
            if ([user.userId isEqualToString:CurrentUser.userId]) continue;
            [self.users addObject:[CurrentUser relatedUserWithUser:user]];
        }
        
        [self.tblResults reloadData];
    }];
}

- (void)clearResults
{
	self.users = nil;
	[self.tblResults reloadData];
}

#pragma mark - NOTIFICATIONS

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)deregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Facebook

- (void)startFacebookConnect
{
    if (CurrentUser.accountType == 3) {
        self.isVisible = NO;
        self.isSigningIn = YES;
        [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
            self.isVisible = YES;
            self.isSigningIn = NO;
            [self.tblResults reloadData];
        }];
        
        return;
    }
    
    ORFacebookConnectView *vc = [ORFacebookConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        [self.tblResults reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Twitter

- (void)startTwitterConnect
{
    if (CurrentUser.accountType == 3) {
        self.isVisible = NO;
        self.isSigningIn = YES;
        [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
            self.isVisible = YES;
            self.isSigningIn = NO;
            [self.tblResults reloadData];
        }];
        
        return;
    }
    
    ORTwitterConnectView *vc = [ORTwitterConnectView new];
    [vc setCompletionBlock:^(BOOL success) {
        [self.tblResults reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Google

- (void)startGoogleSignIn
{
    if (CurrentUser.accountType == 3) {
        self.isVisible = NO;
        self.isSigningIn = YES;
        [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
            self.isVisible = YES;
            self.isSigningIn = NO;
            [self.tblResults reloadData];
        }];
        
        return;
    }

    self.didCancel = NO;
    self.lblLoading.text = @"Connecting Google";
    self.viewLoading.hidden = NO;
    
    AppDelegate.ge.delegate = self;
    
    __weak ORPeopleSearchView *weakSelf = self;
    [AppDelegate.ge authenticateWithCompletion:^(NSError *error) {
        weakSelf.viewLoading.hidden = YES;
        if (error) NSLog(@"Error: %@", error);
        
        if (AppDelegate.ge.isAuthenticated) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:AppDelegate.ge.token forKey:@"googleToken"];
            [prefs setObject:AppDelegate.ge.tokenSecret forKey:@"googleTokenSecret"];
            [prefs setObject:AppDelegate.ge.userID forKey:@"googleUserID"];
            [prefs setObject:AppDelegate.ge.userName forKey:@"googleUserName"];
            [prefs setObject:AppDelegate.ge.userEmail forKey:@"googleUserEmail"];
            [prefs setObject:AppDelegate.ge.profilePicture forKey:@"googleProfilePicture"];
            [prefs synchronize];
            
            NSLog(@"Authenticated with Google: %@", AppDelegate.ge.userEmail);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGooglePaired" object:nil];
            
            CurrentUser.googleToken = AppDelegate.ge.token;
            CurrentUser.googleSecret = AppDelegate.ge.tokenSecret;
            
            OREpicUser *u = [OREpicUser new];
            u.userId = CurrentUser.userId;
            u.googleToken = CurrentUser.googleToken;
            u.googleSecret = CurrentUser.googleSecret;
            
            [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
                if (error || !result) {
                    NSString *email = AppDelegate.ge.userEmail;
                    [AppDelegate.ge resetOAuthToken];
                    
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs removeObjectForKey:@"googleToken"];
                    [prefs removeObjectForKey:@"googleTokenSecret"];
                    [prefs removeObjectForKey:@"googleUserID"];
                    [prefs removeObjectForKey:@"googleUserEmail"];
                    [prefs removeObjectForKey:@"googleUserName"];
                    [prefs removeObjectForKey:@"googleProfilePicture"];
                    [prefs synchronize];
                    
                    CurrentUser.googleToken = nil;
                    CurrentUser.googleSecret = nil;
                    
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                        message:PAIRING_MESSAGE_GO_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    } else if (!result) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"@%@", email]
                                                                        message:PAIRING_MESSAGE_GOACCOUNT_PAIRED_TO_OTHER_CCACCOUNT
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                }
                
                [CurrentUser saveLocalUser];
                [weakSelf loadGoogleContactsForceReload:YES];
            }];
        }
    }];
}

- (void)loadGoogleContactsForceReload:(BOOL)forceReload
{
    self.didCancel = NO;
    self.lblLoading.text = @"Loading Contacts";
    self.viewLoading.hidden = NO;
    
    __weak ORPeopleSearchView *weakSelf = self;
    
    [[ORDataController sharedInstance] googleContactsForceReload:forceReload cacheOnly:NO completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        weakSelf.viewLoading.hidden = YES;
        
        if (items) {
            if (forceReload) {
                NSMutableArray *following = [NSMutableArray arrayWithCapacity:10];
                NSMutableArray *notFollowing = [NSMutableArray arrayWithCapacity:10];
                NSOrderedSet *friends = CurrentUser.following;
                
                for (ORContact *contact in items) {
                    if (contact.user) {
                        if ([contact.user.userId isEqualToString:CurrentUser.userId]) continue;
                        
                        if ([friends containsObject:contact.user]) {
                            [following addObject:contact.user];
                        } else {
                            [notFollowing addObject:contact.user];
                        }
                    }
                }
                
                // TODO: Find Friends
                
//                if (notFollowing.count > 0) {
//                    ORFindCCFriendsView *vc = [[ORFindCCFriendsView alloc] initWithNotFollowing:notFollowing andFollowing:following andContacts:[items array]];
//                    [AppDelegate forcePortrait];
//                    [RVC presentModalVC:vc];
//                }
            }
            
            ORContactsListView *ff = [[ORContactsListView alloc] initWithType:ORFindFriendsGoogle contacts:items];
            [weakSelf.navigationController pushViewController:ff animated:YES];
        }
    }];
}

- (void)googleEngine:(ORGoogleEngine *)engine needsToOpenURL:(NSURL *)url
{
    if (self.didCancel) {
        self.viewLoading.hidden = YES;
        return;
    }
    
    ORWebView *wv = [[ORWebView alloc] initWithURL:url];
    wv.delegate = self;
    wv.callbackURL = AppDelegate.ge.callbackURL;
    
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:wv];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)googleEngine:(ORGoogleEngine *)engine statusUpdate:(NSString *)message
{
    NSLog(@"%@", message);
}

- (void)webView:(ORWebView *)webView didHitCallbackURL:(NSURL *)url
{
    [AppDelegate.ge resumeAuthenticationFlowWithURL:url];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)webView:(ORWebView *)webView didCancelWithError:(NSError *)error
{
    if (error) NSLog(@"Error: %@", error);
    
    self.viewLoading.hidden = YES;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Address Book

- (void)requestAddressBookPermissionUser
{
    // Pre-OS permission requests are disabled
    [self requestAddressBookPermissionNative];
}

- (void)requestAddressBookPermissionNative
{
    // Present the Address Book access request to the user
    ABAddressBook *ab = [ABAddressBook sharedAddressBook];
    
    [ab authorize:^(bool granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                [self addressBookPermissionDenied];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORAddressBookPaired" object:nil];
                [self loadAddressBookContactsForceReload:YES];
            }
        });
    }];
}

- (void)addressBookPermissionDenied
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't load Contacts"
                                                    message:PERMISSION_AB_OS_DENIED
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)loadAddressBookContactsForceReload:(BOOL)forceReload
{
    if (CurrentUser.accountType == 3) {
        self.isVisible = NO;
        self.isSigningIn = YES;
        [RVC presentSignInWithMessage:@"Sign-in to find your friends!" completion:^(BOOL success) {
            self.isVisible = YES;
            self.isSigningIn = NO;
            [self.tblResults reloadData];
        }];
        
        return;
    }

    // Check for AB Authorization Status
    if (ABAddressBookGetAuthorizationStatus != NULL) {
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        
        if (status == kABAuthorizationStatusAuthorized) {
            // OK, we're authorized, will continue
        } else if (status == kABAuthorizationStatusNotDetermined) {
            // Ask
            [self requestAddressBookPermissionUser];
            return;
        } else {
            [self addressBookPermissionDenied];
            return;
        }
    }

    self.didCancel = NO;
    self.lblLoading.text = @"Loading Contacts";
    self.viewLoading.hidden = NO;
    
    __weak ORPeopleSearchView *weakSelf = self;
    
    [[ORDataController sharedInstance] addressBookContactsForceReload:forceReload cacheOnly:NO match:YES completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        weakSelf.viewLoading.hidden = YES;
        
        if (items) {
            if (forceReload) {
                NSMutableArray *following = [NSMutableArray arrayWithCapacity:10];
                NSMutableArray *notFollowing = [NSMutableArray arrayWithCapacity:10];
                NSOrderedSet *friends = CurrentUser.following;
                
                for (ORContact *contact in items) {
                    if (contact.user) {
                        if ([contact.user.userId isEqualToString:CurrentUser.userId]) continue;
                        
                        if ([friends containsObject:contact.user]) {
                            [following addObject:contact.user];
                        } else {
                            [notFollowing addObject:contact.user];
                        }
                    }
                }
                
                // TODO: Find Friends
                
//                if (notFollowing.count > 0) {
//                    ORFindCCFriendsView *vc = [[ORFindCCFriendsView alloc] initWithNotFollowing:notFollowing andFollowing:following andContacts:[items array]];
//                    [AppDelegate forcePortrait];
//                    [RVC presentModalVC:vc];
//                }
            }
            
            ORContactsListView *ff = [[ORContactsListView alloc] initWithType:ORFindFriendsAddressBook contacts:items];
            [weakSelf.navigationController pushViewController:ff animated:YES];
        }
    }];
}

#pragma mark - KEYBOARD

- (void)tapGesture:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

-(void)keyboardWillShow:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.tblResults.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight - self.navigationController.toolbar.frame.size.height, 0);
    }];
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapGesture];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];

    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.tblResults.contentInset = UIEdgeInsetsZero;
    }];
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

@end
