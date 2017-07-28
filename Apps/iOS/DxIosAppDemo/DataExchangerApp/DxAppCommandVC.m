//
//  DxAppCommandVC.m
//  DataExchangerApp
//
//  Created by Ming Leung on 2016-04-14.
//  Copyright © 2016 GT-Tronics HK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DxAppCommandVC.h"
#include <sys/time.h>

@interface DxAppCommandVC () <UITextFieldDelegate>
{
    CGFloat     _lastConstant;
    BOOL        _active;
}

@property (nonatomic, strong)   IBOutlet    UITextView*         rspTxtView;
@property (nonatomic, strong)   IBOutlet    UITextField*        cmdTxtField;
@property (nonatomic, strong)   IBOutlet    NSLayoutConstraint* cmdTxtFieldBC;
@property (nonatomic, strong)               UIBarButtonItem*    bleBtn;
@property (nonatomic, strong)               NSTimer*            rptTimer;

@end

@implementation DxAppCommandVC

@synthesize rspTxtView;
@synthesize cmdTxtField;
@synthesize cmdTxtFieldBC;
@synthesize bleBtn;
@synthesize rptTimer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bleNotify:)
                                                 name:@"BleNotify"
                                               object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(clearScreen)];
    swipe.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipe];

    bleBtn = self.navigationItem.leftBarButtonItem;
 
    rspTxtView.editable = YES;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        rspTxtView.font = [UIFont fontWithName:@"Courier-Bold" size:17];
    }
    else
    {
        rspTxtView.font = [UIFont fontWithName:@"Courier-Bold" size:11];
    }
    rspTxtView.editable = NO;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if( ![[DxAppSC controller] isConnected] )
    {
        [self writeToTextField:@"\nSearching for device ...\n" suppressTimeStamp:YES];

        bleBtn.tintColor = [UIColor lightTextColor];

        // Do something here when the device is disconnected
        [[DxAppSC controller] startScan];
    }
    else
    {
        bleBtn.tintColor = [UIColor orangeColor];
    }
    
    cmdTxtField.text = @"AT+";
    _active = YES;
}

- (void) viewDidDisappear:(BOOL)animated
{
    _active = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dismissKeyboard
{
    [cmdTxtField resignFirstResponder];
}

- (void) clearScreen
{
    rspTxtView.text = @"";
    
    [UIView setAnimationsEnabled:NO];
    [rspTxtView scrollRangeToVisible:NSMakeRange([rspTxtView.text length]-1, 1)];
    [UIView setAnimationsEnabled:YES];
}


- (void)keyboardWillShow:(NSNotification*)noti
{
    if( !_active )
    {
        return;
    }
    
    NSLog(@"[INFO] Editing begin");
    CGRect frame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    _lastConstant = cmdTxtFieldBC.constant;
    cmdTxtFieldBC.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    
    NSTimeInterval duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration
                     animations:^{
                         [self.view layoutIfNeeded];
                         [rspTxtView scrollRangeToVisible:NSMakeRange([rspTxtView.text length]-1, 1)];
                     } completion:^(BOOL finished) {
                     }];
}

- (void)keyboardWillHide:(NSNotification*)noti
{
    if( !_active )
    {
        return;
    }
    
    NSLog(@"[INFO] Editing end");
    cmdTxtFieldBC.constant = _lastConstant;
    [self.view layoutIfNeeded];
}

#pragma mark -
#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //
    // Tx text field just hit return.
    //
    
    if( rptTimer )
    {
        [rptTimer invalidate];
        rptTimer = nil;
    }
    
    NSString* text = cmdTxtField.text;
    
    NSLog(@"[INFO] %@", text);
    
    // Filter out special actions
    NSRange idxRng = [text rangeOfString:@"AT"];
    if( idxRng.length > 0 && idxRng.location > 0 )
    {
        NSString* cmdStr = [text substringFromIndex:idxRng.location];
        NSString* metaStr = [text substringToIndex:idxRng.location];
        NSTimeInterval period = 10.0;
        NSScanner* scanner = [NSScanner scannerWithString:metaStr];
        [scanner scanDouble:&period];
        rptTimer = [NSTimer scheduledTimerWithTimeInterval:period
                                                    target:self
                                                  selector:@selector(processTextString:)
                                                  userInfo:cmdStr
                                                   repeats:period > 0 ?YES :NO];
        return YES;
    }

    [NSTimer scheduledTimerWithTimeInterval:0
                                     target:self
                                   selector:@selector(processTextString:)
                                   userInfo:text
                                    repeats:NO];
    return YES;
}

