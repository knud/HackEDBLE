//
//  ViewController.h
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-11-13.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>

@property (strong, nonatomic) BLE *ble;
@property (weak, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBService *service;

@property (weak, nonatomic) IBOutlet UIButton *connectToDongle;
@property (weak, nonatomic) IBOutlet UISwitch *ledSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *buttonImage;

- (IBAction)findDongle:(UIButton *)sender;
- (IBAction)ledSwitched:(id)sender;

@end

