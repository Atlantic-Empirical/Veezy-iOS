//
//  ORHomeView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 28/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORHashtagView : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (id)initWithHashtag:(NSString *)hashtag;

@end
