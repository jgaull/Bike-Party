//
//  CLLocation+GoogleDirections.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (GoogleDirections)

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
