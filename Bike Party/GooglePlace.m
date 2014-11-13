//
//  NSObject+GooglePlace.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "GooglePlace.h"

@implementation GooglePlace : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSDictionary *geometryDictionary = dictionary[@"geometry"];
        NSDictionary *locationDictionary = geometryDictionary[@"location"];
        float lattitude = [locationDictionary[@"lat"] floatValue];
        float longitude = [locationDictionary[@"lng"] floatValue];
        _location = [[CLLocation alloc] initWithLatitude:lattitude longitude:longitude];
        
        _name = dictionary[@"name"];
        _openingHours = dictionary[@"opening_hours"];
        _photos = dictionary[@"photos"];
        _placeId = dictionary[@"place_id"];
        _reference = dictionary[@"reference"];
        _scope = dictionary[@"scope"];
        _types = dictionary[@"types"];
        _address = dictionary[@"vicinity"];
        _rating = [dictionary[@"rating"] floatValue];
    }
    return self;
}

@end
