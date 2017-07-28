//
//  DataExchangerDevice.m
//  BLETestApp
//
//  Created by Ming Leung on 12-12-12.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 427 $
//


#import "DataExchangerDevice.h"
#import "DataExchangerProfile.h"

@interface DataExchangerDevice()

@property id<DataExchangerDeviceAppDelegateProtocol>    discoveryDelegate;
@property NSTimer*                                      discActTimer;

@end

@implementation DataExchangerDevice

@synthesize discoveryDelegate;
@synthesize proximityConnecting;
@synthesize minPowerLevel;
@synthesize discActTimer;
@synthesize discoveryActiveTimeout;

+ (DataExchangerDevice*) deviceWithAppDelegate:(id<DataExchangerDeviceAppDelegateProtocol>)delegate
{
    DataExchangerDevice* dev = [[DataExchangerDevice alloc] initWithAppDelegate:delegate];
    if( dev )
    {
        dev.discoveryDelegate = delegate;
    }
    return dev;
}

- (id) initWithAppDelegate:(id<DataExchangerDeviceAppDelegateProtocol>)delegate
{
    self = [super initWithAppDelegate:delegate];
    if( self == nil )
    {
        return nil;
    }
    
    proximityConnecting = NO;
    minPowerLevel = -127;
    discoveryActiveTimeout = 5.0;
    
    return self;
}

- (NSInteger) evaluateDeviceMatchingScoreBasedOnAdvertisingData:(NSDictionary*)adv rssi:(NSNumber*)rssi deviceUUID:(CBUUID*)uuid
{
    // Insert your code here to make decision whether you should connect or not.
    //
    // - The return value is the score used by the controller to determine
    //   which registered device to be used for the rest of the discovering process.
    //   The implementation of this method should use the data provided in the
    //   adversting dictionary, rssi, and discovered device name to determine
    //   the score. If the discovered device is absolutely not matched, return -1.
    //   If discovered device is matched but should be choosen based on BLEController
    //   policy, return 0. If discovered device is matched should be choosen based on
    //   user defined policy, return any number between 1 to 100. In this case,
    //   the highest score will be picked.
    //
    // - the example here check couple things:
    //   1/ make sure the advertisement contains DataExchanger Service UUID
    //   2/ rssi is larger -45dbM
    //
    // - For a list of advertisementData keys, see {CBAdvertisementDataLocalNameKey} and other similar
    //   constants in CBAdvertisementData.h
    //   - you can hold the Command key and move the mouse over {CBAdvertisementDataLocalNameKey} to see
    //     the dclaration.
    //
    
    NSArray* cuuids = [adv objectForKey:CBAdvertisementDataServiceUUIDsKey];
    BOOL matched = NO;
    
    NSLog(@"%@", [(CBUUID*)[cuuids firstObject] UUIDString]);
    for( CBUUID* cuuid in cuuids )
    {
        if( [cuuid isEqual:[CBUUID UUIDWithString:kDXServiceUUID]] )
        {
            matched = YES;
        }
    }
    
    if( matched == NO )
    {
        return -1;
    }
    
    NSLog(@"INFO: Peripheral[%@] discovered [RSSI=%@]", [uuid UUIDString], rssi);
    
    if ( [rssi floatValue] > 0 )    // filter some bogus value sometime received from iOS
    {
        return -1;
    }
    
    if( discoveryDelegate && !self.autoConnect )
    {
        NSDictionary* params = @{@"RSSI":rssi,
                                 @"CBUUID":uuid,
                                 @"ADV":adv};
        
        //NSLog(@"[INFO] Advertising: %@", adv);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [discoveryDelegate Device:self active:YES parameters:params];

            if( discActTimer )
            {
                [discActTimer invalidate];
                discActTimer = nil;
            }
            
            discActTimer = [NSTimer scheduledTimerWithTimeInterval:discoveryActiveTimeout
                                                            target:self
                                                          selector:@selector(discoveryActiveTimerExpired:)
                                                          userInfo:params
                                                           repeats:NO];
        });
        
    }
    
    // Proximity connecting
    // - reject if enabled and is below the minimum power level
    if( proximityConnecting && ([rssi floatValue] > 0 || [rssi floatValue] < minPowerLevel) )
    {
        return -1;
    }
    
    return 0;
}

- (void) discoveryActiveTimerExpired:(NSTimer*)timer
{
    discActTimer = nil;
    [discoveryDelegate Device:self active:NO parameters:timer.userInfo];
}


- (BOOL) sendData:(NSData*)data
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile sendTx:data];
        }
    }
    return NO;
}

- (BOOL) sendCmd:(NSData*)data withResponse:(BOOL)response
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile sendTx2:data withResponse:response];
        }
    }
    return NO;
}

- (BOOL) enableCmd:(BOOL)enabled
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile enableRx2Notification:enabled];
        }
    }
    return NO;
}

- (BOOL) enableTxCreditNotification:(BOOL)enabled
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile enableTxCreditNotification:enabled];
        }
    }
    return NO;
}

- (BOOL) enableChannelScrambler:(BOOL)enabled
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile enableChannelScrambler:enabled];
        }
    }
    return NO;
}

- (BOOL) readTxCredit
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile readTxCredit];
        }
    }
    
    return NO;
}

- (BOOL) writeTxCreditReportLoopCount:(uint32_t)count
{
    if( self.state != BLE_DEVICE_CONNECTED )
    {
        return NO;
    }
    
    NSSet* profiles = [self listRegisteredProfile];
    
    for( BLEProfile* profile in profiles )
    {
        if( [profile isMemberOfClass:[DataExchangerProfile class]] )
        {
            return [(DataExchangerProfile*)profile writeTxCreditReportLoopCount:count];
        }
    }
    
    return NO;
}

@end
