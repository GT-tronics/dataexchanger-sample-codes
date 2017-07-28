//
//  DxAppAppDelegate.m
//  DataExchangerApp
//
//  Created by Ming Leung on 12-12-25.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 427 $
//

#import "DxAppAppDelegate.h"
#import <Corelocation/Corelocation.h>

@interface GtBeacon : NSObject

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSUUID *uuid;
@property (assign, nonatomic, readonly) CLBeaconMajorValue majorValue;
@property (assign, nonatomic, readonly) CLBeaconMinorValue minorValue;

@property (strong, nonatomic) CLBeacon *lastSeenBeacon;

- (instancetype) initWithName:(NSString *)name
                         uuid:(NSUUID *)uuid
                        major:(CLBeaconMajorValue)major
                        minor:(CLBeaconMinorValue)minor;

- (BOOL)isEqualToCLBeacon:(CLBeacon*)beacon;

@end

@implementation GtBeacon

@synthesize name;
@synthesize uuid;
@synthesize majorValue;
@synthesize minorValue;

- (instancetype) initWithName:(NSString *)n
                         uuid:(NSUUID *)u
                        major:(CLBeaconMajorValue)ma
                        minor:(CLBeaconMinorValue)mi
{
    self = [super init];
    if( self == nil )
    {
        return nil;
    }
    
    name = n;
    uuid = u;
    majorValue = ma;
    minorValue = mi;
    
    return self;
}

- (BOOL)isEqualToCLBeacon:(CLBeacon *)beacon
{
    if ([[beacon.proximityUUID UUIDString] isEqualToString:[self.uuid UUIDString]] &&
        [beacon.major isEqual: @(self.majorValue)] &&
        [beacon.minor isEqual: @(self.minorValue)])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end

@interface DxAppAppDelegate () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) GtBeacon*         gtBeacon;

@end

@implementation DxAppAppDelegate

@synthesize gtBeacon;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
#if 0
    UILocalNotification *locationNotification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
    if (locationNotification)
    {
        // Set icon badge number to zero
        application.applicationIconBadgeNumber = 0;

        NSLog(@"[INFO] local noti: %@", locationNotification.alertBody);

        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        
        return YES;
    }
#endif
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if( [defaults objectForKey:@"enableCmdCh"] == nil )
    {
        [defaults setBool:@YES forKey:@"enableCmdCh"];
        [defaults setBool:@YES forKey:@"dataChTerminator"];
        [defaults setInteger:-50 forKey:@"proxPwrLvl"];
        //[defaults setObject:@"https://192.168.0.1:8080/DataExchangerATMerged_TIEM_V2_OAD.bin" forKey:@"firmImageAddr"];
        [defaults synchronize];
    }
    
#if 0 // set 1 to enable iBeacon test code
    // Enable iBeacon monitoring
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    [self.locationManager requestAlwaysAuthorization];
    
    NSUUID* uuid = [[NSUUID alloc] initWithUUIDString:@"8889A8CA-0F7E-4565-8D19-74C20C4F9400"];
    gtBeacon = [[GtBeacon alloc] initWithName:@"GT-Beacon"
                                         uuid:uuid
                                        major:1
                                        minor:1];
    [self stopMonitoringItem:gtBeacon];
    [self startMonitoringItem:gtBeacon];
    
    UIMutableUserNotificationAction *openAppAction = [[UIMutableUserNotificationAction alloc] init];
    openAppAction.identifier = @"ACT_ID_OPEN_APP"; // The id passed when the user selects the action
    openAppAction.title = NSLocalizedString(@"Open App",nil); // The title displayed for the action
    openAppAction.activationMode = UIUserNotificationActivationModeForeground; // Choose whether the application is launched in foreground when the action is clicked
    openAppAction.destructive = NO; // If YES, then the action is red
    openAppAction.authenticationRequired = NO; // Whether the user must authenticate to execute the action
    
    UIMutableUserNotificationAction *regJobAction = [[UIMutableUserNotificationAction alloc] init];
    regJobAction.identifier = @"ACT_ID_REG_JOB"; // The id passed when the user selects the action
    regJobAction.title = NSLocalizedString(@"Register Job",nil); // The title displayed for the action
    regJobAction.activationMode = UIUserNotificationActivationModeBackground; // Choose whether the application is launched in foreground when the action is clicked
    regJobAction.destructive = NO; // If YES, then the action is red
    regJobAction.authenticationRequired = NO; // Whether the user must authenticate to execute the action
    
    UIMutableUserNotificationCategory *actionCategory = [[UIMutableUserNotificationCategory alloc] init];
    actionCategory.identifier = @"CTG_PROXI_NOTI"; // Identifier passed in the payload
    [actionCategory setActions:@[openAppAction, regJobAction] forContext:UIUserNotificationActionContextDefault]; // The context determines the number of actions presented (see documentation)

    // Enable local notification
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:[NSSet setWithObject:actionCategory]]];
#endif
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"[INFO] local noti: %@", notification.alertBody);
}

- (void) application:(UIApplication*)app handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(nonnull UILocalNotification *)notification completionHandler:(nonnull void (^)())completionHandler
{
    
}

- (void) application:(UIApplication*)app handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nonnull UILocalNotification *)notification completionHandler:(nonnull void (^)())completionHandler
{
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
#if 0
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Exit";
        notification.soundName = @"Default";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
#endif
        NSLog(@"[INFO] Beacon exit");
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"Shredder is here!";
        notification.soundName = @"Default";
        notification.category = @"CTG_PROXI_NOTI";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        NSLog(@"[INFO] Beacon enter");
    }
}

- (CLBeaconRegion *)beaconRegionWithItem:(GtBeacon*)item
{
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:item.uuid
                                                                           major:item.majorValue
                                                                           minor:item.minorValue
                                                                      identifier:item.name];
    beaconRegion.notifyEntryStateOnDisplay = YES;
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyOnExit = YES;
    
    return beaconRegion;
}

- (void)startMonitoringItem:(GtBeacon*)item
{
    CLBeaconRegion *beaconRegion = [self beaconRegionWithItem:item];
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

- (void)stopMonitoringItem:(GtBeacon*)item
{
    CLBeaconRegion *beaconRegion = [self beaconRegionWithItem:item];
    [self.locationManager stopMonitoringForRegion:beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"[WARN] Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"[WARN] Location manager failed: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    for (CLBeacon* beacon in beacons)
    {
        if( [gtBeacon isEqualToCLBeacon:beacon] )
        {
            gtBeacon.lastSeenBeacon = beacon;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if(state == CLRegionStateInside) {
        NSLog(@"locationManager didDetermineState INSIDE for %@", region.identifier);
        //[self locationManager:manager didEnterRegion:region];
    }
    else if(state == CLRegionStateOutside) {
        NSLog(@"locationManager didDetermineState OUTSIDE for %@", region.identifier);
        //[self locationManager:manager didExitRegion:region];
    }
    else {
        NSLog(@"locationManager didDetermineState OTHER for %@", region.identifier);
    }
}


@end
