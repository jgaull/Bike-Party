//
//  TouchyFeelyMapView.m
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "TouchyFeelyMapView.h"

@implementation TouchyFeelyMapView

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint pointInView = [touch locationInView:self];
    CLLocationCoordinate2D coordinate = [self convertPoint:pointInView toCoordinateFromView:self];
    
    if ([self.delegate conformsToProtocol:@protocol(TouchyFeelyMapViewDelegate)]) {
        NSObject <TouchyFeelyMapViewDelegate> *delegate = (NSObject <TouchyFeelyMapViewDelegate> *)self.delegate;
        
        if ([delegate respondsToSelector:@selector(mapView:didDragToCoordinate:)]) {
            [delegate mapView:self didDragToCoordinate:coordinate];
        }
    }
}

@end
