//
//  GooglePlacesSearch.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GooglePlacesSearch : NSObject

- (id)initWithAPIKey:(NSString *)apiKey;
- (void)findplaceByName:(NSString *)name nearLocation:(CLLocation *)location withinRadius:(CLLocationDistance)radius WithCallback:(void (^)(NSArray *places, NSError *error))callback;

@end
