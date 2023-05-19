//
//  ORContactSelectView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import "ORDirectSendView.h"
#import "ORNavigationController.h"
#import "ORUserCell.h"
#import "ORLoadingCell.h"
#import "MBContactPicker.h"
#import "ORContact.h"
#import "ORDSContact.h"
#import "ABAddressBook.h"
#import "ORWebView.h"

@interface ORDirectSendView () <UIAlertViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, MBContactPickerDataSource, MBContactPickerDelegate, ORGoogleEngineDelegate, ORWebViewDelegate>

@property (nonatomic, strong) OREpicVideo *video;
@property (nonatomic, strong) MBContactPicker *contactPicker;
@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSArray *selectedContacts;
@property (nonatomic, assign) BOOL isLoadingUsers;
@property (nonatomic, strong) NSSet *alreadySelectedContacts;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSArray *twitterAccounts;
@property (nonatomic, strong) NSString *suggestedContactsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *suggestedContacts;
@property (nonatomic, assign) BOOL didCancel;

@property (nonatomic, strong) NSMutableArray *selectedEmails;
@property (nonatomic, strong) NSMutableArray *selectedPhones;
@property (nonatomic, strong) NSArray *selectedUserIds;
@property (nonatomic, assign) BOOL sent;

@end

@implementation ORDirectSendView

static NSString *loadingCell = @"LoadingCell";
static NSString *searchCell = @"SearchCell";
static NSString *userCell = @"UserCell";

- (void)dealloc
{
    AppDelegate.ge.delegate = nil;
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithVideo:(OREpicVideo *)video andSelectedContacts:(NSArray *)selectedContacts
{
    self = [super init];
    if (!self) return nil;
    
    self.video = video;
    self.alreadySelectedContacts = [NSSet setWithArray:selectedContacts];
    
    return self;
}

- (id)initWithVideo:(OREpicVideo *)video
{
    self = [super init];
    if (!self) return nil;
    
    self.video = video;
    
    if (video.authorizedKeys.count > 0) {
        NSMutableSet *selected = [NSMutableSet setWithCapacity:video.authorizedKeys.count];
        for (NSString *contactId in video.authorizedKeys) {
            ORDSContact *contact = [[ORDSContact alloc] init];
            contact.contactId = contactId;
            [selected addObject:contact];
        }

        self.alreadySelectedContacts = selected;
    }
    
    return self;
}

- (void)setWillSendDirectly:(BOOL)willSendDirectly
{
    _willSendDirectly = willSendDirectly;
    if (willSendDirectly) self.alreadySelectedContacts = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = @"D I R E C T";
	self.screenName = @"DirectSend";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.viewLoadingInner.layer.cornerRadius = 10.0f;

    self.contactPicker = [[MBContactPicker alloc] initWithFrame:self.viewContactPicker.bounds];
    self.contactPicker.translatesAutoresizingMaskIntoConstraints = YES;
    self.contactPicker.frame = self.viewContactPicker.bounds;
    self.contactPicker.placeholder = @" Send video privately";
    self.contactPicker.showThumbnails = YES;
    self.contactPicker.showPrompt = NO;
    self.contactPicker.maxVisibleRows = 3;
    self.contactPicker.allowsCompletionOfSelectedContacts = NO;
    [self.viewContactPicker addSubview:self.contactPicker];
    
    [self.contactPicker setCustomBackgroundColor:[UIColor clearColor]];
    
    self.contactPicker.datasource = self;
    self.contactPicker.delegate = self;

    self.lblAutotitle.text = self.video.autoTitle;
	self.lblDuration.text = self.video.friendlyDurationString;

    if (self.video.thumbnailURL && ![self.video.thumbnailURL isEqualToString:@""]) {
        NSString *local = nil;
        
        if ([self.video.userId isEqualToString:CurrentUser.userId]) {
            NSString *file = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, self.video.thumbnailIndex];
            local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", self.video.videoId, file]];
        }
        
        if (local && [[NSFileManager defaultManager] fileExistsAtPath:local]) {
            UIImage *thumb = [UIImage imageWithContentsOfFile:local];
            [self.imgThumbnail setImage:thumb];
        } else {
            NSURL *url = [NSURL URLWithString:self.video.thumbnailURL];
            __weak ORDirectSendView *weakSelf = self;
            __weak OREpicVideo *weakVideo = self.video;
            
            [self.imgThumbnail setImage:nil];
            
            [[ORCachedEngine sharedInstance] imageAtURL:url size:((UIImageView *)self.imgThumbnail).frame.size fill:NO maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                if (error) {
                    NSLog(@"Error: %@", error);
                    
                    if ([weakSelf.video isEqual:weakVideo]) {
                        [weakSelf.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
                    }
                } else if (image && [weakSelf.video isEqual:weakVideo]) {
                    [weakSelf.imgThumbnail setImage:image];
                }
            }];
        }
    } else {
        [self.imgThumbnail setImage:[UIImage imageNamed:@"video"]]; // put default in place
    }
	
    [self initSuggestedContacts];
    [self layoutContactPicker];
    [self reloadContacts];
    [self configureButtons];
    [self updateNavBar:self.alreadySelectedContacts.count];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.view endEditing:animated];
}

