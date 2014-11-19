//
//  DestinationPin.h
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <MapKit/MapKit.h>

@class DestinationPin;
@protocol DestinationPinDelegate <NSObject>

- (void)destinationPin:(DestinationPin *)pin didDragWithTouch:(UITouch *)touch;

@end

@interface DestinationPin : MKPinAnnotationView

@property (weak, nonatomic) NSObject <DestinationPinDelegate> *delegate;

@end
