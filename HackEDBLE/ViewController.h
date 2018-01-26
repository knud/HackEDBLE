//
//  ViewController.h
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-01-24.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>

@property (strong, nonatomic) BLE *ble;
@property (weak, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBService *service;

@property (weak, nonatomic) IBOutlet UIButton *connectToNanoButton;
@property (weak, nonatomic) IBOutlet UISwitch *ledSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *ledImage;

- (IBAction)findNano:(UIButton *)sender;
- (IBAction)ledSwitched:(id)sender;

@end

