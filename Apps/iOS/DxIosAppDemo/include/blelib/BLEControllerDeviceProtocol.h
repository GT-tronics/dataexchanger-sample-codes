//
//  BLEControllerDeviceProtocol.h
//  blelib
//
//  Created by Ming Leung on 12-07-16.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 31 $
//
// This protocol is primarily used by BLEDevice base class.
// User doesn't require to implement any of these functions.
//

#ifndef __BLECONTROLLERDEVICEPROTOCOL_H__
#define __BLECONTROLLERDEVICEPROTOCOL_H__

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

@protocol BLEControllerDeviceProtocol <NSObject>

@required

// Report peripheral device connected successfully
- (void) centralManager:(CBCentralManager *)central reportPeripheralConnected:(CBPeripheral*)peripheral;

// Report peripheral device connected failed
- (void) centralManager:(CBCentralManager *)central reportPeripheralConnectedFailed:(CBPeripheral*)peripheral;

// Report peripheral device disconnected
- (void) centralManager:(CBCentralManager *)central reportPeripheralDisconnected:(CBPeripheral*)peripheral;

// Report peripheral device discovered with rssi
- (BOOL) centralManager:(CBCentralManager *)central reportPeripheralDiscovered:(CBPeripheral*)peripheral withAdvertisementData:(NSDictionary*)ad rssi:(NSNumber*)rssi;

@end

#endif