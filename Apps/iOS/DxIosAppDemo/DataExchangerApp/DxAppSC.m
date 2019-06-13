//
//  DxAppSC.m
//  DataExchangerApp
//
//  Created by Ming Leung on 2015-09-24.
//  Copyright © 2015 GT-Tronics HK Ltd. All rights reserved.
//

#import "DxAppSC.h"
#import "BLEController.h"
#import "DataExchangerDevice.h"
#import "DataExchangerProfile.h"
#import "DxAppFirmLogStateMachine.h"

static NSString* const kDevNameDX      = @"DataExchanger";
static DxAppSC* gController = nil;
static DxAppSC* gController2 = nil;


@interface DxAppSC ()
{
    int _lastMinPwrLevel;
}

// BLE
@property (nonatomic, strong)   BLEController*                  bleController;
@property (nonatomic, strong)   DataExchangerDevice*            device;
@property (nonatomic, strong)   NSMutableDictionary*            activeDevices;
@property (nonatomic, strong)   NSMutableDictionary*            connectedDevices;
@property (nonatomic, strong)   NSMutableSet*                   allDevices;

@property (nonatomic, strong)   NSMutableDictionary*            firmLogSMs;

@end

@implementation DxAppSC

@synthesize bleController;
@synthesize device;
@synthesize enableTxCreditNoti;
@synthesize activeDevices;
@synthesize connectedDevices;
@synthesize allDevices;
@synthesize firmLogSMs;
@synthesize delegate;

+ (DxAppSC*)controller
{
    if( gController == nil )
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL enableCmdCh = [defaults boolForKey:@"enableCmdCh"];
        BOOL enableChScrm = [defaults boolForKey:@"enableChScrm"];
        NSInteger proxPwrLvl = [defaults integerForKey:@"proxPwrLvl"];
        NSString* suuidListStr = [defaults stringForKey:@"svcUUIDList"];
        
        BOOL backToDefault = NO;
        
        if( suuidListStr && suuidListStr.length > 0 )
        {
            NSArray* suuidStrs = [suuidListStr componentsSeparatedByString:@","];
            
            // Verify the UUID string is valid
            for( NSString* suuidStr in suuidStrs )
            {
                if( [[NSUUID alloc] initWithUUIDString:[suuidStr capitalizedString]] == nil )
                {
                    backToDefault = YES;
                    break;
                }
            }
            
            if( !backToDefault )
            {
                gController = [[DxAppSC alloc] initWithDeviceCount:1 proximityPowerLevel:proxPwrLvl discoveryActiveTimeout:5.0 autoConnect:YES enableCommandChannel:enableCmdCh enableChannelScrambler:enableChScrm enableTransmitBackPressure:YES serviceUUIDStrings:suuidStrs];
            }
        }
        else
        {
            backToDefault = YES;
        }
        
        if( backToDefault )
        {
            gController = [[DxAppSC alloc] initWithDeviceCount:1 proximityPowerLevel:proxPwrLvl discoveryActiveTimeout:5.0 autoConnect:YES enableCommandChannel:enableCmdCh enableChannelScrambler:enableChScrm enableTransmitBackPressure:YES];
        }
    }
    
    return gController;
}

+ (DxAppSC*)controllerNoConnect
{
    if( gController2 == nil )
    {
        gController2 = [[DxAppSC alloc] initWithDeviceCount:1 proximityPowerLevel:0 discoveryActiveTimeout:5.0 autoConnect:NO enableCommandChannel:NO enableChannelScrambler:NO enableTransmitBackPressure:NO];
    }
    
    return gController2;
}

+ (void) assignToController:(DxAppSC*)controller byDelegate:(id)delegate
{
    gController = controller;
    if( controller )
    {
        controller.delegate = delegate;
    }
}

+ (void) assignToControllerNoConnect:(DxAppSC*)controller
{
    gController2 = controller;
}

