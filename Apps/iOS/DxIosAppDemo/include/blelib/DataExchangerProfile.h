//
//  DataExchangerProfile.h
//  blelib
//
//  Created by Ming Leung on 12-12-12.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 57 $
//


#import "BLEProfile.h"
#import "DataExchangerProfileProtocol.h"

extern NSString* const kDXServiceUUID;
extern NSString* const kDXI2cSetupUUID;

@interface DataExchangerProfile : BLEProfile

@property (nonatomic, weak)   id<DataExchangerProfileProtocol>      appDelegate;
@property (nonatomic, assign) BOOL                                  enableRx2Noti;
@property (nonatomic, assign) BOOL                                  enableTxCreditNoti;
@property (nonatomic, assign) BOOL                                  enableChScrmb;

//
//Init
//
- (BLEProfile*) initWithDevice:(BLEDevice*)device andAppDelegate:(id<DataExchangerProfileProtocol>)appDelegate;
- (BLEProfile*) initWithDevice:(BLEDevice*)device andAppDelegate:(id<DataExchangerProfileProtocol>)delegate andServiceUUIDStrings:(NSArray*)suuidStrs;
+ (BLEProfile*) profileWithDevice:(BLEDevice*)device andAppDelegate:(id<DataExchangerProfileProtocol>)appDelegate;
+ (BLEProfile*) profileWithDevice:(BLEDevice*)device andAppDelegate:(id<DataExchangerProfileProtocol>)delegate andServiceUUIDStrings:(NSArray*)suuidStrs;

//
// Change app delegate
//
- (void) changeAppDelegate:(id)appDelegate;

//
// This method will send data to the uart port of the connected BLE device
// - deprecated. Use sendTx:
//
- (BOOL) sendData:(NSData*)data;

//
// This method will send data to the Tx port 1 of the connected BLE device
// - deprecated. Use sendTx:
//
- (BOOL) sendTx:(NSData*)data;
- (BOOL) sendTx:(NSData*)data withResponse:(BOOL)response;

//
// This method will send data to the Tx port 2 of the connected BLE device
// - deprecated. Use sendTx:
//
- (BOOL) sendTx2:(NSData*)data;
- (BOOL) sendTx2:(NSData*)data withResponse:(BOOL)response;

//
// This method will enable/disable Rx2 port notification of the connected BLE device
//
- (BOOL) enableRx2Notification:(BOOL)enabled;

//
// This method will enable/disable Tx port credit notification of the connected BLE device
//
- (BOOL) enableTxCreditNotification:(BOOL)enabled;

//
// This methd will enabl/disable channel scrambling
//
- (BOOL) enableChannelScrambler:(BOOL)enabled;

//
// This method will read the TX Credit count
//
- (BOOL) readTxCredit;

//
// This method will write the TX Credit Report Loop Count
//
- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count;

- (BOOL) switchScrambling:(BOOL)isOn;

@end
