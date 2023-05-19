//
//  ORUserListView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORUserListView : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL isFollowingList;
@property (nonatomic, assign) BOOL isFollowersList;
@property (nonatomic, assign) BOOL isRequestsList;

- (id)initWithUsers:(NSArray *)users andFollowRequests:(NSArray *)followRequests;
- (id)initWithUsers:(NSArray *)users;

@end
