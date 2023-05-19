//
//  ORNavigationController.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 03/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORNavigationController.h"

@implementation ORNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self.navigationBar setTranslucent:NO];
	[self.navigationBar setOpaque:YES];
}

-(BOOL)shouldAutorotate
{
    return self.topViewController.shouldAutorotate;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return self.topViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}

/* Disabled because it's not needed anymore, but the code might be useful in the future
 
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    if (self.viewControllers.count > 1) {
		[RVC hideBottomNav];
        
		UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(showCamera)];
		viewController.navigationItem.rightBarButtonItem = camera;
	}
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *vc = [super popViewControllerAnimated:animated];
    if (self.viewControllers.count == 1) {
		[RVC showBottomNav];
		
        vc.navigationItem.rightBarButtonItem = nil;
	}
    
    return vc;
}

- (void)showCamera
{
	[self popViewControllerAnimated:YES];
    [RVC showCamera];
}
 
*/

@end
