//
//  ORUnlimitedParentView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORUnlimitedParentView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollerMain;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnRestore;

- (IBAction)btnRestore_TouchUpInside:(id)sender;

@end