- (void)layoutContactPicker
{
    CGRect f = self.viewContactPickerParent.frame;
    f.origin.y = 84.0f;
    f.size.height = self.contactPicker.currentContentHeight + 28.0f;
    self.viewContactPickerParent.frame = f;
    self.contactPicker.frame = self.viewContactPicker.bounds;
}

- (void)viewWillAppear:(BOOL)animated
{
//    if (ABAddressBookGetAuthorizationStatus != NULL) {
//        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
//        
//        if (status == kABAuthorizationStatusNotDetermined) {
//            self.alertView = [[UIAlertView alloc] initWithTitle:@"Address Book"
//                                                        message:@"Would you like to send this video to your contacts via e-mail or text?"
//                                                       delegate:self
//                                              cancelButtonTitle:@"Not Now"
//                                              otherButtonTitles:@"Connect Address Book", nil];
//            self.alertView.tag = 1;
//            [self.alertView show];
//        }
//    }
    
    if (self.focusOnDisplay) {
        [self.contactPicker becomeFirstResponder];
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UI

- (IBAction)btnAddressBook_TouchUpInside:(id)sender
{
//    [self loadAddressBookContactsForceReload:YES];
}

- (IBAction)btnGmail_TouchUpInside:(id)sender
{
//    [self startGoogleSignIn];
}

- (void)btnCancel_TouchUpInside:(id)sender
{
    self.didCancel = YES;
    self.viewLoading.hidden = YES;
}

#pragma mark - MBContactPickerDataSource

- (NSArray *)contactModelsForContactPicker:(MBContactPicker*)contactPickerView
{
    return self.allContacts;
}

- (NSArray *)selectedContactModelsForContactPicker:(MBContactPicker*)contactPickerView
{
    return self.selectedContacts;
}

- (NSArray *)suggestedContactModelsForContactPicker:(MBContactPicker *)contactPickerView
{
    return [self.suggestedContacts array];
}

#pragma mark - MBContactPickerDelegate

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Select: %@", model.contactTitle);
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Add: %@", model.contactTitle);
    [self addContactToSuggested:model];
    
    [self updateNavBar:self.contactPicker.contactsSelected.count];
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    NSLog(@"Did Remove: %@", model.contactTitle);
    
    [self updateNavBar:self.contactPicker.contactsSelected.count];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	
    switch (alertView.tag) {
        case 1: { // Address Book Permission
            if (buttonIndex == alertView.cancelButtonIndex) return;
            [self requestAddressBookPermissionNative];
            break;
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 1: { // Twitter Sign In
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                return;
            }
            
            if (buttonIndex < self.twitterAccounts.count) {
                [self twitterAccountSelected:buttonIndex];
            }
            
            break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.twitterAccounts = nil;
}

#pragma mark - Custom

- (IBAction)selectContacts:(id)sender
{
    [self.delegate contactSelectView:self didSelectContacts:self.contactPicker.contactsSelected];
}

- (void)updateNavBar:(NSUInteger)count
{
    if (self.contactPicker.isFirstResponder) {
        if (self.focusOnDisplay) {
            UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
            self.navigationItem.leftBarButtonItem = cancel;
            
            if (count > 0) {
                if (self.willSendDirectly) {
                    UIBarButtonItem *select = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Send (%d)", count] style:UIBarButtonItemStyleDone target:self action:@selector(selectContacts:)];
                    self.navigationItem.rightBarButtonItem = select;
                } else {
                    UIBarButtonItem *select = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Done (%d)", count] style:UIBarButtonItemStyleDone target:self action:@selector(selectContacts:)];
                    self.navigationItem.rightBarButtonItem = select;
                }
            }
        } else {
            UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(directSendDone:)];
            self.navigationItem.leftBarButtonItem = done;
            self.navigationItem.rightBarButtonItem = nil;
        }
    } else {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.leftBarButtonItem = cancel;

        if (count > 0) {
            if (self.willSendDirectly) {
                UIBarButtonItem *select = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Send (%d)", count] style:UIBarButtonItemStyleDone target:self action:@selector(selectContacts:)];
                self.navigationItem.rightBarButtonItem = select;
            } else {
                UIBarButtonItem *select = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"Done (%d)", count] style:UIBarButtonItemStyleDone target:self action:@selector(selectContacts:)];
                self.navigationItem.rightBarButtonItem = select;
            }
        } else if (self.alreadySelectedContacts.count > 0 && !self.willSendDirectly) {
            UIBarButtonItem *clear = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleDone target:self action:@selector(selectContacts:)];
            self.navigationItem.rightBarButtonItem = clear;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate contactSelectViewDidCancel:self];
}

