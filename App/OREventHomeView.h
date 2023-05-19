//
//  OREventHomeView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/25/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OREventHomeView : UIViewController

- (id)initWithEvent:(OREpicEvent*)event;

@property (weak, nonatomic) IBOutlet UILabel *lblEventName;

@end
