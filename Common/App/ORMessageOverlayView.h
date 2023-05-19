//
//  ORAfterFirstCaptureView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 20/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORMessageOverlayView : UIViewController

- (id)initWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle;

@property (nonatomic, weak) IBOutlet UIButton *btnContinue;
@property (weak, nonatomic) IBOutlet UIView *viewMessageHost;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIView *viewCenteringHost;
@property (nonatomic, copy) BOOL (^enableButtonBlock)();

- (IBAction)btnContinue_TouchUpInside:(id)sender;

- (void)presentInViewController:(UIViewController *)vc completion:(void (^)(void))completion;

@end
