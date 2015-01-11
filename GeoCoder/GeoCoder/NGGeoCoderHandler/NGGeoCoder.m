//
//  NGGeoCoder.m
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import "NGGeoCoder.h"
#import <MapKit/MapKit.h>
#import "NGGeoPlaceMark.h"

@interface NGGeoCoder ()
- (NSString*)encodedURLParameterString:(NSString *)_string ;
- (NGGeoCoder*)initWithCoordinate:(CLLocationCoordinate2D)coordinate ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block ;
- (NGGeoCoder*)initWithAddress:(NSString*)address ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block ;
- (NGGeoCoder*)initWithAddress:(NSString *)address region:(CLCircularRegion *)region ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block ;
- (NGGeoCoder*)initWithParameters:(NSMutableDictionary*)parameters completion:(GeocoderCompletionHandler)block ;
- (void)addParametersToRequest:(NSMutableDictionary*)parameters ;
- (void)setTimeoutTimer:(NSTimer *)newTimer ;
- (void)start ;
- (void)finish ;
- (void)cancel ;
- (BOOL)isConcurrent ;
- (BOOL)isFinished ;
- (BOOL)isExecuting ;
- (GeocoderState)state ;
- (void)setState:(GeocoderState)newState ;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)callCompletionBlockWithResponse:(id)response error:(NSError *)error;
@end

@implementation NGGeoCoder

#pragma mark - Dealloc
- (void)dealloc {
    [operationConnection cancel];
}

#pragma mark - Convenience Initializers

+ (NGGeoCoder *)geocode:(NSString *)address ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block {
    NGGeoCoder *geocoder = [[self alloc] initWithAddress:address ID:_anID completion:block];
    [geocoder start];
    return geocoder;
}

+ (NGGeoCoder *)geocode:(NSString *)address region:(CLCircularRegion *)region ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block {
    NGGeoCoder *geocoder = [[self alloc] initWithAddress:address region:region ID:_anID completion:block];
    [geocoder start];
    return geocoder;
}

+ (NGGeoCoder *)reverseGeocode:(CLLocationCoordinate2D)coordinate ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block {
    NGGeoCoder *geocoder = [[self alloc] initWithCoordinate:coordinate ID:_anID completion:block];
    [geocoder start];
    return geocoder;
}

#pragma mark - Private Utility Methods
- (NSString*)encodedURLParameterString:(NSString *)_string {
    NSString *result = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                            (__bridge CFStringRef)_string,
                                                                                            NULL,
                                                                                            CFSTR(":/=,!$&'()*+;[]@#?|"),
                                                                                            kCFStringEncodingUTF8));
	return result;
}


- (NGGeoCoder*)initWithCoordinate:(CLLocationCoordinate2D)coordinate ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude], @"latlng", nil];
    parentID = [[NSString alloc] initWithString:_anID];
    return [self initWithParameters:parameters completion:block];
}


- (NGGeoCoder*)initWithAddress:(NSString*)address ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       address, @"address", nil];
    parentID = [[NSString alloc] initWithString:_anID];
    return [self initWithParameters:parameters completion:block];
}


- (NGGeoCoder*)initWithAddress:(NSString *)address region:(CLCircularRegion *)region ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block {
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(region.center, region.radius, region.radius);
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       address, @"address",
                                       [NSString stringWithFormat:@"%f,%f|%f,%f",
                                        coordinateRegion.center.latitude-(coordinateRegion.span.latitudeDelta/2.0),
                                        coordinateRegion.center.longitude-(coordinateRegion.span.longitudeDelta/2.0),
                                        coordinateRegion.center.latitude+(coordinateRegion.span.latitudeDelta/2.0),
                                        coordinateRegion.center.longitude+(coordinateRegion.span.longitudeDelta/2.0)], @"bounds", nil];
    parentID = [[NSString alloc] initWithString:_anID];
    return [self initWithParameters:parameters completion:block];
}

- (NGGeoCoder*)initWithParameters:(NSMutableDictionary*)parameters completion:(GeocoderCompletionHandler)block {
    self = [super init];
    operationCompletionBlock = block;
    operationRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://maps.googleapis.com/maps/api/geocode/json"]];
    [operationRequest setTimeoutInterval:kGeocoderTimeoutInterval];
    
    [parameters setValue:@"true" forKey:@"sensor"];
    [parameters setValue:[NSLocale preferredLanguages][0] forKey:@"language"];
    [self addParametersToRequest:parameters];
    
    self.state = GeocoderStateReady;
    
    return self;
}

- (void)addParametersToRequest:(NSMutableDictionary*)parameters {
    
    NSMutableArray *paramStringsArray = [NSMutableArray arrayWithCapacity:[[parameters allKeys] count]];
    
    for(NSString *key in [parameters allKeys]) {
        NSObject *paramValue = [parameters valueForKey:key];
		if ([paramValue isKindOfClass:[NSString class]]) {
			[paramStringsArray addObject:[NSString stringWithFormat:@"%@=%@", key, [self encodedURLParameterString:(NSString *)paramValue]]];
		} else {
			[paramStringsArray addObject:[NSString stringWithFormat:@"%@=%@", key, paramValue]];
		}
    }
    
    NSString *paramsString = [paramStringsArray componentsJoinedByString:@"&"];
    NSString *baseAddress = operationRequest.URL.absoluteString;
    baseAddress = [baseAddress stringByAppendingFormat:@"?%@", paramsString];
    [operationRequest setURL:[NSURL URLWithString:baseAddress]];
}

