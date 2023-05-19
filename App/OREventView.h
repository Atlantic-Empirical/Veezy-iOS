//
//  ORFifaWc2014.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OREventView : UIViewController

- (id)initWithEvent:(OREpicEvent*)event;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollerMain;
@property (weak, nonatomic) IBOutlet UIImageView *imgBrandingBanner;
@property (weak, nonatomic) IBOutlet UIView *viewActiveAreaIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnHome;
@property (weak, nonatomic) IBOutlet UIButton *btnMap;
@property (weak, nonatomic) IBOutlet UIButton *btnVenues;
@property (weak, nonatomic) IBOutlet UIButton *btnList;
@property (weak, nonatomic) IBOutlet UILabel *lblEventName;

- (IBAction)btnHome_TouchUpInside:(id)sender;
- (IBAction)btnMap_TouchUpInside:(id)sender;
- (IBAction)btnVenues_TouchUpInside:(id)sender;
- (IBAction)btnList_TouchUpInside:(id)sender;

@end
