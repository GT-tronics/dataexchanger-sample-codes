//
//  DxAppDataVC.m
//  DataExchangerApp
//
//  Created by Ming Leung on 2016-04-14.
//  Copyright © 2016 GT-Tronics HK Ltd. All rights reserved.
//

#import "DxAppDataVC.h"
#include <sys/time.h>

@interface DxAppDataVC ()
{
    CGFloat     _lastConstant;
    BOOL        _hexMode;
}

@property (nonatomic, strong)   IBOutlet    UITextView*         rxTxtView;
@property (nonatomic, strong)   IBOutlet    UITextField*        txTxtField;
@property (nonatomic, strong)   IBOutlet    NSLayoutConstraint* txTxtFieldBC;
@property (nonatomic, strong)               UIBarButtonItem*    bleBtn;
@property (nonatomic, strong)   IBOutlet    UIBarButtonItem*    dispModeBtn;

@end

@implementation DxAppDataVC

@synthesize rxTxtView;
@synthesize txTxtField;
@synthesize txTxtFieldBC;
@synthesize bleBtn;
@synthesize dispModeBtn;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(commandSent:)
                                                 name:@"CommandSent"
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
    dispModeBtn = self.navigationItem.rightBarButtonItem;
    
    rxTxtView.editable = YES;
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        rxTxtView.font = [UIFont fontWithName:@"Courier-Bold" size:17];
    }
    else
    {
        rxTxtView.font = [UIFont fontWithName:@"Courier-Bold" size:11];
    }
    rxTxtView.editable = NO;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if( ![[DxAppSC controller] isConnected] )
    {
        [self writeToTextField:@"\nSearching for device ...\n"];
        
        bleBtn.tintColor = [UIColor lightTextColor];

        // Do something here when the device is disconnected
        [[DxAppSC controller] startScan];
    }
    else
    {
        bleBtn.tintColor = [UIColor orangeColor];
    }
    
    txTxtField.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dismissKeyboard
{
    [txTxtField resignFirstResponder];
}

- (void) clearScreen
{
    rxTxtView.text = @"";
    
    [UIView setAnimationsEnabled:NO];
    [rxTxtView scrollRangeToVisible:NSMakeRange([rxTxtView.text length]-1, 1)];
    [UIView setAnimationsEnabled:YES];
}

- (void)keyboardWillShow:(NSNotification*)noti
{
    NSLog(@"[INFO] Editing begin");
    CGRect frame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    _lastConstant = txTxtFieldBC.constant;
    txTxtFieldBC.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    
    NSTimeInterval duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration
                     animations:^{
                         [self.view layoutIfNeeded];
                         [rxTxtView scrollRangeToVisible:NSMakeRange([rxTxtView.text length]-1, 1)];
                     }];
}

- (void)keyboardWillHide:(NSNotification*)noti
{
    NSLog(@"[INFO] Editing end");
    txTxtFieldBC.constant = _lastConstant;
    [self.view layoutIfNeeded];
}

#pragma mark -
#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //
    // Tx text field just hit return.
    //
    
    NSLog(@"[INFO]: %@", txTxtField.text);
    
    NSString* textStr = txTxtField.text;
    
    if( [dispModeBtn.title isEqualToString:@"Text"] )
    {
        // Send data to the device.
        __block NSString* newText;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if( [defaults boolForKey:@"dataChTerminator"] )
        {
            newText = [NSString stringWithFormat:@"%@\r\n",textStr];
        }
        else
        {
            newText = textStr;
        }
        
        newText = [newText stringByReplacingOccurrencesOfString:@"\\\\" withString:@"<DataExchanger\\>"];
        newText = [newText stringByReplacingOccurrencesOfString:@"\\r" withString:@"\r"];
        newText = [newText stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        newText = [newText stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
        newText = [newText stringByReplacingOccurrencesOfString:@"\\b" withString:@"\b"];
        
        NSString* matchStr = @"\\\\x([0-9ABCDEFabcdef]{2})";
        NSRegularExpression *regex;
        regex = [NSRegularExpression regularExpressionWithPattern:matchStr
                                                          options:0
                                                            error:nil];
        
        NSMutableIndexSet* indices = [NSMutableIndexSet indexSet];
        NSArray* matches = [regex matchesInString:newText
                                          options:NSMatchingReportCompletion
                                            range:NSMakeRange(0, newText.length)];
        for (NSTextCheckingResult* match in matches )
        {
            uint32_t val;
            NSScanner* scanner = [NSScanner scannerWithString:[newText substringWithRange:[match rangeAtIndex:1]]];
            BOOL success = [scanner scanHexInt:&val];
            if( !success )
            {
                [self writeToTextField:[NSString stringWithFormat:@">>> Invalid: %@\r\n", txTxtField.text]];
                return YES;
            }
            
            [indices addIndex:val];
        }
        
        [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSString* huntStr = [NSString stringWithFormat:@"\\x%02x", (UInt8)idx];
            NSString* replaceStr = [NSString stringWithFormat:@"%c", (UInt8)idx];
            newText = [newText stringByReplacingOccurrencesOfString:huntStr withString:replaceStr];
        }];
        
        newText = [newText stringByReplacingOccurrencesOfString:@"<DataExchanger\\>" withString:@"\\"];
        
#if 0
        NSString* dataStr = [NSString stringWithFormat:@"%@\r\n",newText];
        
        NSArray* dataStrs = [dataStr componentsSeparatedByString:@"\\1"];
        
        if( dataStrs.count > 0 )
        {
            [NSTimer scheduledTimerWithTimeInterval:0.5
                                             target:self
                                           selector:@selector(sendDataStr:)
                                           userInfo:dataStrs
                                            repeats:NO];
        }
        else
        {
            // Send data to the device.
            [[DxAppSC controller] sendData:[dataStr dataUsingEncoding:NSASCIIStringEncoding]];
        }
#endif
        textStr = newText;
    }
    
    NSData* data = [textStr dataUsingEncoding:NSASCIIStringEncoding];
    
    NSLog(@"[INFO] %@", [self convertDataToHexString:data]);
    
    if( [dispModeBtn.title isEqualToString:@"Hex"] )
    {
        NSMutableData* newData = [NSMutableData data];
        
        NSScanner* scanner = [NSScanner scannerWithString:txTxtField.text];
        while( ![scanner isAtEnd] )
        {
            uint32_t byte;
            if( [scanner scanHexInt:&byte] )
            {
                [newData appendBytes:&byte length:1];
                if( byte > 255 )
                {
                    goto ERR;
                }
            }
            else
            {
ERR:
                [self writeToTextField:[NSString stringWithFormat:@">>> Invalid: %@\r\n", txTxtField.text]];
                return YES;
            }
        }
        data = newData;

        // Display >>> send
        [self writeToTextField:[NSString stringWithFormat:@">>> Send: %@\r\n", [self convertDataToHexString:data]]];
    }
    
    [[DxAppSC controller] sendData:data];

    return YES;
}

