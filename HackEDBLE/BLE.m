
//
//  BLE.m
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-01-24.
//  Copyright © 2018 TechConficio. All rights reserved.
//


#import "BLE.h"
#import "BLEUtils.h"

@implementation BLE

@synthesize delegate;
@synthesize CM;
@synthesize peripherals;
@synthesize advertisingData;
@synthesize activePeripheral;

static bool isConnected = false;
static int rssi = 0;

#pragma mark - BLE singleton

+ (id)sharedInstance {
  static BLE *myInstance = nil;
  @synchronized(self) {
    if (myInstance == nil)
      myInstance = [[self alloc] init];
  }
  return myInstance;
}

- (id)init {
  // Initialize stuff here
  self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

  return self;
}

#pragma mark - Manage peripherals

- (int) findPeripherals:(int) timeout
{
  if (self.CM.state != CBManagerStatePoweredOn)
  {
    NSLog(@"CoreBluetooth not correctly initialized !");
    NSLog(@"State = %ld (%@)\r\n", (long) self.CM.state, [BLEUtils centralManagerStateToString:self.CM.state]);
    return -1;
  }
  [self.peripherals removeAllObjects];
  [self.advertisingData removeAllObjects];
  
  [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
  
  // set up find peripherals that provide specified service(s)
  // TODO seems to be broken currently, so find any peripheral and then filter in the delegate
#if 0
  NSString *serviceUUIDStr = @BLE_NANO_SERVICE_UUID;
  NSLog(@"Scanning for service UUID %@",serviceUUIDStr);
  CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDStr];
  NSArray<CBUUID *> *services = [NSArray arrayWithObjects:serviceUUID, nil];
#if TARGET_OS_IPHONE
  [self.CM scanForPeripheralsWithServices:services options:nil];
#else
  [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif
#else
  [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif
  
  NSLog(@"scanForPeripheralsWithServices");
  
  return 0; // Started scanning OK !
}

- (void) scanTimer:(NSTimer *)timer
{
  [self.CM stopScan];
  NSLog(@"Stopped Scanning");
  NSLog(@"Known peripherals : %lu", (unsigned long)[self.peripherals count]);
  [self printKnownPeripherals];
  [[self delegate] bleFindPeripheralsFinished];
}

- (void) connectPeripheral:(CBPeripheral *)peripheral
{
  NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);
  
  self.activePeripheral = peripheral;
  self.activePeripheral.delegate = self;
  [self.CM connectPeripheral:self.activePeripheral
                     options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

-(void) disconnectPeripheral:(CBPeripheral *)peripheral
{
  if (self.activePeripheral == peripheral)
    [self.CM cancelPeripheralConnection:peripheral];
}

-(BOOL) isConnected
{
  return isConnected;
}

- (void) printKnownPeripherals
{
  NSLog(@"List of currently known peripherals :");
  
  for (int i = 0; i < self.peripherals.count; i++)
  {
    CBPeripheral *p = [self.peripherals objectAtIndex:i];
    
    if (p.identifier != NULL)
      NSLog(@"%d  |  %@", i, p.identifier.UUIDString);
    else
      NSLog(@"%d  |  NULL", i);
    
    [self printPeripheralInfo:p];
  }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
  NSLog(@"------------------------------------");
  NSLog(@"Peripheral Info :");
  
  if (peripheral.identifier != NULL)
    NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
  else
    NSLog(@"UUID : NULL");

  NSLog(@"Name : %@", peripheral.name);
  NSLog(@"-------------------------------------");
}

-(void) readRSSI
{
  [activePeripheral readRSSI];
}

#pragma mark - Find Services and Characteristics

// services can be nil, in which case all services are found
-(void) findServicesFrom:(CBPeripheral *) peripheral services:(NSArray<CBUUID *> *)services;
{
  NSLog(@"findServicesFrom: ");
  [peripheral discoverServices:services];
}

-(void) findCharacteristicsFrom:(CBPeripheral *) peripheral characteristicUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs;
{
  if (peripheral.services)
  {
    unsigned long numServices = [peripheral.services count];
    NSLog(@"findCharacteristicsFrom services count %lu",numServices);
  for (int i=0; i < peripheral.services.count; i++)
  {
    CBService *s = [peripheral.services objectAtIndex:i];
    [peripheral discoverCharacteristics:characteristicUUIDs forService:s];
  }
  }
}

-(CBService *) findServiceBy:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral;
{
  for(int i = 0; i < peripheral.services.count; i++)
  {
    CBService *s = [peripheral.services objectAtIndex:i];
    if ([BLEUtils equalCBUUIDs:s.UUID UUID2:UUID])
      return s;
  }
  return nil;
}

-(CBCharacteristic *) findCharacteristicBy:(CBUUID *)UUID service:(CBService*)service;
{
  for(int i=0; i < service.characteristics.count; i++)
  {
    CBCharacteristic *c = [service.characteristics objectAtIndex:i];
    if ([BLEUtils equalCBUUIDs:c.UUID UUID2:UUID]) return c;
  }
  return nil;
}

#pragma mark - Read and Write

-(void) read
{
  CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_NANO_SERVICE_UUID];
  CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID];
  
  [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
}

-(void) write:(NSData *)data toUUID:(CBUUID *)uuid
{
  CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_NANO_SERVICE_UUID];
  
  [self writeValue:uuid_service characteristicUUID:uuid p:activePeripheral data:data];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
  CBService *service = [self findServiceBy:serviceUUID peripheral:p];
  
  if (!service)
  {
    NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  CBCharacteristic *characteristic = [self findCharacteristicBy:characteristicUUID service:service];
  
  if (!characteristic)
  {
    NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:characteristicUUID],
          [BLEUtils CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p
{
  CBService *service = [self findServiceBy:serviceUUID peripheral:p];
  
  if (!service)
  {
    NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  CBCharacteristic *characteristic = [self findCharacteristicBy:characteristicUUID service:service];
  
  if (!characteristic)
  {
    NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:characteristicUUID],
          [BLEUtils CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  [p readValueForCharacteristic:characteristic];
}

-(void) enableReadNotification:(CBPeripheral *)p
{
  CBUUID *uuid_service = [CBUUID UUIDWithString:@BLE_NANO_SERVICE_UUID];
  CBUUID *uuid_char = [CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID];
  
  [self notification:uuid_service characteristicUUID:uuid_char p:p on:YES];
}

-(void) notification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
  CBService *service = [self findServiceBy:serviceUUID peripheral:p];
  
  if (!service)
  {
    NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  
  CBCharacteristic *characteristic = [self findCharacteristicBy:characteristicUUID service:service];
  
  if (!characteristic)
  {
    NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:characteristicUUID],
          [BLEUtils CBUUIDToString:serviceUUID],
          p.identifier.UUIDString);
    
    return;
  }
  NSLog(@"Setting notify on for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
        [BLEUtils CBUUIDToString:characteristicUUID],
        [BLEUtils CBUUIDToString:serviceUUID],
        p.identifier.UUIDString);

  [p setNotifyValue:on forCharacteristic:characteristic];
}


#pragma mark - CBCentralManagerDelegate monitor connections with peripherals

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
  if (peripheral.identifier != NULL)
    NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
  else
    NSLog(@"Connected to NULL successful");
  
  self.activePeripheral = peripheral;
  [[self delegate] bleDidConnect];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
  if (peripheral)
    NSLog(@"Disconnected from peripheral with UUID %@", peripheral.identifier.UUIDString);
  else
    NSLog(@"Disconnected from peripheral with unknown UUID ");
  if (error)
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
  [[self delegate] bleDidDisconnect];
  isConnected = false;
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
  if (peripheral)
    NSLog(@"Error connecting to peripheral with UUID %@", peripheral.identifier.UUIDString);
  else
    NSLog(@"Error connecting to peripheral with unknown UUID ");
  if (error)
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
  isConnected = false; // to be sure
}

#pragma mark - CBCentralManagerDelegate discovering and retrieving peripherals

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  NSLog(@"new peripheraal with RSSI %@",RSSI);
  if (!self.peripherals)
    self.peripherals = [[NSMutableArray alloc] initWithCapacity:1];
  if (!self.advertisingData)
    self.advertisingData = [[NSMutableArray alloc] initWithCapacity:1];
  for(int i = 0; i < self.peripherals.count; i++)
  {
    CBPeripheral *p = [self.peripherals objectAtIndex:i];
    
    if ((p.identifier == NULL) || (peripheral.identifier == NULL))
      continue;
    
    if ([BLEUtils equal:p.identifier UUID2:peripheral.identifier])
    {
      [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
      NSLog(@"Duplicate UUID found updating...");
      return;
    }
  }
  if (peripheral.name) {
    NSLog(@" ------- adding peripheral %@",peripheral.name);
    [self.peripherals addObject:peripheral];
    if (advertisingData)
      [self.advertisingData addObject:advertisementData];
    else
      NSLog(@"advertising data is nil");
  }
}

#pragma mark - CBCentralManagerDelegate monitoring changes to the central manager's state

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if TARGET_OS_IPHONE
  NSLog(@"Status of CoreBluetooth central manager changed %ld (%@)", (long)central.state, [BLEUtils centralManagerStateToString:central.state]);
  [[self delegate] bleCentralManagerStateChanged:central.state];
  
#else
  [self isLECapableHardware];
#endif
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{
#if TARGET_OS_IPHONE
  NSLog(@"CoreBluetooth central manager will restore state");
// TODO do anything here?
#else
  [self isLECapableHardware];
#endif
}

#pragma mark - CBPeripheralDelegate discovering services

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Services discovery unsuccessful!");
  }
  else
  {
    if (peripheral)
      NSLog(@"Discovered services for peripheral with name %@",peripheral.name);
    else
      NSLog(@"Discovered services for peripheral with unknown name");
    [[self delegate] bleServicesFound];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Discover included services for service unsuccessful!");
  }
  else
  {
    if (peripheral)
      NSLog(@"For peripheral named %@, discovered service with UUID %@",peripheral.name,[BLEUtils CBUUIDToString:service.UUID]);
    else
      NSLog(@"Discovered services for peripheral with unknown name");
    // TODO make a callback that includes the service and services?
    [[self delegate] bleServicesFound];
  }

}

#pragma mark - CBPeripheralDelegate discovering characteristics and characteristic descriptors

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Characteristic discovery unsuccessful!");
  }
  else
  {
    NSLog(@"Characteristics of service with UUID : %@ found",[BLEUtils CBUUIDToString:service.UUID]);
    if (service.characteristics)
    {
      unsigned long n = [service.characteristics count];
      NSLog(@"  %lu Characteristics",n);
    }
    [[self delegate] bleServiceCharacteristicsFound];
  }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Discovering descriptors for characteristic unsuccessful!");
  }
  else
  {
    NSLog(@"Descriptors for characteristic %@ found:",[BLEUtils CBUUIDToString:characteristic.UUID]);
    if (characteristic.descriptors)
    {
      unsigned long n = [characteristic.descriptors count];
      NSLog(@"  %lu Descriptors",n);
    }
// TODO add callback?
//    [[self delegate] ???];
  }
}


