//
//  DestinationPin.m
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "DestinationPin.h"

@implementation DestinationPin

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSLog(@"Touches Moved");
    UITouch *touch = touches.anyObject;
    
    if ([self.delegate respondsToSelector:@selector(destinationPin:didDragWithTouch:)]) {
        [self.delegate destinationPin:self didDragWithTouch:touch];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches Began");
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches Ended");
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches Cancelled");
}

@end
