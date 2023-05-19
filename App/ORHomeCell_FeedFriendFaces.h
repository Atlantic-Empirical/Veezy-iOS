//
//  ORHomeCell_FeedSummary.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORHomeCell_FeedFriendFaces : UITableViewCell

@property (nonatomic, weak) IBOutlet UIView *lineView;
@property (nonatomic, strong) NSOrderedSet *items;
@property (nonatomic, weak) UIViewController *parent;

- (IBAction)imgTapped:(id)sender;

@end
