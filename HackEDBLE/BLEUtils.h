//
//  BLEUtils.h
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-11-13.
//  Copyright © 2018 TechConficio. All rights reserved.
//


#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface BLEUtils : NSObject

+ (NSString *) CBUUIDToString:(CBUUID *) cbuuid;
+ (UInt16) swapBytes:(UInt16) word;
+ (BOOL) equal:(NSUUID *) UUID1 UUID2:(NSUUID *) UUID2;
+ (BOOL) equalCBUUIDs:(CBUUID *) UUID1 UUID2:(CBUUID *) UUID2;
+ (NSString *) centralManagerStateToString:(int) state;

@end