#pragma mark - CBPeripheralDelegate retrieving characteristic and characteristic descriptor values

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Retrieving value for characteristic unsuccessful!");
  }
  else
  {
    // Log any characteristic updates
//    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@ENVISAS_COMMAND_SPARE_CHARACTERISTIC_UUID]])
//      NSLog(@"didUpdateValueForCharacteristic for %@",@ENVISAS_COMMAND_SPARE_CHARACTERISTIC_UUID);
//
//    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@BLE_NANO_TX_CHAR_UUID]])
//      NSLog(@"didUpdateValueForCharacteristic for %@",@BLE_NANO_TX_CHAR_UUID);

    // We use this characteristic to exchange messages with the peripheral, so pass the update
    // along to the delegate
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@BLE_NANO_RX_CHAR_UUID]]) {
//      NSLog(@"didUpdateValueForCharacteristic for %@",@BLE_NANO_RX_CHAR_UUID);
      if (characteristic.value) {
//        NSLog(@"read value got %lu data",[characteristic.value length]);
        [[self delegate] bleHaveDataFor:characteristic];
      } else {
        NSLog(@"read value returned null characteristic.value");
      }
    } // if update for command messaging
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Retrieving value for descriptor unsuccessful!");
  }
  else
  {
    // TODO does nothing for now
  }
}