- (void)reloadContacts
{
    self.isLoadingUsers = YES;
    __weak ORDirectSendView *weakSelf = self;
    
    [[ORDataController sharedInstance] allDSContactsWithSelected:self.alreadySelectedContacts completion:^(NSError *error, NSArray *contacts, NSArray *selected) {
        if (error) NSLog(@"Error: %@", error);
        
        weakSelf.allContacts = contacts;
        weakSelf.selectedContacts = selected;
        
        weakSelf.isLoadingUsers = NO;
        [weakSelf updateNavBar:weakSelf.selectedContacts.count];
        [weakSelf.contactPicker reloadData];
    }];
}

- (void)configureButtons
{
    self.btnAddressBook.hidden = NO;
    self.btnGmail.hidden = NO;
    self.viewConnect.alpha = 1.0f;

//    // Address Book
//    if (ABAddressBookGetAuthorizationStatus != NULL) {
//        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
//        
//        if (status == kABAuthorizationStatusAuthorized) {
//            self.btnAddressBook.hidden = YES;
//		}
//    }
//    
//    // Google
//    if (AppDelegate.ge.isAuthenticated) {
//        self.btnGmail.hidden = YES;
//    }
    
    if (self.btnAddressBook.hidden && self.btnGmail.hidden) {
        self.viewConnect.alpha = 0;
    }
}

- (void)initSuggestedContacts
{
    self.suggestedContactsFilename = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/suggested_contacts.cache"];
    self.suggestedContacts = [NSKeyedUnarchiver unarchiveObjectWithFile:self.suggestedContactsFilename];
    if (!self.suggestedContacts) self.suggestedContacts = [NSMutableOrderedSet orderedSetWithCapacity:1];
}

- (void)addContactToSuggested:(id<MBContactPickerModelProtocol>)contact
{
    if (!contact) return;
    
    if ([self.suggestedContacts containsObject:contact]) [self.suggestedContacts removeObject:contact];
    [self.suggestedContacts insertObject:contact atIndex:0];
    [NSKeyedArchiver archiveRootObject:self.suggestedContacts toFile:self.suggestedContactsFilename];
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
                [self configureButtons];
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
            NSLog(@"User denied Address Book access");
            return;
        }
    }
    
    self.didCancel = NO;
    self.lblLoading.text = @"Reloading Contacts";
    self.viewLoading.hidden = NO;
    
    __weak ORDirectSendView *weakSelf = self;
    
    [[ORDataController sharedInstance] addressBookContactsForceReload:forceReload cacheOnly:NO match:YES completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        weakSelf.viewLoading.hidden = YES;
        [weakSelf reloadContacts];
    }];
}