- (id) initWithDeviceCount:(NSUInteger)devCount proximityPowerLevel:(float)pwrLevel discoveryActiveTimeout:(NSTimeInterval) timeout autoConnect:(BOOL)autoConnect enableCommandChannel:(BOOL)enableCmdCh enableChannelScrambler:(BOOL)enableChScrm enableTransmitBackPressure:(BOOL)enableTxCredit
{
    return [self initWithDeviceCount:devCount proximityPowerLevel:pwrLevel discoveryActiveTimeout:timeout autoConnect:autoConnect enableCommandChannel:enableCmdCh enableChannelScrambler:enableChScrm enableTransmitBackPressure:enableTxCredit serviceUUIDStrings:nil];
}

- (id) initWithDeviceCount:(NSUInteger)devCount proximityPowerLevel:(float)pwrLevel discoveryActiveTimeout:(NSTimeInterval) timeout autoConnect:(BOOL)autoConnect enableCommandChannel:(BOOL)enableCmdCh enableChannelScrambler:(BOOL)enableChScrm enableTransmitBackPressure:(BOOL)enableTxCredit serviceUUIDStrings:(NSArray*)suuidStrs
{
    self = [super init];
    if( self == nil )
    {
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bleControllerOn)
                                                 name:@"BleControllerOn"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bleControllerOff)
                                                 name:@"BleControllerOff"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bleControllerReset)
                                                 name:@"BleControllerReset"
                                               object:nil];
    activeDevices = [@{} mutableCopy];
    connectedDevices = [@{} mutableCopy];
    allDevices = [NSMutableSet set];
    firmLogSMs = [@{} mutableCopy];
    
    //
    // Initialize BLE controller, device, and profile. Please follow these steps:
    //
    // 1. Create BLE controller
    // 2. Create DataExchanger BLE device. DataExchangerDevice should be subclassed from BLEDevice.
    // 3. Create DataExchanger BLE profile. DataExchangerProfile has already been implemented in libblelib.a.
    // 4. Bind DataExchangerProfile with DataExchangerDevice.
    // 5. Bind DataExchangerDevice with BLE controller.
    //
    // 1. Create BLE controller
    [BLEController enablePrivateCentralQueue];
    bleController = [[BLEController alloc] init]; // [BLEController controller];
    bleController.scanDevicePolicy = SCAN_ALLOW_DUPLICATED_KEY;

    for( int i=0; i < devCount; i++)
    {
        // 2. Create DataExchanger device
        device = [DataExchangerDevice deviceWithAppDelegate:self];
        device.devName = [NSString stringWithString:kDevNameDX];
        device.autoConnect = autoConnect;
        device.discoveryActiveTimeout = timeout;
        
        if( pwrLevel <= -127 )
        {
            device.proximityConnecting = NO;
        }
        else
        {
            device.proximityConnecting = YES;
            if( pwrLevel > -20 )
            {
                pwrLevel = -20;
            }
            device.minPowerLevel = pwrLevel;
        }
        
        // 3. Create DataExchanger profile
        DataExchangerProfile* dxp;
        if( suuidStrs == nil )
        {
            dxp = (DataExchangerProfile*)[DataExchangerProfile profileWithDevice:device andAppDelegate:self];
        }
        else
        {
            dxp = (DataExchangerProfile*)[DataExchangerProfile profileWithDevice:device andAppDelegate:self andServiceUUIDStrings:suuidStrs];
        }
        
        dxp.enableRx2Noti = enableCmdCh;
        dxp.enableChScrmb = enableChScrm;
        dxp.enableTxCreditNoti = enableTxCredit;
        
        // 4. Add DataExchanger profile in DataExchanger device
        [device addProfile:dxp];
        
        // 5. Register DataExchanger device with BLE controller
        [bleController registerDevice:device];
        
        [allDevices addObject:device];
    }
    
    return self;
}

- (void) changeProximityConnectPower:(NSInteger)proxPwrLvl
{
    for( DataExchangerDevice* d in allDevices )
    {
        d.proximityConnecting = proxPwrLvl <= -127 ?NO :YES;
        d.minPowerLevel = proxPwrLvl;
    }
}

- (BOOL) isEnabled
{
    return [bleController isBluetoothOn];
}

