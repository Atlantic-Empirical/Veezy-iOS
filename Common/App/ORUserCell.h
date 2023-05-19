//
//  ORUserCell.h
//  Epic
//
//  Created by Rodrigo Sieiro on 01/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "MBContactModel.h"

@class ORFacebookPage;

@interface ORUserCell : UITableViewCell

@property (nonatomic, strong) OREpicFriend *user;
@property (nonatomic, strong) id<MBContactPickerModelProtocol> contact;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) ORFacebookPage *page;

@end