#pragma mark - Twitter

- (void)startTwitterSignIn
{
    [AppDelegate.twitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
        if (error) NSLog(@"Error: %@", error);
        
        if (items.count > 0) {
            self.twitterAccounts = items;
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select a Twitter account to use with Veezy:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            sheet.tag = 1;
            
            for (ACAccount *account in items) {
                [sheet addButtonWithTitle:account.accountDescription];
            }
            
            sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
            [sheet showFromToolbar:self.navigationController.toolbar];
        } else {
            if (error && error.code == 403) {
                // Not authorized
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access to Twitter denied"
                                                                message:@"Please authorize Veezy to use your Twitter accounts in iOS Settings > Twitter then try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                // No accounts
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Twitter Account"
                                                                message:@"It seems there are no Twitter accounts connected on this device - add one in iOS Settings > Twitter then try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }];
}

- (void)twitterAccountSelected:(NSUInteger)idx
{
    self.didCancel = NO;
    self.lblLoading.text = @"Connecting Twitter";
    self.viewLoading.hidden = NO;
    
    [AppDelegate.twitterEngine reverseAuthWithAccount:self.twitterAccounts[idx] completion:^(NSError *error) {
        if (self.didCancel) {
            NSLog(@"Twitter signed in, but user did cancel before");
            self.didCancel = NO;
            
            return;
        }
        
        if (error) {
            self.viewLoading.hidden = YES;
            
            NSLog(@"Error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        if (AppDelegate.twitterEngine.isAuthenticated) {
            NSLog(@"Authenticated with Twitter as @%@", AppDelegate.twitterEngine.screenName);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORTwitterPaired" object:nil];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs removeObjectForKey:@"twitterDisabled"];
            [prefs setObject:AppDelegate.twitterEngine.token forKey:@"twitterToken"];
            [prefs setObject:AppDelegate.twitterEngine.tokenSecret forKey:@"twitterTokenSecret"];
            [prefs setObject:AppDelegate.twitterEngine.userId forKey:@"twitterUserId"];
            [prefs setObject:AppDelegate.twitterEngine.screenName forKey:@"twitterScreenName"];
            [prefs setObject:AppDelegate.twitterEngine.userName forKey:@"twitterUserName"];
            [prefs synchronize];
            
            CurrentUser.twitterId = AppDelegate.twitterEngine.userId;
            CurrentUser.twitterToken = AppDelegate.twitterEngine.token;
            CurrentUser.twitterSecret = AppDelegate.twitterEngine.tokenSecret;
            CurrentUser.twitterName = AppDelegate.twitterEngine.screenName;
            
            OREpicUser *u = [OREpicUser new];
            u.userId = CurrentUser.userId;
            u.twitterId = CurrentUser.twitterId;
            u.twitterToken = CurrentUser.twitterToken;
            u.twitterSecret = CurrentUser.twitterSecret;
            u.twitterName = CurrentUser.twitterName;
            
            [ApiEngine savePairing:u cb:^(NSError *error, BOOL result) {
                if (self.didCancel) {
                    NSLog(@"Twitter signed in, but user did cancel before");
                    self.didCancel = NO;
                    
                    return;
                }
                
                if (error || !result) {
                    NSString *screenName = AppDelegate.twitterEngine.screenName;
                    [AppDelegate.twitterEngine resetOAuthToken];
                    
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs removeObjectForKey:@"twitterDisabled"];
                    [prefs removeObjectForKey:@"twitterToken"];
                    [prefs removeObjectForKey:@"twitterTokenSecret"];
                    [prefs removeObjectForKey:@"twitterUserId"];
                    [prefs removeObjectForKey:@"twitterScreenName"];
                    [prefs removeObjectForKey:@"twitterUserName"];
                    [prefs synchronize];
                    
                    CurrentUser.twitterId = nil;
                    CurrentUser.twitterToken = nil;
                    CurrentUser.twitterSecret = nil;
                    CurrentUser.twitterName = nil;
                    
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                        message:PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    } else if (!result) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"@%@", screenName]
                                                                        message:PAIRING_MESSAGE_TWACCOUNT_PAIRED_TO_OTHER_CCACCOUNT
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                }
                
                [CurrentUser saveLocalUser];
                [self loadTwitterContactsForceReload:YES];
            }];
        }
    }];
}

- (void)loadTwitterContactsForceReload:(BOOL)forceReload
{
    self.didCancel = NO;
    self.lblLoading.text = @"Reloading Contacts";
    self.viewLoading.hidden = NO;
    
    __weak ORDirectSendView *weakSelf = self;
    
    [[ORDataController sharedInstance] twitterContactsForceReload:forceReload cacheOnly:NO completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        weakSelf.viewLoading.hidden = YES;
        [weakSelf reloadContacts];
    }];
}

