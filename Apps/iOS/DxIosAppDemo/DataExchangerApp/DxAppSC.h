//
//  DxAppSC.h
//  DataExchangerApp
//
//  Created by Ming Leung on 2015-09-24.
//  Copyright © 2015 GT-Tronics HK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataExchangerDevice.h"
#import "DataExchangerProfileProtocol.h"

@interface DxAppSC : NSObject <DataExchangerDeviceAppDelegateProtocol, DataExchangerProfileProtocol>

@property (nonatomic, assign)   BOOL            enableTxCreditNoti;
@property (nonatomic, weak)     id _Nullable    delegate;

+ (nullable DxAppSC*)controller;
+ (nullable DxAppSC*)controllerNoConnect;
+ (void) assignToController:(nullable DxAppSC*)controller byDelegate:(nullable id)delegate;
+ (void) assignToControllerNoConnect:(nullable DxAppSC*)controller;


- (nullable id) initWithDeviceCount:(NSUInteger)devCount proximityPowerLevel:(float)pwrLevel discoveryActiveTimeout:(NSTimeInterval) timeout autoConnect:(BOOL)autoConnect enableCommandChannel:(BOOL)enableCmdCh enableChannelScrambler:(BOOL)enableChScrm enableTransmitBackPressure:(BOOL)enableTxCredit;

- (nullable id) initWithDeviceCount:(NSUInteger)devCount proximityPowerLevel:(float)pwrLevel discoveryActiveTimeout:(NSTimeInterval) timeout autoConnect:(BOOL)autoConnect enableCommandChannel:(BOOL)enableCmdCh enableChannelScrambler:(BOOL)enableChScrm enableTransmitBackPressure:(BOOL)enableTxCredit serviceUUIDStrings:(nullable NSArray*)suuidStrs;


- (void) changeProximityConnectPower:(NSInteger)proxPwrLvl;

- (BOOL) isEnabled;

- (void) startScan;
- (void) stopScan;
- (BOOL) isScanning;
- (void) enableScanning;
- (void) disableScanning;

- (BOOL) connectDevice:(nonnull NSUUID*)uuid;
- (BOOL) disconnectDevice:(nonnull NSUUID*)uuid;
- (NSUInteger) connectedDeviceCount;
- (BOOL) isDeviceConnected:(nonnull NSUUID*)uuid;
- (BOOL) isDeviceActive:(nonnull NSUUID*)uuid;

- (BOOL) isConnected; // legacy API
- (BOOL) disconnect;  // legacy API

- (BOOL) sendData:(nonnull NSData*)data;
- (BOOL) sendData:(nonnull NSData*)data toDevice:(nonnull NSUUID*)uuid;

- (BOOL) sendCmd:(nonnull NSData*)data;
- (BOOL) sendCmd:(nonnull NSData*)data toDevice:(nonnull NSUUID*)uuid;

- (BOOL) enableCmd:(BOOL)enabled;
- (BOOL) enableCmd:(BOOL)enabled onDevice:(nonnull NSUUID*)uuid;

- (BOOL) enableChannelScrambler:(BOOL)enabled;
- (BOOL) enableChannelScrambler:(BOOL)enabled onDevice:(nonnull NSUUID*)uuid;

- (BOOL) readTxCredit;
- (BOOL) readTxCreditFromDevice:(nonnull NSUUID*)uuid;

- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count;
- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count inDevice:(nonnull NSUUID*)uuid;

- (BOOL) retrieveDataLoggerMetaWithCompletion:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler;
- (BOOL) retrieveDataLoggerMetaWithCompletion:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler fromDevice:(nonnull NSUUID*)uuid;

- (BOOL) retrieveDataLoggerDataUsingMetas:(nonnull NSDictionary*)metas metaKey:(nonnull NSString*)key flush:(BOOL)isFlush completion:(nullable void (^) (NSData* _Nullable data, NSError* _Nullable err))completeHandler;
- (BOOL) retrieveDataLoggerDataUsingMetas:(nonnull NSDictionary*)metas metaKey:(nonnull NSString*)key flush:(BOOL)isFlush completion:(nullable void (^) (NSData* _Nullable data, NSError* _Nullable err))completeHandler fromDevice:(nonnull NSUUID*)uuid;

- (BOOL) retrieveFirmwareMetaWithProgress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler;
- (BOOL) retrieveFirmwareMetaWithProgress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler fromDevice:(nonnull NSUUID*)uuid;

- (BOOL) writeFirmwareImageInSlot:(uint8_t)slotIdx firmwareData:(nonnull NSDictionary*)firmData scratchPad:(nullable NSData*)scratchPad progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler;
- (BOOL) writeFirmwareImageInSlot:(uint8_t)slotIdx firmwareData:(nonnull NSDictionary*)firmData scratchPad:(nullable NSData*)scratchPad progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler inDevice:(nonnull NSUUID*)uuid;

- (BOOL) deleteFirmwareImageFromSlot:(uint8_t)slotIdx progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler;
- (BOOL) deleteFirmwareImageFromSlot:(uint8_t)slotIdx progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler inDevice:(nonnull NSUUID*)uuid;

- (BOOL) switchFirmwareImageToSlot:(uint8_t)slotIdx keepConfig:(BOOL)bKeepConfig;
- (BOOL) switchFirmwareImageToSlot:(uint8_t)slotIdx keepConfig:(BOOL)bKeepConfig inDevice:(nonnull NSUUID*)uuid;

- (BOOL) primeFirmwareBinary:(nonnull NSData*)firmBin name:(nullable NSString*)firmName progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler;
- (BOOL) primeFirmwareBinary:(nonnull NSData*)firmBin name:(nullable NSString*)firmName progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler inDevice:(nonnull NSUUID*)uuid;

- (uint16_t) crc16CalcOnData:(nonnull uint8_t*)data length:(NSUInteger)len;

- (void) setInterleavingCommand:(nullable NSString*)cmd interleavingCount:(NSUInteger)count;
- (void) setInterleavingCommand:(nullable NSString*)cmd interleavingCount:(NSUInteger)count inDevice:(nonnull NSUUID*)uuid;

@end
