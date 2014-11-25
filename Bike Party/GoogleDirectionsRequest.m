//
//  GoogleDirectionsRequest.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "GoogleDirectionsRequest.h"

@interface GoogleDirectionsRequest ()

@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSURLSession *urlSession;

@end

@implementation GoogleDirectionsRequest

- (id)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        self.apiKey = apiKey;
    }
    return self;
}

- (void)loadDirectionsForPath:(NSArray *)path WithCallback:(void (^)(NSArray *routes, NSError *error))callback {
    if (self.apiKey && path.count > 1 && path.count <= 8) {
        
        NSString *baseUrl = @"https://maps.googleapis.com/maps/api/directions/json?key=%@&origin=%f,%f&destination=%f,%f&mode=bicycling";
        
        if (path.count > 2) {
            NSString *waypointsString = @"&waypoints=";
            for (int i = 1; i < path.count - 1; i++) {
                CLLocation *waypoint = [path objectAtIndex:i];
                CLLocationCoordinate2D coordinate = waypoint.coordinate;
                NSString *waypointString = [NSString stringWithFormat:@"%f,%f|", coordinate.latitude, coordinate.longitude];
                waypointsString = [waypointsString stringByAppendingString:waypointString];
            }
            
            waypointsString = [waypointsString substringToIndex:waypointsString.length - 1];
            baseUrl = [baseUrl stringByAppendingString:waypointsString];
            //NSLog(@"%@", baseUrl);
        }
        
        CLLocation *origin = path.firstObject;
        CLLocation *destination = path.lastObject;
        
        CLLocationCoordinate2D originCoordinate = origin.coordinate;
        CLLocationCoordinate2D destinationCoordinate = destination.coordinate;
        NSString *urlString = [NSString stringWithFormat:baseUrl,
                               self.apiKey,
                               originCoordinate.latitude,
                               originCoordinate.longitude,
                               destinationCoordinate.latitude,
                               destinationCoordinate.longitude];
        
        [self loadDirectionsWithUrlString:urlString withCallback:callback];
    }
    else {
        NSLog(@"something isn't set");
        NSLog(@"path.count: %lu", (unsigned long)path.count);
        callback(nil, [NSError errorWithDomain:@"error" code:1 userInfo:nil]);
    }
}

- (void)loadDirectionsFromPlace:(CLLocation *)origin toPlace:(CLLocation *)destination WithCallback:(void (^)(NSArray *places, NSError *error))callback {
    
    if (self.apiKey) {
        
        NSString *urlFormat = @"https://maps.googleapis.com/maps/api/directions/json?key=%@&origin=%f,%f&destination=%f,%f&mode=bicycling";
        
        CLLocationCoordinate2D originCoordinate = origin.coordinate;
        CLLocationCoordinate2D destinationCoordinate = destination.coordinate;
        NSString *urlString = [NSString stringWithFormat:urlFormat,
                               self.apiKey,
                               originCoordinate.latitude,
                               originCoordinate.longitude,
                               destinationCoordinate.latitude,
                               destinationCoordinate.longitude];
        
        NSMutableURLRequest *urlRequest = [self urlRequestForHTTPMethod:@"GET" withURLString:urlString];
        
        NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSError *error;
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                
                if ([responseDictionary[@"status"] isEqualToString:@"OK"]) {
                    //NSLog(@"Success: %@", responseDictionary);
                    
                    NSArray *results = responseDictionary[@"routes"];
                    NSMutableArray *routes = [NSMutableArray new];
                    
                    for (NSDictionary *routeDictionary in results) {
                        GoogleDirectionsRoute *route = [[GoogleDirectionsRoute alloc] initWithDictionary:routeDictionary];
                        [routes addObject:route];
                    }
                    
                    callback(routes, nil);
                }
                else {
                    //NSLog(@"Error JSON decoding: %@", error.localizedDescription);
                    callback(nil, error);
                }
            }
            else {
                //NSLog(@"Error loading request: %@", error.localizedDescription);
                callback(nil, error);
            }
        }];
        
        [dataTask resume];
    }
    else {
        NSLog(@"Not enough params...");
    }
}

- (void)loadDirectionsWithUrlString:(NSString *)urlString withCallback:(void (^)(NSArray *places, NSError *error))callback {
    NSMutableURLRequest *urlRequest = [self urlRequestForHTTPMethod:@"GET" withURLString:urlString];
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSError *error;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            
            if ([responseDictionary[@"status"] isEqualToString:@"OK"]) {
                //NSLog(@"Success: %@", responseDictionary);
                
                NSArray *results = responseDictionary[@"routes"];
                NSMutableArray *routes = [NSMutableArray new];
                
                for (NSDictionary *routeDictionary in results) {
                    GoogleDirectionsRoute *route = [[GoogleDirectionsRoute alloc] initWithDictionary:routeDictionary];
                    [routes addObject:route];
                }
                
                callback(routes, nil);
            }
            else {
                //NSLog(@"Error JSON decoding: %@", error.localizedDescription);
                callback(nil, error);
            }
        }
        else {
            //NSLog(@"Error loading request: %@", error.localizedDescription);
            callback(nil, error);
        }
    }];
    
    [dataTask resume];
}

- (NSMutableURLRequest *)urlRequestForHTTPMethod:(NSString *)method withURLString:(NSString *)urlString {
    
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod:method];
    return urlRequest;
}

- (NSURLSession *)urlSession {
    if (!_urlSession) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    
    return _urlSession;
}

@end