#pragma mark - Google

- (void)startGoogleSignIn
{
    self.didCancel = NO;
    self.lblLoading.text = @"Connecting Google";
    self.viewLoading.hidden = NO;
    
    AppDelegate.ge.delegate = self;
    
    __weak ORDirectSendView *weakSelf = self;
    [AppDelegate.ge authenticateWithCompletion:^(NSError *error) {
        if (error) {
            if (error) {
                self.viewLoading.hidden = YES;
                
                NSLog(@"Error: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:PAIRING_MESSAGE_GO_UNABLE_TO_USE_SELECTED_ACCOUNT
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            }
        }
        
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
                [self configureButtons];
                [weakSelf loadGoogleContactsForceReload:YES];
            }];
        }
    }];
}

- (void)loadGoogleContactsForceReload:(BOOL)forceReload
{
    self.didCancel = NO;
    self.lblLoading.text = @"Reloading Contacts";
    self.viewLoading.hidden = NO;
    
    __weak ORDirectSendView *weakSelf = self;
    
    [[ORDataController sharedInstance] googleContactsForceReload:forceReload cacheOnly:NO completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        weakSelf.viewLoading.hidden = YES;
        [weakSelf reloadContacts];
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

#pragma mark - Sending

- (void)prepareDirectForContacts:(NSArray *)contacts
{
    if (contacts.count > 0) {
        self.selectedEmails = [NSMutableArray arrayWithCapacity:1];
        self.selectedPhones = [NSMutableArray arrayWithCapacity:1];
        
        NSMutableSet *userIds = [NSMutableSet setWithCapacity:contacts.count];
        NSMutableSet *names = [NSMutableSet setWithCapacity:contacts.count];
        NSMutableSet *keys = [NSMutableSet setWithCapacity:contacts.count];
        
        for (ORDSContact *contact in contacts) {
            if (contact.type == ORContactTypeCloudCamGroup) {
                for (NSString *userId in contact.group.userIds) {
                    if (![userId isEqualToString:CurrentUser.userId]) {
                        [userIds addObject:userId];
                    }
                }
            } else if (contact.type == ORContactTypeCloudCam) {
                if (contact.user) {
                    [userIds addObject:contact.user.userId];
                }
            } else if (!ORIsEmpty(contact.email)) {
                // Don't send again for external contacts
                if (![self.video.authorizedKeys containsObject:contact.contactId]) {
                    [self.selectedEmails addObject:contact.email];
                }
            } else if (!ORIsEmpty(contact.phone)) {
                // Don't send again for external contacts
                if (![self.video.authorizedKeys containsObject:contact.contactId]) {
                    [self.selectedPhones addObject:contact.phone];
                }
            }
            
            [names addObject:contact.name];
            [keys addObject:contact.contactId];
        }
        
        if (self.willSendDirectly) {
            self.selectedUserIds = [userIds allObjects];
        } else {
            self.video.authorizedUserIds = (userIds.count > 0) ? [userIds allObjects] : nil;
            self.video.authorizedNames = (names.count > 0) ? [names allObjects] : nil;
            self.video.authorizedKeys = (keys.count > 0) ? [keys allObjects] : nil;
        }
    }
}

- (void)sendDirect
{
    self.sent = NO;
    
    if (self.selectedUserIds.count > 0 && self.willSendDirectly) {
        [self sendDirectToServer];
    }
    
    if (self.selectedEmails.count > 0) {
        [self displayEmailComposer];
    } else if (self.selectedPhones.count > 0) {
        [self displaySMSComposer];
    } else {
        [self.delegate contactSelectView:self didFinishSending:self.sent];
    }
}

- (void)sendDirectToServer
{
    OREpicVideo *video = [OREpicVideo new];
    video.videoId = self.video.videoId;
    video.authorizedUserIds = self.selectedUserIds;
    self.sent = YES;
    
    [ApiEngine directSendVideo:video cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
    }];
    
    BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
    [AppDelegate.mixpanel track:@"Direct Send" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"Veezy", @"Self": @(isSelf)}];
    [ORLoggingEngine logEvent:@"VideoSent" params:[@[self.video.videoId, @"Veezy", @(isSelf)] mutableCopy]];
}

