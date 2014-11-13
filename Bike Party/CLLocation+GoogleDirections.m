//
//  CLLocation+GoogleDirections.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "CLLocation+GoogleDirections.h"

@implementation CLLocation (GoogleDirections)

- (id)initWithDictionary:(NSDictionary *)dictionary {
    
    float lattitude = [dictionary[@"lat"] floatValue];
    float longitude = [dictionary[@"lng"] floatValue];
    
    return [self initWithLatitude:lattitude longitude:longitude];
}

@end
