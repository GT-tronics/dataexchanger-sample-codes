//
//  DxAppViewController.m
//  DataExchangerApp
//
//  Created by Ming Leung on 12-12-25.
//  Copyright (c) 2012 GT-Tronics HK Ltd. All rights reserved.
//
//  $Rev: 416 $
//

#import "DxAppViewController.h"
#import "DxAppSC.h"
#include <sys/time.h>

@interface DxAppViewController ()

// BLE
@property (nonatomic, strong)   IBOutlet    UITextView*         rxText;
@property (nonatomic, strong)   IBOutlet    UITextField*        txText;
@property (nonatomic, strong)   IBOutlet    UILabel*            txLabel;

@end

@implementation DxAppViewController

@synthesize txText;
@synthesize rxText;
@synthesize txLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bleNotify:)
                                                 name:@"BleNotify"
                                               object:nil];
    
    if( ![[DxAppSC controller] isConnected] )
    {
        txText.hidden = YES;
        txLabel.hidden = YES;
        rxText.text = @"Searching for device ...";
        rxText.textAlignment = NSTextAlignmentCenter;
        
        // Do something here when the device is disconnected
        [[DxAppSC controller] startScan];
    }
    else
    {
        txText.hidden = NO;
        txLabel.hidden = NO;
        rxText.text = @"";
        rxText.textAlignment = NSTextAlignmentLeft;
    }

    NSLog(@"INFO: Main VC appeared");
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"INFO: Main VC disappeared");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissKeyboard
{
    [txText resignFirstResponder];
}

#pragma mark -
#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //
    // Tx text field just hit return.
    //
    
    //NSLog(@"INFO: %@", textField.text);
    
    // Send data to the device.
    NSString* cmdStr = [NSString stringWithFormat:@"%@\r\n",txText.text];
    [[DxAppSC controller] sendCmd:[cmdStr dataUsingEncoding:NSASCIIStringEncoding]];
    
    return YES;
}

- (void) bleNotify:(NSNotification*)noti
{
    NSDictionary* usrInfo = noti.userInfo;
    NSString* cmd = usrInfo[@"Command"];
    if( [cmd isEqualToString:@"Start"] )
    {
        
    }
    else if( [cmd isEqualToString:@"DeviceOff"])
    {
        txText.hidden = YES;
        txLabel.hidden = YES;
        rxText.text = @"Searching for device ...";
        rxText.textAlignment = NSTextAlignmentCenter;
        
        // Do something here when the device is disconnected
        [[DxAppSC controller] startScan];
    }
    else if( [cmd isEqualToString:@"DeviceOn"] )
    {
        rxText.text = @"Device Found";
    }
    else if( [cmd isEqualToString:@"DeviceReady"] )
    {
        txText.hidden = NO;
        txLabel.hidden = NO;
        rxText.text = @"";
        rxText.textAlignment = NSTextAlignmentLeft;
    }
    else if( [cmd isEqualToString:@"Rx"] )
    {
        [self rxData:usrInfo[@"Data"]];
    }
    else if( [cmd isEqualToString:@"DidSent"] )
    {
        id obj = usrInfo[@"Data"];
        if( [[obj class] isSubclassOfClass:[NSNull class]] )
        {
            NSLog(@"[INFO] packet sent");
        }
        else
        {
            NSLog(@"[INFO] packet sent with error [%@]", obj);
        }
    }
}

- (void) rxData:(NSData *)data
{
    struct timeval time;
    gettimeofday(&time, NULL);
    long totalSec = time.tv_sec;
    int mss = time.tv_usec / 1000;
    int ss = totalSec % 60;
    int mm = (totalSec / 60) % 60;
    //int hh = (totalSec / 3600) % 24;
    
    NSString* addedStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    rxText.text = [NSString stringWithFormat:@"%d::%d::%03d:%@\n%@", mm, ss, mss, addedStr, rxText.text];
}

@end
