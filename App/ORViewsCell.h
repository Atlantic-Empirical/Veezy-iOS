//
//  ORViewsCell.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 6/30/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TTTAttributedLabel;

@interface ORViewsCell : UITableViewCell

@property (nonatomic, weak) IBOutlet TTTAttributedLabel *lblNames;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;

@property (nonatomic, weak) UIViewController *parent;
@property (nonatomic, strong) OREpicVideo *video;

@end
