//
//  BLEProfile.h
//  blelib
//
//  Created by Ming Leung on 12-07-16.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 49 $
//

#ifndef __BLEPROFILE_H__
#define __BLEPROFILE_H__

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import "BLEDevice.h"
#import "BLEDeviceProfileProtocol.h"

@interface BLEProfile : NSObject <BLEDeviceProfileProtocol>

// This dictionary contains service UUIDs registered with this profile
@property (nonatomic, strong)   NSMutableDictionary*    serviceUUIDDict;

// This dictionary contains primary service UUIDs registered with this profile
@property (nonatomic, strong)   NSMutableArray*    primaryServiceUUIDs;

// Device to which this profile is bonded.
@property (nonatomic, weak)     BLEDevice*              device;

// This-Profile-Is-Ready flag
@property (nonatomic, assign)   BOOL                    isReady;

//
// Init
//
- (BLEProfile*) initWithDevice:(BLEDevice*)device;

//
// List of all registered service UUIDs
//
- (NSArray*) listServiceUUID;

//
// List of all registered primary service UUIDs
//
- (NSArray*) listPrimaryServiceUUID;

//
// Change app delegate of this profile. This is only an empty base
// class function.
//
- (void) changeAppDelegate:(id)appDelegate;

//
// Return whether this profile should report ready. This method is called
// by lower subclass profile to decide whether it should report ready.
// The usage scenerio is as follows:
// 1. upper subclass would be the only subclass to report ready.
// 2. upper subclass would implement this function and return NO.
// 3. when lower subclass is about to report ready, it will check
//    with this method to see whether it should report ready first.
//
- (BOOL) shouldReportReady;

//
// Change service UUID
//
- (BOOL) changePrimaryServiceUUIDTo:(CBUUID*)newUUID;

//
// Revert Service UUID to originally assigned
//
- (void) revertPrimaryServiceUUID;

- (void) reset;

@end

//
// This utility function contructs an array of non-duplciated service UUIDs
// from an array of profiles.
//
NSArray* bleUtilityProfileConstructServiceArray(NSArray* profiles);

#endif