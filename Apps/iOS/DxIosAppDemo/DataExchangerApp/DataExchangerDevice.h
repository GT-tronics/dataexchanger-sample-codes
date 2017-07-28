//
//  DataExchangerDevice.h
//  BLETestApp
//
//  Created by Ming Leung on 12-12-12.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 427 $
//

#import "BLEDevice.h"

@class DataExchangerDevice;

@protocol DataExchangerDeviceAppDelegateProtocol <BLEDeviceAppDelegateProtocol>

@required

- (void) Device:(DataExchangerDevice*)d active:(BOOL)isActive parameters:(NSDictionary*)params;

@end

@interface DataExchangerDevice : BLEDevice

// Proximity connecting
@property (nonatomic, readwrite)       BOOL                proximityConnecting;

// Proximity minimum power level
@property (nonatomic, readwrite)       float               minPowerLevel;

// Discovery active timeout
@property (nonatomic, readwrite)       NSTimeInterval      discoveryActiveTimeout;


+ (DataExchangerDevice*) deviceWithAppDelegate:(id<DataExchangerDeviceAppDelegateProtocol>)delegate;

- (BOOL) sendData:(NSData*)data;
- (BOOL) sendCmd:(NSData*)data withResponse:(BOOL)response;
- (BOOL) enableCmd:(BOOL)enabled;
- (BOOL) enableChannelScrambler:(BOOL)enabled;
- (BOOL) enableTxCreditNotification:(BOOL)enabled;
- (BOOL) readTxCredit;
- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count;

@end
