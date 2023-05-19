//
//  ORPeopleLists.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/30/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPeopleLists : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *tblAllContacts;
@property (weak, nonatomic) IBOutlet UITableView *tblGroups;

@property (nonatomic, assign) BOOL connectTwitter;

@end
