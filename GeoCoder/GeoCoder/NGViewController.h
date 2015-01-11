//
//  NGViewController.h
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface NGViewController : UIViewController {
    // Contact Information
    NSMutableDictionary *_contactsMDict;
    
    // Requested Geocode Counter
    int _requestedCount;
}

// Getting Revese => Address to GeoCode .
//@param _anID is Set for referncing respective Contact Adddress. Might be single contact have multiple type Address (Home, Office, Other).
//@param _anID could be nill as well,majorly based on requirements.
- (NSString *)addressFromGeocodeLocation:(CLLocationCoordinate2D)location andID:(NSString *)_anID ;
// Getting GeoCode from Address.
//@param _anID is Set for referncing respective Contact Adddress. Might be single contact have multiple type Address (Home, Office, Other).
//@param _anID could be nill as well,majorly based on requirements.
- (void)geocodeFromAddressString:(NSString *)_address andID:(NSString *)_anID ;

@end
