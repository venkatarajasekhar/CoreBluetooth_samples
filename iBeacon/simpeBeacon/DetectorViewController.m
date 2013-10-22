//
//  DetectorViewController.m
//  simpeBeacon
//
//  Created by uehara akihiro on 2013/10/20.
//  Copyright (c) 2013年 REINFORCE Lab. All rights reserved.
//

#import "DetectorViewController.h"

@interface DetectorViewController ()  {
    CLLocationManager *_locationManager;
    CLBeaconRegion    *_region;
}

@property (weak, nonatomic) IBOutlet UIView *rangePanelView;
@property (weak, nonatomic) IBOutlet UILabel *rangeUUIDTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeMinorTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeMajorTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeProxTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeAccuracyTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeRssiTextLabel;
@property (weak, nonatomic) IBOutlet UISwitch *regionSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rangingSwitch;
@property (weak, nonatomic) IBOutlet UILabel *inRegionTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *inRegionStatusTextLabel;
@end

@implementation DetectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // CLBeaconRegionを作成
    _region = [[CLBeaconRegion alloc]
               initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:kBeaconUUID]
               identifier:kIdentifier];
    
    // iBeaconを受信するlocationManagerを組み立てます
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private methods
// ビーコンの受信をOn/Offします
-(void)startReceivingBeacon {
    // 距離計測を開始

    // Beaconによる領域観測を開始
    [_locationManager startMonitoringForRegion:_region];
}
-(void)stopReceivingBeacon {


}
-(void)updatePanelView:(NSArray *)beacons region:(CLBeaconRegion *)region {
    CLBeacon *beacon = [beacons firstObject];
    
    if(beacon == nil) {
        self.rangePanelView.alpha = 0.2;
        /*
        self.rangeUUIDTextLabel.text  = @"";
        self.rangeMajorTextLabel.text = @"";
        self.rangeMinorTextLabel.text = @"";
        self.rangeProxTextLabel.text  = @"";
         */
    } else {

        self.rangePanelView.alpha = 1.0;

        self.rangeUUIDTextLabel.text  = [NSString stringWithFormat:@"%@", beacon.proximityUUID.UUIDString];
        self.rangeMajorTextLabel.text = [NSString stringWithFormat:@"%@", beacon.major];
        self.rangeMinorTextLabel.text = [NSString stringWithFormat:@"%@", beacon.minor];
        self.rangeAccuracyTextLabel.text = [NSString stringWithFormat:@"%1.1e", beacon.accuracy];
        self.rangeRssiTextLabel.text =[NSString stringWithFormat:@"%d", beacon.rssi];
        
        NSString *proximity = @"";
        switch (beacon.proximity) {
            case CLProximityUnknown: proximity = @"CLProximityUnknown"; break;
            case CLProximityImmediate: proximity = @"CLProximityImmediate"; break;
            case CLProximityNear: proximity = @"CLProximityNear"; break;
            case CLProximityFar: proximity = @"CLProximityFar"; break;
            default:
                break;
        }
        self.rangeProxTextLabel.text =proximity;
    }
}
#pragma mark Event handlers
- (IBAction)rangingSwitchValueChanged:(id)sender {
    // iBeaconに対応しているかを調べます。
    // TBD BTの対応?スイッチ?
    if(![CLLocationManager isRangingAvailable]) {
        [self showAleart:@"iBeaconの受信機能がありません。"];
        self.rangingSwitch.on = NO;
        return;
    }
    
    if(self.rangingSwitch.on) {
        [_locationManager startRangingBeaconsInRegion:_region];
    } else {
        [_locationManager stopRangingBeaconsInRegion:_region];
    }
}
- (IBAction)regionSwitchValueChanged:(id)sender {
    // iBeaconのリージョンモニタリングに対応しているかを調べます。
    if(![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        [self showAleart:@"iBeaconのリージョンモニタリング機能がありません。"];
        self.regionSwitch.on = NO;
        return;
    }
    
    if(self.regionSwitch.on) {
        [_locationManager startMonitoringForRegion:_region];

        self.inRegionTextLabel.alpha = 1.0;
        self.inRegionStatusTextLabel.alpha = 1.0;
    } else {
        [_locationManager stopMonitoringForRegion:_region];
        
        self.inRegionTextLabel.alpha = 0.5;
        self.inRegionStatusTextLabel.alpha = 0.5;
    }
    
}
#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    id beacon = [beacons firstObject];
    [self writeLog:[NSString stringWithFormat:@"%s\nbeacon_addr:%ld\n%@\n%@", __func__, (long int)beacon, beacons, region]];
    [self updatePanelView:beacons region:region];
}
- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error {
    [self writeLog:[NSString stringWithFormat:@"%s\n%@\n%@", __func__, region, error]];
}
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    [self writeLog:[NSString stringWithFormat:@"%s\n%@", __func__, error]];
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self writeLog:[NSString stringWithFormat:@"%s\n%d", __func__, status]];
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        [self writeLog:@"ローケーションサービスを使う権限がありません。"];
        self.rangingSwitch.on = NO;
        return;
    }
}
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    [self writeLog:[NSString stringWithFormat:@"%s\n%@", __func__, region]];
    
    self.inRegionStatusTextLabel.text = @"YES";
}
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region {
    [self writeLog:[NSString stringWithFormat:@"%s\n%@", __func__, region]];
    
    self.inRegionStatusTextLabel.text = @"NO";
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    [self writeLog:[NSString stringWithFormat:@"%s", __func__]];
}
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    [self writeLog:[NSString stringWithFormat:@"%s", __func__]];
}
- (void)locationManager:(CLLocationManager *)manager
didFinishDeferredUpdatesWithError:(NSError *)error {
    [self writeLog:[NSString stringWithFormat:@"%s\n%@", __func__, error]];
}

@end
