//
//  BLEController.h
//  blelib
//
//  Created by Ming Leung on 12-07-16.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 50 $
//
// BLEController class (together with BLEDevice and BLEProfile classes)
// abstracts the CoreBluetooth framework to provide a class-based
// framework for peripheral device and profile modelling. User only
// requires to model the content (data) and its behavior (method) of
// BLE device and profile, then the framework will take care the rest.
//

#ifndef __BLECONTROLLER_H__
#define __BLECONTROLLER_H__

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import "BLEDevice.h"

enum BLEMatchDevicePolicy
{
    SCORE_0_MATCH_FIRST_IDLE = 0,
    SCORE_0_MATCH_NONE,
};

enum BLEScanDevicePolicy
{
    SCAN_NOT_ALLOW_DUPLICATED_KEY = 0,
    SCAN_NORMAL = 0,
    SCAN_ALLOW_DUPLICATED_KEY = 0x1,
    SCAN_WILD_CARD_SRV_UUID = 0x2
};

@interface BLEController :  NSObject  <CBCentralManagerDelegate>

@property (nonatomic, assign)   enum BLEMatchDevicePolicy   matchDevicePolicy;
@property (nonatomic, assign)   enum BLEScanDevicePolicy    scanDevicePolicy;

// Init (Singleton)
+ (BLEController*) controller;

+ (BOOL) isPrivateCentralQueueEnabled;
+ (BOOL) isRestored;
+ (void) enablePrivateCentralQueue;

// Init without restoration
- (BLEController*) init;

// Init With Restoration
- (BLEController*) initWithRestoreIdentifier:(NSString*)idStr;

// return bluetooth state
- (BOOL) isBluetoothOn;

// return bluetooth status
- (BOOL) isBluetoothSupported;

// Start scanning peripheral devices
- (void) startScan;

// Stop scanning peripheral devices
- (void) stopScan;

// Enable scanning operation (default is enabled)
- (void) enableScanning;

// Disable scanning operation. This will also stop scanning if scanning
// is on. 
- (void) disableScanning;

// Check scanning state
- (BOOL) isScanning;

// Register BLE device with controller. This method allows BLE controller
// to scan for the GATT services which are associated with the BLE device.
- (void) registerDevice:(BLEDevice*)device;

- (BOOL) connectDevice:(NSUUID*)uuid;

- (BOOL) disconnectDevice:(NSUUID*)uuid;

@end

#endif