- (void) startScan
{
    NSMutableSet* unconnected = [allDevices copy];
    if( connectedDevices.count > 0 )
    {
        [unconnected minusSet:[NSSet setWithArray:connectedDevices.allValues]];
    }
    if( unconnected.count > 0 )
    {
        [bleController startScan];
    }
}

- (void) stopScan
{
    [bleController stopScan];
}

- (BOOL) isScanning
{
    return [bleController isScanning];
}

- (void) enableScanning
{
    if( device && _lastMinPwrLevel != 0 )
    {
        device.minPowerLevel = _lastMinPwrLevel;
    }
    [bleController enableScanning];
}

- (void) disableScanning
{
    [bleController disableScanning];
    if( device )
    {
        _lastMinPwrLevel = device.minPowerLevel;
    }
}

- (BOOL) isDeviceActive:(NSUUID*)uuid
{
    DataExchangerDevice* d = activeDevices[uuid];
    
    return d ?YES :NO;
}

- (BOOL) isDeviceConnected:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    
    return d ?YES :NO;
}

// Legacy API
- (BOOL) isConnected
{
    if( device == nil )
    {
        return NO;
    }
    
    return device.state == BLE_DEVICE_CONNECTED;
}

- (BOOL) disconnect
{
    if( device == nil )
    {
        return NO;
    }
    
    [device disconnect];
    
    return YES;
}

- (NSUInteger) connectedDeviceCount
{
    return connectedDevices.count;
}

- (BOOL) connectDevice:(NSUUID*)uuid
{
    return [bleController connectDevice:uuid];
}

- (BOOL) disconnectDevice:(NSUUID*)uuid
{
    return [bleController disconnectDevice:uuid];
}

- (BOOL) sendData:(NSData *)data
{
    if( device == nil )
    {
        return NO;
    }
    
    return [device sendData:data];
}

- (BOOL) sendData:(NSData*)data toDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [d sendData:data];
}

- (BOOL) sendCmd:(NSData*)data
{
    if( device == nil )
    {
        return NO;
    }
    
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    if( sm.state != STATE_IDLE )
    {
        return NO;
    }
    
    return [device sendCmd:data withResponse:YES];
}

- (BOOL) sendCmd:(NSData*)data toDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }

    if( ((DxAppFirmLogStateMachine*)firmLogSMs[uuid]).state != STATE_IDLE )
    {
        return NO;
    }
    
    return [d sendCmd:data withResponse:YES];
}

- (BOOL) enableCmd:(BOOL)enabled
{
    if( device == nil )
    {
        return NO;
    }
    
    return [device enableCmd:enabled];
}

- (BOOL) enableCmd:(BOOL)enabled onDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [d enableCmd:enabled];
}

- (BOOL) enableChannelScrambler:(BOOL)enabled
{
    if( device == nil )
    {
        return NO;
    }
    
    return [device enableChannelScrambler:enabled];
}

- (BOOL) enableChannelScrambler:(BOOL)enabled onDevice:(nonnull NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [d enableChannelScrambler:enabled];
}


- (BOOL) readTxCredit
{
    if( device == nil )
    {
        return NO;
    }
    
    return [device readTxCredit];
}

- (BOOL) readTxCreditFromDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [d readTxCredit];
}

- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count
{
    if( device == nil )
    {
        return NO;
    }
    
    return [device writeTxCreditReportLoopCount:count];
}

- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count inDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [d writeTxCreditReportLoopCount:count];
}

// Retrieve meta data from data logger
- (BOOL) retrieveDataLoggerMetaWithCompletion:(nullable void (^) (NSDictionary* metas, NSError* err))completeHandler
{
    if( device == nil )
    {
        return NO;
    }
    
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    return [sm retrieveDataLoggerMetaWithCompletion:completeHandler fromDevice:device];
}

- (BOOL) retrieveDataLoggerMetaWithCompletion:(nullable void (^) (NSDictionary* metas, NSError* err))completeHandler fromDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [firmLogSMs[uuid] retrieveDataLoggerMetaWithCompletion:completeHandler fromDevice:d];
}

