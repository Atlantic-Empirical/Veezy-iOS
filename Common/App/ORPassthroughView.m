//
//  ORPassthroughView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 21/02/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORPassthroughView.h"

@implementation ORPassthroughView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.alpha != 0.0f && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event]) {
            return YES;
        }
    }
    
    return NO;
}

@end
