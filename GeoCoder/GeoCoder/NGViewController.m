//
//  NGViewController.m
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import "NGViewController.h"
#import "NGGeoCoder.h"
#import "NGGeoPlaceMark.h"


/*!
 NGGeoCoderHandler Could Added to any project and for more detail find the sample code below.
 Here we are using some default name and Addesss, i.e, randomaly picked and does'nt belongs to any real entitiy.
 All address will request for Goe code, Once code is generated It Returns data with requested referance ID. 
 @param _anID could be any thing, In case its not required we could keep it as nil as well.
 */


/*! Address Keys*/
static NSString *kAddressKey              =  @"address";
static NSString *kCityKey                    = @"City";
static NSString *kCountryKey              = @"Country";
static NSString *kStateKey                  = @"State";
static NSString *kStreetKey                 = @"Street";
static NSString *kZipKey                     = @"ZIP";
static NSString *kGeoCodeKey             = @"GeoCode";

@interface NGViewController ()
//Temp Methods for sample
// Intialize Requets For Geo Coder
- (void) initializeRequestForLocationGeoCode ;
// Updating fetched location for parent ID.
- (void) updateGeoCodeForID:(NSString *)_anID and:(NGGeoPlaceMark *)_placemark ;

@end

@implementation NGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeRequestForLocationGeoCode];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GeoCode Data Handler Method
- (NSString *)addressFromGeocodeLocation:(CLLocationCoordinate2D)location andID:(NSString *)_anID {
    __block NSString *_result = nil;
    [NGGeoCoder reverseGeocode:location ID:_anID
                     completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
                         NSLog(@"placemarks = %@", placemarks);
                         _result = [placemarks objectAtIndex:0];
                     }];
    return _result;
}

- (void)geocodeFromAddressString:(NSString *)_address andID:(NSString *)_anID {
    _requestedCount ++;
    [NGGeoCoder geocode:_address ID:_anID
              completion:^(NSArray *placemarksArray, NSHTTPURLResponse *urlResponse, NSError *error) {
                  if ([placemarksArray count]) {
                      NGGeoPlaceMark *placemark = [placemarksArray objectAtIndex:0];
                      NSString *IdKey = [placemark anIDKey];
                      [self updateGeoCodeForID:IdKey and:placemark];
                  }
              }];
}

#pragma mark - Life Cycle Methods
- (void) initializeRequestForLocationGeoCode {
    /*! Initializing Local Data*/
    NSString * fullPath = [[NSBundle mainBundle] resourcePath];
    fullPath = [fullPath stringByAppendingPathComponent:@"DefaultData.plist"];
    NSLog(@"%@",[NSArray arrayWithContentsOfFile:fullPath]);
    _contactsMDict = [[NSMutableDictionary alloc] initWithContentsOfFile:fullPath];
    NSLog(@"Intial Address Info = %@ path = %@",_contactsMDict,fullPath);
    
    NSArray *allContactsKey = [_contactsMDict allKeys];
    for (NSString *aKey in allContactsKey) {
        NSDictionary *_contactInfo = [_contactsMDict objectForKey:aKey];
        NSDictionary *_contactAdderssInfo = [_contactInfo objectForKey:kAddressKey];
        NSArray *addressAllKey = [_contactAdderssInfo allKeys];
        for (NSString *addressTypeKey in addressAllKey) {
            NSDictionary *singleAddress = [_contactAdderssInfo objectForKey:addressTypeKey];
            if (![singleAddress objectForKey:kGeoCodeKey]) {
                NSString *aAddressString = [NSString stringWithString:[NSString stringWithFormat:@"%@,%@,%@-%@,%@",[singleAddress objectForKey:kStreetKey],[singleAddress objectForKey:kCityKey],[singleAddress objectForKey:kStateKey],[singleAddress objectForKey:kZipKey],[singleAddress objectForKey:kCountryKey]]];
                NSString *_anIDValue = [NSString stringWithFormat:@"%@_%@",aKey,addressTypeKey];
                [self geocodeFromAddressString:aAddressString andID:_anIDValue];
            }
        }
    }
}

- (void) updateGeoCodeForID:(NSString *)_anID and:(NGGeoPlaceMark *)_placemark {
    _requestedCount --;
    NSArray*keyArr = [_anID componentsSeparatedByString:@"_"];
    if ([keyArr count] == 2 && _placemark) {
        NSString *aKey = [keyArr objectAtIndex:0];
        NSString *addressTypeKey = [keyArr lastObject];
        NSMutableDictionary *_contactInfo = [NSMutableDictionary dictionaryWithDictionary:[_contactsMDict objectForKey:aKey]];
        NSMutableDictionary *_contactAdderssInfo = [NSMutableDictionary dictionaryWithDictionary:[_contactInfo objectForKey:kAddressKey]];
        NSMutableDictionary *singleAddress = [NSMutableDictionary dictionaryWithDictionary:[_contactAdderssInfo objectForKey:addressTypeKey]];
        
        CLLocationCoordinate2D coordinate = [_placemark coordinate];
        CGPoint _point = CGPointMake(coordinate.latitude,coordinate.longitude);
        
        NSString *str= NSStringFromCGPoint(_point);
        
        [singleAddress setValue:str forKey:kGeoCodeKey];
        [_contactAdderssInfo setValue:singleAddress forKey:addressTypeKey];
        [_contactInfo setValue:_contactAdderssInfo forKey:kAddressKey];
        [_contactsMDict setValue:_contactInfo forKey:aKey];
    }
    if (_requestedCount <= 0) {
        NSLog(@"Final Update Address Info For Geo Code:\n%@",_contactsMDict);
    }
    
}


@end
