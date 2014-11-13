//
//  GoogleDirectionsStep.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "GoogleDirectionsStep.h"
#import "CLLocation+GoogleDirections.h"
#import "MKPolyline+GoogleDirections.h"

@implementation GoogleDirectionsStep

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super self];
    if (self) {
        NSDictionary *distanceDictionary = dictionary[@"distance"];
        _distanceText = distanceDictionary[@"text"];
        _distanceValue = [distanceDictionary[@"value"] floatValue];
        
        NSDictionary *durationDictionary = dictionary[@"duration"];
        _durationText = durationDictionary[@"text"];
        _durationValue = [durationDictionary[@"value"] floatValue];
        
        _startLocation = [[CLLocation alloc] initWithDictionary:dictionary[@"start_location"]];
        _endLocation = [[CLLocation alloc] initWithDictionary:dictionary[@"end_location"]];
        _polyline = [MKPolyline polylineWithEncodedString:dictionary[@"polyline"][@"points"]];
        _htmlInstructions = dictionary[@"html_instructions"];
        _maneuver = dictionary[@"maneuver"];
        _travelMode = dictionary[@"travel_mode"];
    }
    return self;
}

@end
