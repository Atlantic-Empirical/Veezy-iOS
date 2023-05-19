//
//  ORUserSelectView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORUserSelectViewDelegate;

@interface ORUserSelectView : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<ORUserSelectViewDelegate> delegate;

@end

@protocol ORUserSelectViewDelegate <NSObject>

- (void)userSelectViewDidCancel:(ORUserSelectView *)userSelect;
- (void)userSelectView:(ORUserSelectView *)userSelect didSelectUser:(OREpicFriend *)user;

@end