#pragma mark - E-Mail

- (void)displayEmailComposer
{
    [AppDelegate nativeBarAppearance_nativeShare];
	
	MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
	if ([MFMailComposeViewController canSendMail]) {
//        NSString *action;
		NSString *body;
		NSString *subject;
		if ([self.video.userId isEqualToString:CurrentUser.userId]) {
			
			body = [NSString stringWithFormat:@"<p>Hey! Check out my video - <a href=\"%@\">%@</a>.", self.video.playerUrlSelected, self.video.autoTitle];
			
//			action = @"shot with";
//			body = [NSString stringWithFormat:@"<p>Hey! Check out this video I %@ Veezy - <a href=\"%@\">%@</a>. Get the iPhone app now, <a href=\"http://appstore.com/veezy\">http://appstore.com/veezy</a>", action, self.video.playerUrlSelected, self.video.autoTitle];
			
			subject = [NSString stringWithFormat:@"My video: %@", self.video.autoTitle];

		} else {
			
			body = [NSString stringWithFormat:@"<p>Hey! Check out this video I found on Veezy - <a href=\"%@\">%@</a>.", self.video.playerUrlSelected, self.video.autoTitle];

//			action = @"shot with";
//			body = [NSString stringWithFormat:@"<p>Hey! Check out this video I %@ Veezy - <a href=\"%@\">%@</a>. Get the iPhone app now, <a href=\"http://appstore.com/veezy\">http://appstore.com/veezy</a>", action, self.video.playerUrlSelected, self.video.autoTitle];
			
			subject = [NSString stringWithFormat:@"Check out this video: %@", self.video.autoTitle];
		}
		
        [controller setSubject:subject];
		[controller setMessageBody:body isHTML:YES];
        [controller setToRecipients:self.selectedEmails];
        [controller setMailComposeDelegate:self];
		[self.parent presentViewController:controller animated:YES completion:nil];
	} else {
        [AppDelegate nativeBarAppearance_default];
        
        if (self.selectedPhones.count > 0) {
            [self displaySMSComposer];
        } else {
            [self.delegate contactSelectView:self didFinishSending:self.sent];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [AppDelegate nativeBarAppearance_default];
    
	[self.parent dismissViewControllerAnimated:YES completion:^{
		switch (result) {
			case MFMailComposeResultSent:
				NSLog(@"Email sent");
                self.sent = YES;

                BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
                [AppDelegate.mixpanel track:@"Direct Send" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"Mail", @"Self": @(isSelf)}];
                [ORLoggingEngine logEvent:@"VideoSent" params:[@[self.video.videoId, @"Mail", @(isSelf)] mutableCopy]];
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
        
        if (self.selectedPhones.count > 0) {
            [self displaySMSComposer];
        } else {
            [self.delegate contactSelectView:self didFinishSending:self.sent];
        }
	}];
}

#pragma mark - SMS

- (void)displaySMSComposer
{
    [AppDelegate nativeBarAppearance_nativeShare];
	
	NSString *result;
	if ([self.video.userId isEqualToString:CurrentUser.userId]) {
		result = [NSString stringWithFormat:@"Check out my video %@ - %@", self.video.autoTitle, self.video.playerUrlSelected];
	} else {
		result = [NSString stringWithFormat:@"Check out this video %@ - %@", self.video.autoTitle, self.video.playerUrlSelected];
	}
	
//    NSString *action = ([self.video.userId isEqualToString:CurrentUser.userId]) ? @"shot with" : @"found in";
//	NSString *result = [NSString stringWithFormat:@"Hey! Check out this video I %@ Veezy at %@ - %@. Get the iPhone app now: http://appstore.com/veezy", action, self.video.locationFriendlyName, self.video.playerUrlSelected];
    
	MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if ([MFMessageComposeViewController canSendText]) {
        [controller setBody:result];
        [controller setRecipients:self.selectedPhones];
        [controller setMessageComposeDelegate:self];
		[self.parent presentViewController:controller animated:YES completion:nil];
	} else {
        [AppDelegate nativeBarAppearance_default];
        [self.delegate contactSelectView:self didFinishSending:self.sent];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [AppDelegate nativeBarAppearance_default];
    
	[self.parent dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MessageComposeResultSent:
                NSLog(@"Message sent");
                self.sent = YES;

                BOOL isSelf = [self.video.userId isEqualToString:CurrentUser.userId];
                [AppDelegate.mixpanel track:@"Direct Send" properties:@{@"VideoId": self.video.videoId, @"ShareType": @"Message", @"Self": @(isSelf)}];
                [ORLoggingEngine logEvent:@"VideoSent" params:[@[self.video.videoId, @"Message", @(isSelf)] mutableCopy]];
                break;
                
            case MessageComposeResultCancelled:
                NSLog(@"Message cancelled");
                break;
                
            case MessageComposeResultFailed:
                NSLog(@"Message failed");
                break;
        }
        
		[self.delegate contactSelectView:self didFinishSending:self.sent];
	}];
}

#pragma mark - Keyboard

- (void)directSendDone:(id)sender
{
    [self.contactPicker resignFirstResponder];
}

-(void)keyboardWillShow:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGFloat keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    if (self.contactPicker.isFirstResponder) {
		if (CurrentUser.accountType == 3) {
			[RVC presentSignInWithMessage:@"Sign-in to use direct send." completion:^(BOOL success) {
			}];
		} else {
            if (self.focusOnDisplay) {
				CGRect f = self.viewContactPickerParent.frame;
                f.origin.y = 0.0f;
				f.size.height = CGRectGetMaxY(self.view.bounds) - keyboardHeight;
				self.viewContactPickerParent.frame = f;
				self.contactPicker.frame = self.viewContactPicker.bounds;
                [self.contactPicker showSearchTableView];

                [self updateNavBar:self.contactPicker.contactsSelected.count];
            } else {
                [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
                    CGRect f = self.viewContactPickerParent.frame;
                    f.origin.y = 0.0f;
                    f.size.height = CGRectGetMaxY(self.view.bounds) - keyboardHeight;
                    self.viewContactPickerParent.frame = f;
                    self.contactPicker.frame = self.viewContactPicker.bounds;
                    [self.contactPicker showSearchTableView];

                    [self updateNavBar:self.contactPicker.contactsSelected.count];
                }];
				self.title = @"D  I  R  E  C  T";
            }
		}
        
        return;
    }
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    if (self.contactPicker.isFirstResponder) {
        [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
            [self layoutContactPicker];
            [self.contactPicker hideSearchTableView];
            
            [self updateNavBar:self.contactPicker.contactsSelected.count];
        }];
    }
}

@end
