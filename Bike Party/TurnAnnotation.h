//
//  TurnAnnotation.h
//  Bike Party
//
//  Created by Jon on 11/24/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface TurnAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (nonatomic, readonly) NSInteger leg;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate leg:(NSInteger)leg;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate leg:(NSInteger)leg title:(NSString *)title;

@end
