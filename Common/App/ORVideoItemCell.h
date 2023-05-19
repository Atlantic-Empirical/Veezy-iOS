//
//  ORVideoItemCell.h
//  Epic
//
//  Created by Thomas Purnell-Fisher on 10/29/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORVideoItemCell : UITableViewCell


@property (nonatomic, strong) OREpicVideo *video;
@property (nonatomic, weak) UIViewController *parent;


@end
