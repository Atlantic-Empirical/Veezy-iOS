//
//  ORMapView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 11/20/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OREpicEvent;

@interface ORMapView : GAITrackedViewController

- (id)initForDiscovery;
- (id)initWithEvent:(OREpicEvent*)event;
- (id)initWithVideos:(NSArray *)videos;
- (id)initWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

@property (weak, nonatomic) IBOutlet UIView *viewMapParent;
@property (weak, nonatomic) IBOutlet UIButton *btnMap;
@property (weak, nonatomic) IBOutlet UIButton *btnSat;
@property (weak, nonatomic) IBOutlet UIButton *btnTerrain;
@property (weak, nonatomic) IBOutlet UILabel *lblNoDiscoveryVidsFound;
@property (weak, nonatomic) IBOutlet UIView *viewSearch;
@property (weak, nonatomic) IBOutlet UIButton *btnOpenRangeSelector;
@property (weak, nonatomic) IBOutlet UIView *viewRangeParent;
@property (weak, nonatomic) IBOutlet UIControl *view_TimeRangeTouchCatcher;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiTimeRange;
@property (weak, nonatomic) IBOutlet UIButton *btnMyLocation;
@property (weak, nonatomic) IBOutlet UIView *viewMapLabelHost;
@property (weak, nonatomic) IBOutlet UILabel *lblMapLabel;

- (IBAction)btnMap_TouchUpInside:(id)sender;
- (IBAction)btnSat_TouchUpInside:(id)sender;
- (IBAction)btnTerrain_TouchUpInside:(id)sender;
- (IBAction)btnOpenRangeSelector_TouchUpInside:(id)sender;
- (IBAction)view_TimeRangeTouchCatcher_TouchUpInside:(id)sender;
- (IBAction)btnMyLocation_TouchUpInside:(id)sender;

- (void)flyToCLLocation:(CLLocationCoordinate2D)location andName:(NSString*)name;

@end
