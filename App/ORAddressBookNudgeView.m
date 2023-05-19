//
//  ORConnectABView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORAddressBookNudgeView.h"
#import "AddressBook.h"
#import "ORContact.h"
#import "ORFindCCFriendsView.h"
#import "ORContactsListView.h"

@interface ORAddressBookNudgeView () <UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, assign) BOOL showInvites;
@property (nonatomic, assign) BOOL justPaired;

@end

@implementation ORAddressBookNudgeView

- (void)dealloc
{
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.lblTitle.text = @"Connect Address Book";
    self.lblSubtitle.text = @"Find friends & share videos privately";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORConnectAB:) name:@"ORConnectAB" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORAddressBookPaired:) name:@"ORAddressBookPaired" object:nil];
}

- (void)cellTapped:(id)sender
{
    self.showInvites = YES;
//    self.alertView.delegate = nil;
//    self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Address Book"
//                                                message:PERMISSION_AB
//                                               delegate:self
//                                      cancelButtonTitle:@"Don't Ask Again"
//                                      otherButtonTitles:@"Connect", @"Not Now", nil];
//    self.alertView.tag = 1;
//    [self.alertView show];
    
    // Pre-OS permission requests are disabled
    [self requestABPermission];
}

- (void)handleORConnectAB:(NSNotification *)n
{
    self.showInvites = NO;
    self.alertView.delegate = nil;
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Connect Address Book"
                                                message:@"Share this video privately via email or text message directly with people from your address book. They don't need the app to watch the video."
                                               delegate:self
                                      cancelButtonTitle:@"Don't Ask Again"
                                      otherButtonTitles:@"Connect", @"Not Now", nil];
    self.alertView.tag = 1;
    [self.alertView show];
}

- (void)handleORAddressBookPaired:(NSNotification *)n
{
    [RVC hideNudge:self];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    
    if (alertView.tag == 1) {
        if (buttonIndex == alertView.cancelButtonIndex) { // Don't ask again
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"dontShowConnectAB"];
            [defaults synchronize];

            [RVC hideNudge:self];
        } else if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self requestABPermission];
        } else {
            if (self.showInvites) [RVC hideNudge:self];
        }
    }
}

- (void)requestABPermission
{
    // Check for AB Authorization Status
    if (ABAddressBookGetAuthorizationStatus != NULL) {
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        
        if (status == kABAuthorizationStatusAuthorized) {
            // OK, we're authorized, will continue
            [self loadABContacts];
        } else if (status == kABAuthorizationStatusNotDetermined) {
            // Ask
            [self requestABPermissionNative];
        } else {
            // Denied
            [self abPermissionDenied];
        }
    }
}

- (void)requestABPermissionNative
{
    // Present the Address Book access request to the user
    ABAddressBook *ab = [ABAddressBook sharedAddressBook];
    
    [ab authorize:^(bool granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                [self abPermissionDenied];
            } else {
                self.justPaired = YES;
                [self loadABContacts];
            }
        });
    }];
}

- (void)abPermissionDenied
{
    [[[UIAlertView alloc] initWithTitle:@"Address Book"
                                message:PERMISSION_AB_OS_DENIED
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];

    [RVC hideNudge:self];
}

- (void)loadABContacts
{
    self.lblSubtitle.text = @"Loading contacts...";
    
    BOOL showInvites = self.showInvites;
    BOOL justPaired = self.justPaired;
    
    [[ORDataController sharedInstance] addressBookContactsForceReload:YES cacheOnly:NO match:YES completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        
        if (items) {
            NSMutableArray *following = [NSMutableArray arrayWithCapacity:10];
            NSMutableArray *notFollowing = [NSMutableArray arrayWithCapacity:10];
            NSMutableOrderedSet *others = [NSMutableOrderedSet orderedSetWithCapacity:10];
            NSOrderedSet *friends = CurrentUser.following;
            
            for (ORContact *contact in items) {
                if (contact.user) {
                    if ([contact.user.userId isEqualToString:CurrentUser.userId]) continue;
                    
                    if ([friends containsObject:contact.user]) {
                        [following addObject:contact.user];
                    } else {
                        [notFollowing addObject:contact.user];
                    }
                } else {
                    [others addObject:contact];
                }
            }
            
            // TODO: Find Friends
//            if (notFollowing.count > 0) {
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"ORWillDisplayFindFriends" object:nil];
//                
//                ORFindCCFriendsView *vc = [[ORFindCCFriendsView alloc] initWithNotFollowing:notFollowing andFollowing:following andContacts:[items array]];
//                [AppDelegate forcePortrait];
//                [RVC presentModalVC:vc];
//            }
            
            if (showInvites && others.count > 0) {
                ORContactsListView *ff = [[ORContactsListView alloc] initWithType:ORFindFriendsAddressBook contacts:others];
                [RVC pushToMainViewController:ff completion:^{
                    [RVC hideNudge:self];
                }];
                
                return;
            }
        }
        
        if (justPaired) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORAddressBookPaired" object:nil];
        } else {
            [RVC hideNudge:self];
        }
    }];
}

@end