// Retrieve data from data logger
- (BOOL) retrieveDataLoggerDataUsingMetas:(NSDictionary*)metas metaKey:(NSString*)key flush:(BOOL)isFlush completion:(nullable void (^) (NSData* data, NSError* err))completeHandler
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    return [sm retrieveDataLoggerDataWithMetas:metas metaKey:key flush:isFlush completion:completeHandler fromDevice:device];
}

- (BOOL) retrieveDataLoggerDataUsingMetas:(NSDictionary*)metas metaKey:(NSString*)key flush:(BOOL)isFlush completion:(nullable void (^) (NSData* data, NSError* err))completeHandler fromDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [firmLogSMs[uuid] retrieveDataLoggerDataWithMetas:metas metaKey:key flush:isFlush completion:completeHandler fromDevice:d];
}


// Retrieve firmware meta
- (BOOL) retrieveFirmwareMetaWithProgress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(void (^)(NSDictionary*, NSError *))completeHandler
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    return [sm retrieveFirmwareMetaWithProgress:progressHandler complete:completeHandler fromDevice:device];
}

- (BOOL) retrieveFirmwareMetaWithProgress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(void (^)(NSDictionary*, NSError *))completeHandler fromDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [firmLogSMs[uuid] retrieveFirmwareMetaWithProgress:progressHandler complete:completeHandler fromDevice:d];
}


// Write firmware image
- (BOOL) writeFirmwareImageInSlot:(uint8_t)slotIdx firmwareData:(NSData*)firmData scratchPad:(NSDictionary*)scratchPad progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* metas, NSError* err))completeHandler
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    return [sm writeFirmwareImageInSlot:slotIdx firmwareData:firmData scratchPad:scratchPad progress:progressHandler complete:completeHandler inDevice:device];
}

- (BOOL) writeFirmwareImageInSlot:(uint8_t)slotIdx firmwareData:(NSData*)firmData scratchPad:(NSDictionary*)scratchPad progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* metas, NSError* err))completeHandler inDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [firmLogSMs[uuid] writeFirmwareImageInSlot:slotIdx firmwareData:firmData scratchPad:scratchPad progress:progressHandler complete:completeHandler inDevice:d];
}


// Delete firmware meta
- (BOOL) deleteFirmwareImageFromSlot:(uint8_t)slotIdx progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* metas, NSError* err))completeHandler
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    return [sm deleteFirmwareImageFromSlot:slotIdx progress:progressHandler complete:completeHandler inDevice:device];
}

- (BOOL) deleteFirmwareImageFromSlot:(uint8_t)slotIdx progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete: (nullable void (^) (NSDictionary* metas, NSError* err))completeHandler inDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [firmLogSMs[uuid] deleteFirmwareImageFromSlot:slotIdx progress:progressHandler complete:completeHandler inDevice:d];
}

- (BOOL) switchFirmwareImageToSlot:(uint8_t)slotIdx keepConfig:(BOOL)bKeepConfig
{
    if( device == nil )
    {
        return NO;
    }
    
    return [self _switchFirmwareImageToSlot:slotIdx keepConfig:bKeepConfig inDevice:device];
}

- (BOOL) switchFirmwareImageToSlot:(uint8_t)slotIdx keepConfig:(BOOL)bKeepConfig inDevice:(NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    
    return [self _switchFirmwareImageToSlot:slotIdx keepConfig:bKeepConfig inDevice:d];
}

- (BOOL) _switchFirmwareImageToSlot:(uint8_t)slotIdx keepConfig:(BOOL)bKeepConfig inDevice:(DataExchangerDevice*)d
{
    NSString* cmdStr = [NSString stringWithFormat:@"AT+IMG=%u\r\n", bKeepConfig ?slotIdx :slotIdx+128];
    BOOL success = [d sendCmd:[cmdStr dataUsingEncoding:NSUTF8StringEncoding] withResponse:YES];
    NSLog(@"[INFO] Firmware: %@", cmdStr);
    
    return success;
}

