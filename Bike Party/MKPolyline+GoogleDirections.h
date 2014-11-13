//
//  MKPolyline+GoogleDirections.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKPolyline (GoogleDirections)

+ (MKPolyline *)polylineWithEncodedString:(NSString *)encodedStr;

@end