- (void) sendDataStr:(NSTimer*)timer
{
    NSArray* dataStrs = [timer userInfo];
    NSString* dataStr = dataStrs[0];
        
    [[DxAppSC controller] sendData:[dataStr dataUsingEncoding:NSASCIIStringEncoding]];
    
    if( dataStrs.count > 1 )
    {
        [NSTimer scheduledTimerWithTimeInterval:0.0
                                         target:self
                                       selector:@selector(sendDataStr:)
                                       userInfo:[dataStrs subarrayWithRange:NSMakeRange(1, dataStrs.count-1)]
                                        repeats:NO];
    }
}


- (void) bleNotify:(NSNotification*)noti
{
    NSDictionary* usrInfo = noti.userInfo;
    NSString* cmd = usrInfo[@"Command"];
    if( [cmd isEqualToString:@"BleReset"] )
    {
        [self writeToTextField:@"\nBLE is reset ...\n"];
    }
    else if( [cmd isEqualToString:@"BleOn"] )
    {
        [self writeToTextField:@"\nBLE is on ...\n"];
    }
    else if( [cmd isEqualToString:@"BleOff"] )
    {
        [self writeToTextField:@"\nBLE is off ...\n"];
    }
    else if( [cmd isEqualToString:@"Start"] )
    {
        
    }
    else if( [cmd isEqualToString:@"DeviceOff"])
    {
        [self writeToTextField:@"\nSearching for device ...\n"];
        bleBtn.tintColor = [UIColor lightTextColor];
        [[DxAppSC controller] startScan];
    }
    else if( [cmd isEqualToString:@"DeviceOn"] )
    {
        [self writeToTextField:@"\nDevice found ...\n"];
    }
    else if( [cmd isEqualToString:@"DeviceReady"] )
    {
        [self writeToTextField:@"\nDevice connected!\n"];
        bleBtn.tintColor = [UIColor orangeColor];
    }
    else if( [cmd isEqualToString:@"RxData"] )
    {
        [self rxData:usrInfo[@"Data"]];
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

- (void) commandSent:(NSNotification*)noti
{
    [self writeToTextField:@">>> ATCmd Sent\r\n"];
}

- (NSString*) convertDataToHexString:(NSData*)data
{
    NSMutableString* newStr = [@"" mutableCopy];
    
    for( int i=0; i < data.length; i++ )
    {
        [newStr appendFormat:@"%02X ", ((uint8_t*)data.bytes)[i]];
    }
    
    return newStr;
}

- (void) rxData:(NSData *)data
{
    NSString* addedStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if( [dispModeBtn.title isEqualToString: @"Hex"] )
    {
        addedStr = [NSString stringWithFormat:@">>> Recv: %@\r\n", [self convertDataToHexString:data]];
    }
    
    [self writeToTextField:addedStr];
}

- (void) writeToTextField:(NSString*)str
{
    rxTxtView.text = [rxTxtView.text stringByAppendingString:str];
    
    [UIView setAnimationsEnabled:NO];
    [rxTxtView scrollRangeToVisible:NSMakeRange([rxTxtView.text length]-1, 1)];
    [UIView setAnimationsEnabled:YES];
}

- (IBAction) changeDisplayMode:(id)btn
{
    if( [dispModeBtn.title isEqualToString: @"Hex"] )
    {
        dispModeBtn.title = @"Text";
        [self writeToTextField:@"\r\n>>> Display Text Mode\r\n"];
    }
    else
    {
        dispModeBtn.title = @"Hex";
        [self writeToTextField:@"\r\n>>> Display Hex Mode\r\n"];
    }
}

@end
