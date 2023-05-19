//
//  ORAvatarView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/1/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORAvatarView : GAITrackedViewController

- (id)initWithImage:(UIImage *)img andTitle:(NSString*)title;

@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;

@end
