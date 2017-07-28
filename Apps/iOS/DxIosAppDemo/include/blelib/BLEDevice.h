//
//  BLEDevice.h
//  blelib
//
//  Created by Ming Leung on 12-07-16.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 51 $
//

#ifndef __BLEDEVICE_H__
#define __BLEDEVICE_H__

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import "BLEControllerDeviceProtocol.h"
#import "BLEDeviceAppDelegateProtocol.h"

// BLE device state
typedef enum
{
    BLE_DEVICE_IDLE = 0,
    BLE_DEVICE_CONNECTING,
    BLE_DEVICE_CONNECTED,
} BLE_DEVICE_STATE;

@class BLEProfile;

@interface BLEDevice : NSObject <BLEControllerDeviceProtocol, CBPeripheralDelegate>

// BLE device state (default is BLE_DEVICE_IDLE)
@property (nonatomic, readonly)     BLE_DEVICE_STATE            state;

// Auto connect upon discovered (default is YES)
@property (nonatomic, assign)       BOOL                        autoConnect;

// Device name
@property (nonatomic, strong)       NSString*                   devName;

// Device UUID
@property (nonatomic, strong)       CBUUID*                     devUUID;

// Use dynamic primary service UUID
@property (nonatomic, assign)       BOOL                        useDynPriSvc;

//
// Init methods
//
- (BLEDevice*) initWithAppDelegate:(id<BLEDeviceAppDelegateProtocol>)delegate;
+ (BLEDevice*) deviceWithAppDelegate:(id<BLEDeviceAppDelegateProtocol>)delegate;

//
// This method is called by BLE controller when a real device is discovered. The
// BLE controller may have several devices registered with the controller. The
// controller will call this method for each registered device to determine
// which device is best fitted for the discovered real device.
//
// The return value is the score used by the controller to determine
// which registered device to be used for the rest of the discovering process.
// The implementation of this method should use the data provided in the
// adversting dictionary to determine the score. If the discovered device is
// absolutely not matched, return -1. If discovered device is matched but should
// be choosen based on BLEController policy, return 0. If discovered device is
// matched should be choosen based on user defined policy, return any number
// between 1 to 100. In this case, the highest score will be picked.
//
// This method should be implemented by the subclass of BLEDevice.
//
- (NSInteger) evaluateDeviceMatchingScore:(NSDictionary*)adv;

//
// This method is called by BLE controller when a real device is discovered. The
// BLE controller may have several devices registered with the controller. The
// controller will call this method for each registered device to determine
// which device is best fitted for the discovered real device.
//
// The return value is the score used by the controller to determine
// which registered device to be used for the rest of the discovering process.
// The implementation of this method should use the data provided in the
// adversting dictionary, rssi, and discovered device name to determine
// the score. If the discovered device is absolutely not matched, return -1.
// If discovered device is matched but should be choosen based on BLEController
// policy, return 0. If discovered device is matched should be choosen based on
// user defined policy, return any number between 1 to 100. In this case,
// the highest score will be picked.
//
// This method should be implemented by the subclass of BLEDevice.
//
- (NSInteger) evaluateDeviceMatchingScoreBasedOnAdvertisingData:(NSDictionary*)adv rssi:(NSNumber*)rssi deviceName:(NSString*)name;

- (NSInteger) evaluateDeviceMatchingScoreBasedOnAdvertisingData:(NSDictionary*)adv rssi:(NSNumber*)rssi deviceUUID:(CBUUID*)uuid;

//
// This method will manually connect to the discovered device if autoConnect has not
// been set.
//
- (void) connect;

//
// This method will disconnect the connected device immediately
//
- (void) disconnect;

//
// This mehtod will shutdown the connected device immediately
//
- (void) shutdown;

//
// This method issue a write request to an attribute specified by Service UUID and
// Characteristic UUID.
//
- (BOOL) writeValue:(NSData*)data forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid;
- (BOOL) writeValue:(NSData*)data forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid withResponse:(BOOL)withResponse;

//
// This method issues a read request to an attribute specified by Service UUID and
// Characteristic UUID.
//
- (BOOL) readValueForCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid;

//
// This method issues a set notification to an attribute specified by Service UUID and
// Characteristic UUID.
//
- (BOOL) setNotifyValue:(BOOL)isNotify forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid;

//
// This method registers the delegate for all profiles bonded with this device.
//
- (void) registerDelegateForProfiles:(id)delegate;

//
// This method change the delegate for this device.
//
- (void) changeDelegateForDevice:(id)delegate;

//
// Change service UUID
//
- (void) changePrimaryServiceUUIDTo:(CBUUID*)uuid;

//
// Revert service UUID to originally assigned
//
- (void) revertPrimaryServiceUUID;

//
// This method enables the RSSI reading notification for this device.
//
- (void) enableRssiReadingWithNotification:(BOOL)isNotifying howFrequent:(NSTimeInterval)period;

//
// This method disables the RSSI reading notification for this device.
//
- (void) disableRssiReading;

//
// This method adds profile into this device.
//
- (void) addProfile:(BLEProfile*)profile;

//
// This method lists all registered profiles with this device.
//
- (NSSet*) listRegisteredProfile;

//
// This method list all service UUIDs associated with each registered profile.
//
- (NSArray*) listServiceUUID;

//
// This method list all primary only service UUIDs associated with each registered profile.
//
- (NSArray*) listPrimaryServiceUUID;

//
// This method is called by a profile when that profile is ready for service.
// This device will collect all ready signals from each registered profile
// before issuing Device:allProfileIsReady:.
//
- (void) profile:(BLEProfile*)profile isReady:(BOOL)isReady;

- (CBPeripheral*) centralPeripheral;

//
// These methods collect and manage the primary service UUIDs.
// When primary service UUIDs are added in this device, the listPrimaryServiceUUID
// API will return the added primary service UUIDs, instead of returning the
// primary service UUIDs maintained by the BLEProile. This feature is used when
// dynamic primary service UUID is required - e.g. primary service uuid is unique to
// each device and can only be obtained during device discovery process.
//
- (void) emptyDynamicPrimaryServiceUUID;
- (void) addDynamicPrimaryServiceUUID:(CBUUID*)uuid;
- (void) removeDynamicPrimaryServiceUUID:(CBUUID*)uuid;
- (NSArray*) listDynamicPrimaryServiceUUIDs;
- (BOOL) matchLocalDynamicPrimaryServiceUUID:(CBUUID*)uuid;
- (BOOL) matchGlobalDynamicPrimaryServiceUUID:(CBUUID*)uuid;

@end

//
// This utility function constructs a non-duplicated array of service UUIDs
// from the given profiles array.
//
NSArray* bleUtilityDeviceConstructServiceArray(NSArray* profiles);

#endif