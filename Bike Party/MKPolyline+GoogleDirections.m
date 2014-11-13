//
//  MKPolyline+GoogleDirections.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "MKPolyline+GoogleDirections.h"

@implementation MKPolyline (GoogleDirections)

+ (MKPolyline *)polylineWithEncodedString:(NSString *)encodedStr {
    NSMutableString *encoded = [[NSMutableString alloc] initWithCapacity:[encodedStr length]];
    
    [encoded appendString:encodedStr];
    
    [encoded replaceOccurrencesOfString:@"\\\\"
                             withString:@"\\"
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, [encoded length])];
    
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat = 0;
    NSInteger lng = 0;
    while (index < len) {
        
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        //printf("[%f,", [latitude doubleValue]);
        //printf("%f]", [longitude doubleValue]);
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:loc];
    }
    
    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * len);
    
    NSInteger i = 0;
    for (CLLocation *location in array) {
        coords[i] = location.coordinate;
        i++;
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:array.count];
    free(coords);
    
    return polyline;
}

@end
