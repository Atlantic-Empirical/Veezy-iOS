//
//  ORHomeCell_FindAndInvite.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 3/24/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORCell_ImportContactsFacebook : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (weak, nonatomic) IBOutlet UILabel *lblConnectedAs;
@property (weak, nonatomic) IBOutlet UIImageView *imgSourceLogo;
@property (weak, nonatomic) IBOutlet UILabel *lblCount;

- (void)updateTitles;

@end