- (void)setTimeoutTimer:(NSTimer *)newTimer {
    
    if(timeoutTimer)
        [timeoutTimer invalidate], timeoutTimer = nil;
    
    if(newTimer)
        timeoutTimer = newTimer;
}

#pragma mark - NSOperation methods

- (void)start {
    
    if(self.isCancelled) {
        [self finish];
        return;
    }
    
    if(![NSThread isMainThread]) {
        // NSOperationQueue calls start from a bg thread (through GCD), but NSURLConnection already does that by itself
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    self.state = GeocoderStateExecuting;
    [self didChangeValueForKey:@"isExecuting"];
    
    operationData = [[NSMutableData alloc] init];
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kGeocoderTimeoutInterval target:self selector:@selector(requestTimeout) userInfo:nil repeats:NO];
    
    operationConnection = [[NSURLConnection alloc] initWithRequest:operationRequest delegate:self startImmediately:NO];
    [operationConnection start];
    
    NSLog(@"[%@] %@", operationRequest.HTTPMethod, operationRequest.URL.absoluteString);
}

- (void)finish {
    [operationConnection cancel];
    operationConnection = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    state = GeocoderStateFinished;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancel {
    if([self isFinished])
        return;
    
    [super cancel];
    [self callCompletionBlockWithResponse:nil error:nil];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.state == GeocoderStateFinished;
}

- (BOOL)isExecuting {
    return self.state == GeocoderStateExecuting;
}

- (GeocoderState)state {
    @synchronized(self) {
        return state;
    }
}

- (void)setState:(GeocoderState)newState {
    @synchronized(self) {
        [self willChangeValueForKey:@"state"];
        state = newState;
        [self didChangeValueForKey:@"state"];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self callCompletionBlockWithResponse:nil error:error];
}

- (void)callCompletionBlockWithResponse:(id)response error:(NSError *)error {
    self.timeoutTimer = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *serverError = error;
        
        if(!serverError && operationURLResponse.statusCode == 500) {
            serverError = [NSError errorWithDomain:NSURLErrorDomain
                                              code:NSURLErrorBadServerResponse
                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"Bad Server Response.", NSLocalizedDescriptionKey,
                                                    operationRequest.URL, NSURLErrorFailingURLErrorKey,
                                                    operationRequest.URL.absoluteString, NSURLErrorFailingURLStringErrorKey, nil]];
        }
        
        if(operationCompletionBlock && !self.isCancelled)
            operationCompletionBlock([response copy], operationURLResponse, serverError);
        
        [self finish];
    });
}


#pragma mark - NSURLConnectionDelegate

- (void)requestTimeout {
    NSURL *failingURL = operationRequest.URL;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"The operation timed out.", NSLocalizedDescriptionKey,
                              failingURL, NSURLErrorFailingURLErrorKey,
                              failingURL.absoluteString, NSURLErrorFailingURLStringErrorKey, nil];
    
    NSError *timeoutError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
    [self connection:nil didFailWithError:timeoutError];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    operationURLResponse = (NSHTTPURLResponse*)response;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[operationData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSMutableArray *placemarks = nil;
    NSError *error = nil;
    
    if ([[operationURLResponse MIMEType] isEqualToString:@"application/json"]) {
        if(operationData && operationData.length > 0) {
            id response = [NSData dataWithData:operationData];
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:&error];
            NSArray *results = [jsonObject objectForKey:@"results"];
            NSString *status = [jsonObject valueForKey:@"status"];
            
            if(results)
                placemarks = [NSMutableArray arrayWithCapacity:results.count];
            
            if(results.count > 0) {
                [results enumerateObjectsUsingBlock:^(NSDictionary *result, NSUInteger idx, BOOL *stop) {
                    NGGeoPlaceMark *placemark = [[NGGeoPlaceMark alloc] initWithDictionary:result];
                    [placemark setAnIDKey:parentID];
                    [placemarks addObject:placemark];
                }];
            }
            else {
                if ([status isEqualToString:@"ZERO_RESULTS"]) {
                    NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Zero results returned", NSLocalizedDescriptionKey, nil];
                    error = [NSError errorWithDomain:@"GeocoderErrorDomain" code:GeoCoderZeroResultsError userInfo:userinfo];
                    
                } else if ([status isEqualToString:@"OVER_QUERY_LIMIT"]) {
                    NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Currently rate limited. Too many queries in a short time. (Over Quota)", NSLocalizedDescriptionKey, nil];
                    error = [NSError errorWithDomain:@"GeocoderErrorDomain" code:GeoCoderOverQueryLimitError userInfo:userinfo];
                    
                } else if ([status isEqualToString:@"REQUEST_DENIED"]) {
                    NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Request was denied. Did you remember to add the \"sensor\" parameter?", NSLocalizedDescriptionKey, nil];
                    error = [NSError errorWithDomain:@"GeocoderErrorDomain" code:GeoCoderRequestDeniedError userInfo:userinfo];
                    
                } else if ([status isEqualToString:@"INVALID_REQUEST"]) {
                    NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:@"The request was invalid. Was the \"address\" or \"latlng\" missing?", NSLocalizedDescriptionKey, nil];
                    error = [NSError errorWithDomain:@"GeocoderErrorDomain" code:GeoCoderInvalidRequestError userInfo:userinfo];
                }
            }
        }
    }
    
    [self callCompletionBlockWithResponse:placemarks error:error];
}

@end
