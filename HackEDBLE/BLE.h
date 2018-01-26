//
//  BLE.h
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-01-24.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
    #import <CoreBluetooth/CoreBluetooth.h>
#else
    #import <IOBluetooth/IOBluetooth.h>
#endif

@protocol BLEDelegate

@optional
-(void) bleDidConnect;
-(void) bleDidDisconnect;
-(void) bleDidUpdateRSSI:(NSNumber *) rssi;
-(void) bleHaveDataFor:(CBCharacteristic *)characteristic;
-(void) bleCentralManagerStateChanged:(CBManagerState) state;
-(void) bleServicesFound;
-(void) bleServiceCharacteristicsFound;
-(void) bleFindPeripheralsFinished;

@required

@end

@interface BLE : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    
}

@property (nonatomic,assign) id <BLEDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) CBPeripheral *activePeripheral;
@property (strong, nonatomic) CBCentralManager *CM;

+ (id)sharedInstance;

#pragma mark - Manage peripherals
-(int) findPeripherals:(int) timeout;
-(void) scanTimer:(NSTimer *)timer;
-(void) connectPeripheral:(CBPeripheral *)peripheral;
-(BOOL) isConnected;
-(void) printKnownPeripherals;
-(void) printPeripheralInfo:(CBPeripheral*)peripheral;
-(void) readRSSI;

#pragma mark - Find Services and Characteristics
-(void) findServicesFrom:(CBPeripheral *) peripheral services:(NSArray<CBUUID *> *)services;
-(void) findCharacteristicsFrom:(CBPeripheral *) peripheral characteristicUUIDs:(NSArray<CBUUID *> *)characteristicUUIDs;
-(CBService *) findServiceBy:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral;
-(CBCharacteristic *) findCharacteristicBy:(CBUUID *)UUID service:(CBService*)service;

#pragma mark - Read and Write
-(void) read;
-(void) write:(NSData *)data toUUID:(CBUUID *)uuid;
-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p;
-(void) enableReadNotification:(CBPeripheral *)p;

@end