#pragma mark - CBPeripheralDelegate writing characteristic and characteristic descriptor values

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Writing value for characteristic unsuccessful!");
  }
  else
  {
    // TODO does nothing for now
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Writing value for descriptor unsuccessful!");
  }
  else
  {
    // TODO does nothing for now
  }
}

#pragma mark - CBPeripheralDelegate managing notifications for a characteristic's value

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
          [BLEUtils CBUUIDToString:characteristic.UUID],
          [BLEUtils CBUUIDToString:characteristic.service.UUID],
          peripheral.identifier.UUIDString);
  }
  else
  {
    NSLog(@"Updated notification state for characteristic with UUID %@ on service with  UUID %@ for peripheral with UUID %@\r\n",
          [BLEUtils CBUUIDToString:characteristic.UUID],
          [BLEUtils CBUUIDToString:characteristic.service.UUID],peripheral.name);
    if (characteristic.isNotifying)
      NSLog(@"characteristic is notifying");
    else
      NSLog(@"characteristic is NOT NOTIFYING");
  }
}


#pragma mark - CBPeripheralDelegate retrieving a peripheral's received signal strength indicator (RSSI) data

- (void)peripheral:(CBPeripheral *)peripheral
       didReadRSSI:(NSNumber *)RSSI
             error:(NSError *)error
{
  if (!isConnected)
    return;
  
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    NSLog(@"Error reading RSSI for peripheral with UUID %@",peripheral.name);
  } else {
    if (rssi != RSSI.intValue) {
      rssi = RSSI.intValue;
      [[self delegate] bleDidUpdateRSSI:RSSI];
    }
  }
}

