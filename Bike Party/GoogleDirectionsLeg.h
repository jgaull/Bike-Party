//
//  GoogleDirectionsLeg.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface GoogleDirectionsLeg : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *startAddress;
@property (nonatomic, readonly) NSString *endAddress;
@property (nonatomic, readonly) NSString *distanceText;
@property (nonatomic, readonly) float distanceValue;
@property (nonatomic, readonly) NSString *durationText;
@property (nonatomic, readonly) float durationValue;
@property (nonatomic, readonly) CLLocation *startLocation;
@property (nonatomic, readonly) CLLocation *endLocation;
@property (nonatomic, readonly) NSArray *steps;

@end
