//
//  TurnAnnotation.m
//  Bike Party
//
//  Created by Jon on 11/24/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "TurnAnnotation.h"

@implementation TurnAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate leg:(NSInteger)leg {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _leg = leg;
    }
    return self;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate leg:(NSInteger)leg title:(NSString *)title {
    self = [self initWithCoordinate:coordinate leg:leg];
    if (self) {
        _title = title;
    }
    return self;
}

@end
