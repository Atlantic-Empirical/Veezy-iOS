//
//  ORFacebookPagesView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORFacebookPagesView : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (id)initWithOwnPages:(NSArray *)ownPages LikedPages:(NSArray *)likedPages;

@end