- (BOOL) primeFirmwareBinary:(nonnull NSData*)firmBin name:(nullable NSString*)firmName progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^)(NSDictionary*, NSError *))completeHandler
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    
    return [sm primeFirmwareBinary:firmBin name:firmName progress:progressHandler complete:completeHandler fromDevice:device];
}

- (BOOL) primeFirmwareBinary:(nonnull NSData*)firmBin name:(nullable NSString*)firmName progress:(nullable void (^) (NSUInteger stage, double progress))progressHandler complete:(nullable void (^)(NSDictionary*, NSError *))completeHandler inDevice:(nonnull NSUUID*)uuid
{
    DataExchangerDevice* d = connectedDevices[uuid];
    if( !d )
    {
        return NO;
    }
    return [firmLogSMs[uuid] primeFirmwareBinary:firmBin name:firmName progress:progressHandler complete:completeHandler fromDevice:d];
}

- (void) setInterleavingCommand:(nullable NSString*)cmd interleavingCount:(NSUInteger)count
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[device.devUUID UUIDString]];
    DxAppFirmLogStateMachine* sm = firmLogSMs[devUUID];
    sm.interleaveCommand = cmd;
    sm.interleaveCount = count;
}

- (void) setInterleavingCommand:(nullable NSString*)cmd interleavingCount:(NSUInteger)count inDevice:(nonnull NSUUID*)uuid
{
    
    DxAppFirmLogStateMachine* sm = firmLogSMs[uuid];
    sm.interleaveCommand = cmd;
    sm.interleaveCount = count;
}

#pragma mark -
#pragma mark - DataExchangerDeviceAppDelegateProtocol methods

// This member function is called when DataExchangerDevice reports discovery activity.
// Please note this is called only when autoConnect is set NO
- (void) Device:(DataExchangerDevice *)d active:(BOOL)isActive parameters:(NSDictionary *)params
{
    CBUUID* cbUUID = params[@"CBUUID"];
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[cbUUID UUIDString]];
    
    activeDevices[devUUID] = isActive ?d :nil;

    NSString* name = @"Unknown";
    NSString* nameFromAdv = params[@"ADV"][@"kCBAdvDataLocalName"];
    if( nameFromAdv )
    {
        name = nameFromAdv;
    }
    
    NSNumber* txPwrNum = @999;
    NSNumber* txPwrNumFromAdv = params[@"ADV"][@"kCBAdvDataTxPowerLevel"];
    if( txPwrNumFromAdv )
    {
        txPwrNum = txPwrNumFromAdv;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                        object:nil
                                                      userInfo:@{
                                                                 @"Command":isActive ?@"DeviceDiscOn" :@"DeviceDiscOff",
                                                                 @"DevInfo":@{
                                                                         @"UUID":[cbUUID UUIDString],
                                                                         @"NAME":name,
                                                                         @"CONNECTABLE":params[@"ADV"][@"kCBAdvDataIsConnectable"],
                                                                         @"TXPWR":txPwrNum,
                                                                         @"RSSI":params[@"RSSI"]
                                                                         },
                                                                 }];
}

// This member function is called when the device is discovered and
// connected or is disconnected. This function is called before
// Device:allProfilesReady:.
- (void) Device:(DataExchangerDevice*)d switchOn:(BOOL)flag
{
    //
    // Receive notification of device status change
    //
    
    device = (DataExchangerDevice*)d;
    
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[d.devUUID UUIDString]];

    if( flag == NO )
    {
        //
        // Device is disconnected.
        //

        connectedDevices[devUUID] = nil;
        activeDevices[devUUID] = nil;

        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{
                                                                     @"Command":@"DeviceOff",
                                                                     @"DevInfo":@{
                                                                                    @"UUID":[d.devUUID UUIDString]
                                                                                 }
                                                                    }];
                                                          
        [firmLogSMs[devUUID] notifyDeviceOff];
        firmLogSMs[devUUID] = nil;
    }
    else
    {
        //
        // Device is discovered and connected. But its service and characteristics
        // are not fully discovered yet.
        //

        connectedDevices[devUUID] = d;
        firmLogSMs[devUUID] = [[DxAppFirmLogStateMachine alloc] init];
        
        // This is to ensure the active device stored is the same device here
        activeDevices[devUUID] = d;

        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{
                                                                     @"Command":@"DeviceOn",
                                                                     @"DevInfo":@{
                                                                                    @"UUID":[d.devUUID UUIDString]
                                                                                 }
                                                                     }];
    }
}

