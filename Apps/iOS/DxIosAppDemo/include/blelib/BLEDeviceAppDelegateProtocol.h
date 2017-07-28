//
//  BLEDeviceAppDelegateProtocol.h
//  blelib
//
//  Created by Ming Leung on 12-07-23.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  This protocol is used the app delegate to receive status
//  change about the device.
//
//  $Rev: 31 $
//

#import <Foundation/Foundation.h>

@class BLEDevice;

@protocol BLEDeviceAppDelegateProtocol <NSObject>

@optional

//
// Called when the device is switched on or off.
//
- (void) Device:(BLEDevice*)device switchOn:(BOOL)flag;

//
// Called when the device has a new RSSI reading
//
- (void) Device:(BLEDevice*)device reportRssi:(NSNumber*)rssi;

//
// Called when the device has all profiles declared ready
//
- (void) Device:(BLEDevice*)device allProfilesReady:(BOOL)isReady;

//
// Called when the device has some exception
//
- (void) Device:(BLEDevice*)device reportException:(NSError*)err;

@end
