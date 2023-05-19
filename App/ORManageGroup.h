//
//  ORManageGroup.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORManageGroup : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITextField *txtName;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) OREpicGroup *group;

- (id)initWithGroup:(OREpicGroup *)group;

@end