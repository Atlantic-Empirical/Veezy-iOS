//
//  ORProfileView.h
//  epic
//
//  Created by Thomas Purnell-Fisher on 10/24/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORUserProfileView : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *viewTab;
@property (weak, nonatomic) IBOutlet UIButton *btnProfile;
@property (weak, nonatomic) IBOutlet UIButton *btnVideos;
@property (weak, nonatomic) IBOutlet UIButton *btnFavs;
@property (weak, nonatomic) IBOutlet UIButton *btnNetwork;
@property (weak, nonatomic) IBOutlet UIView *viewIndicator;
@property (weak, nonatomic) IBOutlet UIView *viewSeparator0;
@property (weak, nonatomic) IBOutlet UIView *viewSeparator2;
@property (weak, nonatomic) IBOutlet UIView *viewPeopleHost;

@property (nonatomic, assign) BOOL openInConnect;
@property (nonatomic, assign) BOOL askToFollow;
@property (nonatomic, strong) OREpicFriend *user;

- (id)initWithFriend:(OREpicFriend *)eFriend;

- (IBAction)btnProfile_TouchUpInside:(id)sender;
- (IBAction)btnVideos_TouchUpInside:(id)sender;
- (IBAction)btnFavs_TouchUpInside:(id)sender;
- (IBAction)btnNetwork_TouchUpInside:(id)sender;

- (void)reorderVideos;
- (void)openUserMap;
- (void)presentUserSettings;

@end
