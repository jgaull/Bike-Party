//
//  GoogleDirectionsLeg.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "GoogleDirectionsLeg.h"
#import "GoogleDirectionsStep.h"
#import "CLLocation+GoogleDirections.h"

@implementation GoogleDirectionsLeg

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        
        _startAddress = dictionary[@"start_address"];
        _endAddress = dictionary[@"end_address"];
        _distanceText = dictionary[@"distance"][@"text"];
        _distanceValue = [dictionary[@"distance"][@"value"] floatValue];
        _durationText = dictionary[@"duration"][@"text"];
        _durationValue = [dictionary[@"duration"][@"value"] floatValue];
        _startLocation = [[CLLocation alloc] initWithDictionary:dictionary[@"start_location"]];
        _endLocation = [[CLLocation alloc] initWithDictionary:dictionary[@"end_location"]];
        
        
        _steps = dictionary[@"steps"];
        
        NSArray *stepDectionaries = dictionary[@"steps"];
        NSMutableArray *steps = [NSMutableArray new];
        for (NSDictionary *stepDictionary in stepDectionaries) {
            GoogleDirectionsStep *step = [[GoogleDirectionsStep alloc] initWithDictionary:stepDictionary];
            [steps addObject:step];
        }
        _steps = [[NSArray alloc] initWithArray:steps];
    }
    return self;
}

@end
