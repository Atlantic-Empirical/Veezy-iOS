//
//  ORFollowersFollowingListView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/15/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORFollowersFollowingListView : UIViewController

- (id)initForFollowers:(BOOL)forFollowers;

@property (weak, nonatomic) IBOutlet UITableView *tblMain;

@end
