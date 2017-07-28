//
//  DxAppFirmLogStateMachine.h
//  DataExchangerApp
//
//  Created by Ming Leung on 2016-11-14.
//  Copyright © 2016 GT-Tronics HK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataExchangerDevice.h"

typedef enum
{
    STATE_IDLE = 0,
    STATE_FIRM_READ_FLASH_SZ,
    STATE_FIRM_READ_META,
    STATE_FIRM_VERSIONS,
    STATE_FIRM_UPDATE_META,
    STATE_FIRM_READ_IMG,
    STATE_FIRM_WRITE_IMG,
    STATE_FIRM_WRITE_IMG_INTER_CMD,
    STATE_FIRM_WHICH_SLOT,
    STATE_FIRM_CRC_CHECK,
    STATE_FIRM_CRC_CHECK_AFTER_WRITE,
    
    STATE_DLGR_META,
    STATE_DLGR_READ_A,
    STATE_DLGR_READ_B,
} FirmLogStateTyp;

@interface DxAppFirmLogStateMachine : NSObject

@property (nonatomic, readwrite) FirmLogStateTyp        state;
@property (nonatomic, strong)    NSString* _Nullable    interleaveCommand;
@property (nonatomic, assign)    NSUInteger             interleaveCount;

- (BOOL) retrieveDataLoggerMetaWithCompletion:(nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler fromDevice:(nonnull DataExchangerDevice*)device;

- (BOOL) retrieveDataLoggerDataWithMetas:(nonnull NSDictionary*)metas metaKey:(nonnull NSString*)key flush:(BOOL)isFlush completion:(nullable void (^) (NSData* _Nullable data, NSError* _Nullable err))completeHandler fromDevice:(nonnull DataExchangerDevice*)device;

- (BOOL) retrieveFirmwareMetaWithProgress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^)(NSDictionary* _Nullable, NSError* _Nullable))completeHandler fromDevice:(nonnull DataExchangerDevice*)device;

- (BOOL) writeFirmwareImageInSlot:(uint8_t)slotIdx firmwareData:(nonnull NSData*)firmData scratchPad:(nullable NSData*)scratchPad progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler inDevice:(nonnull DataExchangerDevice*)device;

- (BOOL) deleteFirmwareImageFromSlot:(uint8_t)slotIdx progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* _Nullable metas, NSError* _Nullable err))completeHandler inDevice:(nonnull DataExchangerDevice*)device;

- (BOOL) primeFirmwareBinary:(nonnull NSData*)firmBin name:(nullable NSString*)firmName progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^)(NSDictionary* _Nullable, NSError * _Nullable))completeHandler fromDevice:(nonnull DataExchangerDevice*)device;

-(void) notifyDeviceOff;

- (BOOL) processDidWriteWithError:(nullable NSError*)error fromDevice:(nonnull DataExchangerDevice*)device;
- (BOOL) processRx2Data:(nonnull NSData*)data fromDevice:(nonnull DataExchangerDevice*)device;
- (BOOL) processTxCredit:(NSUInteger)credits fromDevice:(nonnull DataExchangerDevice*)device;

+ (uint16_t) crc16CalcOnData:(nonnull uint8_t*)data length:(NSUInteger)len;

@end
