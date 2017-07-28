//
//  BLEDeviceProfileProtocol.h
//  blelib
//
//  Created by Ming Leung on 12-07-17.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  This protocol is used by BLE profile to receive notifications
//  from BLE device about the requested actions on attributes.
//
//  $Rev: 19 $
//

#import <Foundation/Foundation.h>

@protocol BLEDeviceProfileProtocol <NSObject>

@required

//
// Called when the device which the profile is bonded has been disconnected.
//
- (void) reset;

@optional

//
// Called when a characteristic for a service is discovered.
// - deprecated
//
- (void) didDiscoveredCharacteristic:(CBUUID*)cuuid forService:(CBUUID*)suuid;

//
// Called when a characteristic for a service is discovered.
//
- (void) didDiscoveredCharacteristic:(CBUUID*)cuuid forService:(CBUUID*)suuid withError:(NSError*)error;

//
// Called when the read request on a characteristic is ready with data.
// - deprecated
//
- (void) didUpdateValue:(NSData*)data forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid;

//
// Called when the read request on a characteristic is ready with data or error.
//
- (void) didUpdateValue:(NSData*)data forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid withError:(NSError*)error;

//
// Called when the write request on a characteristic is done.
// - deprecated
//
- (void) didWriteValueForCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid;

//
// Called when the write request on a characteristic is done.
//
- (void) didWriteValueForCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid withError:(NSError*)error;

//
// Called when the change of notification on a characteristic is done.
// - deprecated
//
- (void) didUpdateNotificationState:(BOOL)isNotifying forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid;

//
// Called when the change of notification on a characteristic is done.
//
- (void) didUpdateNotificationState:(BOOL)isNotifying forCharacteristic:(CBUUID*)cuuid andService:(CBUUID*)suuid withError:(NSError*)error;

@end
