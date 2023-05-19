//
//  ORInviteUserCell.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 14/05/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORInviteUserCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imgAvatar;
@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblSubtitle;
@property (nonatomic, weak) IBOutlet UIButton *btnInvite;

@property (nonatomic, strong) OREpicFriend *user;
@property (nonatomic, strong) ORContact *contact;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, weak) UIViewController *parent;

- (IBAction)btnInvite_TouchUpInside:(id)sender;

@end
