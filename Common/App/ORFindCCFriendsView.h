//
//  ORFindCCFriendsView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 01/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORFindCCFriendsView : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UILabel *lblDescription;
@property (weak, nonatomic) IBOutlet UITableView *tblFriends;
@property (weak, nonatomic) IBOutlet UIButton *btnFollowAll;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UIView *viewAvatars;
@property (weak, nonatomic) IBOutlet UIControl *viewOverlay;

@property (nonatomic, copy) void (^completionBlock)(BOOL success);

- (id)initWithNotFollowing:(NSArray *)notFollowing andFollowing:(NSArray *)following andContacts:(NSArray *)contacts;

- (IBAction)btnClose_TouchUpInside:(id)sender;
- (IBAction)btnFollowAll_TouchUpInside:(id)sender;
- (IBAction)viewOverlay_TouchUpInside:(id)sender;

@end