// This member function is called when all profiles declared ready
// At this point, you are sure the device can function in all aspects
- (void) Device:(DataExchangerDevice*)d allProfilesReady:(BOOL)isReady
{
    if( isReady )
    {
        //
        // Device is fully ready
        //
        
        // Don't remove the next line
        device = (DataExchangerDevice*)d;
        
        // Uncomment next line to enable RSSI reading
        //[device enableRssiReadingWithNotification:YES howFrequent:1.0];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{
                                                                     @"Command":@"DeviceReady",
                                                                     @"DevInfo":@{
                                                                                    @"UUID":[d.devUUID UUIDString]
                                                                                 }
                                                                    }];
    }
}

// This function is called when RSSI reading is enabled.
- (void) Device:(BLEDevice*)d reportRssi:(NSNumber *)rssi
{
    //
    // Recieve new RSSI reading
    //
    
    //NSLog(@"INFO: reportRssi [%@]", rssi];
}

#pragma mark -
#pragma mark - DataExchangerProfileProtocol methods

// This member function is called when data is ready to be received.
- (void) Device:(BLEDevice *)d RxData:(NSData *)data
{
    //
    // Receive data from the device
    //
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                        object:nil
                                                      userInfo:@{@"Command":@"RxData",
                                                                 @"Data":data,
                                                                 @"DevInfo":@{
                                                                                @"UUID":[d.devUUID UUIDString]
                                                                             }
                                                                 }];
}

- (void) Device:(DataExchangerDevice*)d DidWriteWithError:(NSError*)error
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[d.devUUID UUIDString]];

    if( ![firmLogSMs[devUUID] processDidWriteWithError:error fromDevice:d] )
    {
        NSDictionary* usrInfo;
        
        if( error )
        {
            usrInfo = @{@"Command":@"DidSend",
                        @"DevInfo":@{
                                        @"UUID":[d.devUUID UUIDString]
                                    },
                        @"Error":error};
        }
        else
        {
            usrInfo = @{@"Command":@"DidSend",
                        @"DevInfo":@{
                                        @"UUID":[d.devUUID UUIDString]
                                    }};
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:usrInfo];
    }
}

- (void) Device:(DataExchangerDevice*)d Rx2Data:(NSData *)data
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[d.devUUID UUIDString]];

    if( ![firmLogSMs[devUUID] processRx2Data:data fromDevice:d] )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{@"Command":@"RxCmd",
                                                                     @"Data":data,
                                                                     @"DevInfo":@{
                                                                                     @"UUID":[d.devUUID UUIDString]
                                                                             	 }
                                                                 }];
    }
}

- (void) Device:(DataExchangerDevice *)d TxCredit:(UInt32)credits
{
    NSUUID* devUUID = [[NSUUID alloc] initWithUUIDString:[d.devUUID UUIDString]];

    if( ![firmLogSMs[devUUID] processTxCredit:credits fromDevice:d] )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{@"Command":@"TxCredit",
                                                                     @"Credits":[NSNumber numberWithUnsignedInt:credits],
                                                                     @"DevInfo":@{
                                                                             @"UUID":[d.devUUID UUIDString]
                                                                             }
                                                                     }];
    }
}

- (uint16_t) crc16CalcOnData:(uint8_t *)data length:(NSUInteger)len
{
    return [DxAppFirmLogStateMachine crc16CalcOnData:data length:len];
}

- (void) bleControllerOn
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{@"Command":@"BleOn"}
         ];
    });
}

- (void) bleControllerOff
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{@"Command":@"BleOff"}
         ];
    });
}

- (void) bleControllerReset
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BleNotify"
                                                            object:nil
                                                          userInfo:@{@"Command":@"BleReset"}
         ];
    });
}

@end