#pragma mark - CBPeripheralDelegate monitoring changes to a peripheral's name or services

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
  if (peripheral)
    NSLog(@"The peripheral with UUID %@ updated its name to %@",peripheral.identifier.UUIDString,peripheral.name);
}

- (void)peripheral:(CBPeripheral *)peripheral
 didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
  if (peripheral) {
    NSLog(@"The peripheral %@ with UUID %@ invalidated services:",peripheral.name,peripheral.identifier.UUIDString);
    for (int s=0; s < invalidatedServices.count; s++) {
      CBService *serv = [invalidatedServices objectAtIndex:s];
      NSLog(@"\t%@",[BLEUtils CBUUIDToString:serv.UUID]);
    }
  }
}

#pragma mark - CBPeripheralDelegate instance methods

- (void)peripheral:(CBPeripheral *)peripheral didOpenL2CAPChannel:(CBL2CAPChannel *)channel error:(NSError *)error NS_AVAILABLE_IOS(11.0)
{
  if (error) {
    NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    if (peripheral)
      NSLog(@"Error opening L2CAP channel for peripheral %@ with UUID %@",peripheral.name,peripheral.identifier.UUIDString);
    else
      NSLog(@"Error opening L2CAP channel for peripheral ");
  } else {
    if (peripheral) {
      NSLog(@"Opened L2CAP channel for peripheral %@ with UUID %@",peripheral.name,peripheral.identifier.UUIDString);
      if (channel)
        NSLog(@"\tL2CAP channel peer has UUID %@",channel.peer.identifier.UUIDString);
    }
    else
      NSLog(@"Error opening L2CAP channel for peripheral ");
  }
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral
{
  if (peripheral)
    NSLog(@"Peripheral %@ with UUID %@ is ready to send write without response.",peripheral.name,peripheral.identifier.UUIDString);
  else
    NSLog(@"Peripheral is  ready to send write without response.");
}

@end
