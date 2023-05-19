//
//  ORPopDownView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 08/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPopDownView : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblSubtitle;
@property (nonatomic, weak) IBOutlet UIButton *btnClose;
@property (nonatomic, weak) IBOutlet UIButton *btnUndo;

@property (nonatomic, copy) void (^undoBlock)();
@property (nonatomic, copy) void (^completionBlock)();

- (id)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (void)displayInView:(UIView *)view hideAfter:(NSTimeInterval)seconds;
- (void)displayInView:(UIView *)view margin:(CGFloat)margin hideAfter:(NSTimeInterval)seconds;
- (IBAction)btnClose_TouchUpInside:(id)sender;
- (IBAction)btnUndo_TouchUpInside:(id)sender;

@end
