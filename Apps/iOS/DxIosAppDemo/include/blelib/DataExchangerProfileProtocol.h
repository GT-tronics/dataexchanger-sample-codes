//
//  DataExchangerProfileProtocol.h
//  blelib
//
//  Created by Ming Leung on 12-12-12.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 46 $
//
//  This protocol is used to receive data from Data Exchanger profile.
//

#import <Foundation/Foundation.h>

@protocol DataExchangerProfileProtocol <NSObject>

//
// Called when Data Exchanger profile has uart data to be received on port 1.
//
- (void) Device:(BLEDevice*)device RxData:(NSData*)data;

//
// Called when Data Exchanger profile did write with error
//
- (void) Device:(BLEDevice*)device DidWriteWithError:(NSError*)error;


//
// Called when Data Exchanger profile has uart data to be received on port 2
//
- (void) Device:(BLEDevice*)device Rx2Data:(NSData*)data;

//
// Called when Data Exchanger profile has updated Tx Credit (on port 1)
//
- (void) Device:(BLEDevice*)device TxCredit:(UInt32)credits;

@end
