//
//  ORTextReaderView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/26/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTextReaderView : UIViewController

- (id)initWithText:(NSString *)text andTitle:(NSString*)title;

@property (weak, nonatomic) IBOutlet UITextView *txtMain;

@end
