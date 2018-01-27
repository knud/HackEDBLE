//
//  ViewController.m
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-01-24.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
  bool connected;
  UIActivityIndicatorView *activityIndicator;
  UIBarButtonItem *refreshBarButton;
  UIBarButtonItem *busyBarButton;
  CBUUID *targetPeripheralService;
  bool scanningForPeripherals;
  CBPeripheral *bleNanoPeripheral;
  NSData *onMessage;
  NSData *offMessage;
}
@end

@implementation ViewController

@synthesize ble;
@synthesize peripheral;
@synthesize service;
@synthesize connectToNanoButton;
@synthesize ledSwitch;
@synthesize ledImage;

- (void)viewDidLoad {
  [super viewDidLoad];

  connected = false;
  self.connectToNanoButton.layer.cornerRadius = 4.0;
  self.connectToNanoButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

  [self.connectToNanoButton setTitle:@"Searching..." forState:UIControlStateDisabled];
  [self.connectToNanoButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
  
  [self.ledSwitch setOn:NO animated:YES];
  [self.ledSwitch setEnabled:NO];

  [self.ledImage setImage:[UIImage imageNamed:@"BulbOff"]];
  
  // Make a list of services that a peripheral has to have for us to care.
  // Only have the one to date...
  NSString *serviceUUIDStr = @BLE_NANO_SERVICE_UUID;
  targetPeripheralService = [CBUUID UUIDWithString:serviceUUIDStr];
  scanningForPeripherals = false;
  
  ble = [BLE sharedInstance];
  ble.delegate = self;
  
  uint8_t on[1] = {0x01};
  onMessage = [NSData dataWithBytes:on length:1];
  uint8_t off[1] = {0x00};
  offMessage = [NSData dataWithBytes:off length:1];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // TODO Dispose of any resources that can be recreated.
}

#pragma mark - UI actions

- (IBAction)findNano:(UIButton *)sender
{
  NSLog(@"findNano");

  if (connected && self.peripheral != nil)
    [self.ble disconnectPeripheral:self.peripheral];
  else
  {
    connected = false;
    self.peripheral = nil;
    [self.connectToNanoButton setEnabled:NO];
    [self.connectToNanoButton setBackgroundColor:[UIColor lightGrayColor]];
    [self scanForPeripherals];
  }
}

- (IBAction)ledSwitched:(UISwitch *)sender {
  if (self.ledSwitch.isOn) {
    NSLog(@"switched on");
    [self.ledImage setImage:[UIImage imageNamed:@"BulbOn"]];
    [self.ble write:onMessage toUUID:[CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID]];
  }
  else
  {
    NSLog(@"switched off");
    [self.ledImage setImage:[UIImage imageNamed:@"BulbOff"]];
    [self.ble write:offMessage toUUID:[CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID]];
  }
}

#pragma mark - BLE commands

- (void) scanForPeripherals
{
  scanningForPeripherals = true;
  if (ble.activePeripheral)
    if(ble.activePeripheral.state == CBPeripheralStateConnected)
    {
      [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
      return;
    }
  
  if (ble.peripherals)
    ble.peripherals = nil;
  
  // look for the Nano for 3 seconds
  [ble findPeripherals:3];
  
  [NSTimer scheduledTimerWithTimeInterval:(float)5.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
}

-(void) connectionTimer:(NSTimer *)timer
{
  NSLog(@"connectionTimer");
  if (!connected) {
    [self.connectToNanoButton setEnabled:YES];
    [self.connectToNanoButton setBackgroundColor:[UIColor redColor]];
  }
  // TODO turn off progress indicator
//  [activityIndicator stopAnimating];
}

#pragma mark - BLE delegate methods

-(void) bleCentralManagerStateChanged:(CBManagerState) state
{
  switch(state)
  {
    case CBManagerStateUnsupported:
      NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
      break;
    case CBManagerStateUnauthorized:
      NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
      break;
    case CBManagerStatePoweredOff:
      NSLog(@"Bluetooth is currently powered off.");
      [self.navigationItem.rightBarButtonItem setEnabled:false];
      break;
    case CBManagerStatePoweredOn:
      NSLog(@"Bluetooth is currently powered on.");
      [self.navigationItem.rightBarButtonItem setEnabled:true];
      break;
    case CBManagerStateUnknown:
      NSLog(@"Bluetooth manager unknown state.");
    default:
      break;
  }
}

-(void) bleFindPeripheralsFinished
{
  scanningForPeripherals = false;
  
  if (self.ble.peripherals) {
    for (int i = 0; i < [self.ble.peripherals count]; i++) {
      CBPeripheral *p = [self.ble.peripherals objectAtIndex:i];
      NSDictionary *ad = [self.ble.advertisingData objectAtIndex:i];
      NSString *deviceName = [ad valueForKey:CBAdvertisementDataLocalNameKey];
      if (deviceName)
      {
        if ([deviceName compare:@BLE_DEVICE_NAME] == NSOrderedSame) {
          NSLog(@"Got peripheral %@",deviceName);
          connected = true;
          [self.connectToNanoButton setEnabled:YES];
          
          [self.connectToNanoButton setBackgroundColor:[UIColor greenColor]];
          self.peripheral = p;
          [self.ble connectPeripheral:self.peripheral];
        }
      }
    }
  }
}

// When connected, this will be called
-(void) bleDidConnect
{
  NSLog(@"->Connected");

  // Find the service
  CBUUID *serviceUUID = [CBUUID UUIDWithString:@BLE_NANO_SERVICE_UUID];
  NSArray<CBUUID *> *serviceUUIDs = [NSArray arrayWithObjects:serviceUUID, nil];
  [self.ble findServicesFrom:self.peripheral services:serviceUUIDs];
}

- (void)bleDidDisconnect
{
  NSLog(@"->Disconnected");
  connected = false;
  [self.connectToNanoButton setEnabled:YES];

  [self.connectToNanoButton setBackgroundColor:[UIColor redColor]];
  [self.ledSwitch setOn:NO animated:YES];
  [self.ledSwitch setEnabled:NO];
  [self.ledImage setImage:[UIImage imageNamed:@"BulbOff"]];
  [self.ble write:offMessage toUUID:[CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID]];

}

// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
  NSLog(@"bleDidReceiveData got %d bytes", length);
  
}

-(void) bleServicesFound;
{
  NSLog(@"->bleServicesFound");
  if (self.ble.activePeripheral)
  {
    if (self.ble.activePeripheral.services)
    {
      unsigned long numServices = [self.ble.activePeripheral.services count];
      NSLog(@" %lu services found for %@",numServices,self.ble.activePeripheral.name);
      CBUUID *serviceUUID = [CBUUID UUIDWithString:@BLE_NANO_SERVICE_UUID];
      for (int i = 0; i < numServices; i++)
      {
        CBService *s = [self.ble.activePeripheral.services objectAtIndex:i];
        NSLog(@"\t service UUID %@",s.UUID.UUIDString);
        if ([s.UUID.UUIDString isEqual:serviceUUID.UUIDString])
        {
          self.service = s;
          CBUUID *txCharacteristicUUID = [CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID];
          CBUUID *rxCharacteristicUUID = [CBUUID UUIDWithString:@BLE_NANO_RX_CHAR_UUID];
          NSArray<CBUUID *> *characteristicUUIDs = [NSArray arrayWithObjects:txCharacteristicUUID,rxCharacteristicUUID, nil];
          NSLog(@"  ->findCharacteristicsFrom");
          [self.ble findCharacteristicsFrom:self.peripheral characteristicUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs];
          return;
        }
      }
    }
  }
}

-(void) bleServiceCharacteristicsFound
{
  NSLog(@"->bleServiceCharacteristicsFound");
  CBUUID *txCharacteristicUUID = [CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID];
  CBUUID *rxCharacteristicUUID = [CBUUID UUIDWithString:@BLE_NANO_RX_CHAR_UUID];
  for (int i=0; i < self.service.characteristics.count; i++)
  {
    CBCharacteristic *c = [service.characteristics objectAtIndex:i];
    NSLog(@"Found characteristic %@",c.UUID.UUIDString);
    if (c.properties & CBCharacteristicPropertyRead)
      printf("  has read\n");
    if (c.properties & CBCharacteristicPropertyWrite)
      printf("  has write\n");
    if (c.properties & CBCharacteristicPropertyWriteWithoutResponse)
      printf("  has write without response\n");
    if (c.properties & CBCharacteristicPropertyNotify)
      printf("  has notify\n");
    if (c.properties & CBCharacteristicPropertyIndicate)
      printf("  has indicate\n");
    if (c.properties & CBCharacteristicPropertyBroadcast)
      printf("  has broadcast\n");
    if (c.properties & CBCharacteristicPropertyExtendedProperties)
      printf("  has extended properties\n");
    if (c.properties & CBCharacteristicPropertyNotifyEncryptionRequired)
      printf("  has notify encryption requires\n");
    if (c.properties & CBCharacteristicPropertyIndicateEncryptionRequired)
      printf("  has indicate encryption required\n");
    if (c.properties & CBCharacteristicPropertyAuthenticatedSignedWrites)
      printf("  has authenticated signed writes\n");
    
    if ([c.UUID.UUIDString isEqual:rxCharacteristicUUID.UUIDString]) {
      // enable notification for this characteristic on the peripheral
      [self.ble.activePeripheral setNotifyValue:YES forCharacteristic:c];
    }
    if ([c.UUID.UUIDString isEqual:txCharacteristicUUID.UUIDString])
    {
      [self.ledSwitch setEnabled:YES];
    }
  }
}

@end