- (void) processTextString:(NSTimer*)timer
{
    if( ![DxAppSC controller].isConnected )
    {
        [rptTimer invalidate];
        rptTimer = nil;
        return;
    }
    
    NSString* text = [timer userInfo];
    NSString* newText = [text stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\r\n"];
    newText = [newText stringByReplacingOccurrencesOfString:@"\\n" withString:@"\r\n"];
    
    // Send data to the device.
    NSString* cmdStr = [NSString stringWithFormat:@"%@\r\n",newText];
    
    NSArray* cmdStrs = [cmdStr componentsSeparatedByString:@"\\1"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CommandSent" object:nil];
    
    if( cmdStrs.count > 0 )
    {
        [NSTimer scheduledTimerWithTimeInterval:0.0
                                         target:self
                                       selector:@selector(sendCmdStr:)
                                       userInfo:cmdStrs
                                        repeats:NO];
    }
    else
    {
        
        [[DxAppSC controller] sendCmd:[cmdStr dataUsingEncoding:NSASCIIStringEncoding]];
    }
}

- (void) sendCmdStr:(NSTimer*)timer
{
    NSArray* cmdStrs = [timer userInfo];
    NSString* cmdStr = cmdStrs[0];
    
    [[DxAppSC controller] sendCmd:[cmdStr dataUsingEncoding:NSASCIIStringEncoding]];
    
    if( cmdStrs.count > 1 )
    {
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(sendCmdStr:)
                                       userInfo:[cmdStrs subarrayWithRange:NSMakeRange(1, cmdStrs.count-1)]
                                        repeats:NO];
    }
}

- (void) bleNotify:(NSNotification*)noti
{
    NSDictionary* usrInfo = noti.userInfo;
    NSString* cmd = usrInfo[@"Command"];
    if( [cmd isEqualToString:@"BleReset"] )
    {
        [self writeToTextField:@"\nBLE is reset ...\n" suppressTimeStamp:YES];
    }
    else if( [cmd isEqualToString:@"BleOn"] )
    {
        [self writeToTextField:@"\nBLE is on ...\n" suppressTimeStamp:YES];
    }
    else if( [cmd isEqualToString:@"BleOff"] )
    {
        [self writeToTextField:@"\nBLE is off ...\n" suppressTimeStamp:YES];
    }
    else if( [cmd isEqualToString:@"Start"] )
    {
        
    }
    else if( [cmd isEqualToString:@"DeviceOff"])
    {
        [self writeToTextField:@"\nSearching for device ...\n" suppressTimeStamp:YES];
        bleBtn.tintColor = [UIColor lightTextColor];
        [[DxAppSC controller] startScan];
    }
    else if( [cmd isEqualToString:@"DeviceOn"] )
    {
        [self writeToTextField:@"\nDevice found ...\n" suppressTimeStamp:YES];
    }
    else if( [cmd isEqualToString:@"DeviceReady"] )
    {
        [self writeToTextField:@"\nDevice connected!\n" suppressTimeStamp:YES];
        bleBtn.tintColor = [UIColor orangeColor];
    }
    else if( [cmd isEqualToString:@"RxCmd"] )
    {
        [self rxCmdRsp:usrInfo[@"Data"]];
    }
    else if( [cmd isEqualToString:@"DidSent"] )
    {
        id obj = usrInfo[@"Data"];
        if( [[obj class] isSubclassOfClass:[NSNull class]] )
        {
            NSLog(@"[INFO] command sent");
        }
        else
        {
            NSLog(@"[INFO] command sent with error [%@]", obj);
        }
    }
}

- (void) rxCmdRsp:(NSData *)data
{
    NSString* addedStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    [self writeToTextField:addedStr suppressTimeStamp:NO];
}

- (void) writeToTextField:(NSString*)str  suppressTimeStamp:(BOOL)noTimeStamp
{
    struct timeval time;
    gettimeofday(&time, NULL);
    long totalSec = time.tv_sec;
    int mss = time.tv_usec / 1000;
    int ss = totalSec % 60;
    int mm = (totalSec / 60) % 60;
    //int hh = (totalSec / 3600) % 24;
    
    if( noTimeStamp )
    {
        rspTxtView.text = [rspTxtView.text stringByAppendingString:str];
    }
    else
    {
        //rspTxtView.editable = YES;
        rspTxtView.text = [rspTxtView.text stringByAppendingString:[NSString stringWithFormat:@"[%02d:%02d:%03d]%@", mm, ss, mss, str]];
        //rspTxtView.editable = NO;
    }
    
    [UIView setAnimationsEnabled:NO];
    [rspTxtView scrollRangeToVisible:NSMakeRange([rspTxtView.text length]-1, 1)];
    [UIView setAnimationsEnabled:YES];
}


@end
