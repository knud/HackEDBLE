//
//  BLEUtils.m
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-01-24.
//  Copyright © 2018 TechConficio. All rights reserved.
//

#import "BLEUtils.h"

@interface BLEUtils ()

@end

@implementation BLEUtils

+ (NSString *) CBUUIDToString:(CBUUID *) cbuuid;
{
  NSData *data = cbuuid.data;
  
  if ([data length] == 2)
  {
    const unsigned char *tokenBytes = [data bytes];
    return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
  }
  else if ([data length] == 16)
  {
    NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
    return [nsuuid UUIDString];
  }
  
  return [cbuuid description];
}


+ (UInt16) swapBytes:(UInt16) word;
{
  UInt16 temp = word << 8;
  temp |= (word >> 8);
  return temp;
}

+ (BOOL) equal:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
  if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
    return TRUE;
  else
    return FALSE;
}

+ (BOOL) equalCBUUIDs:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
  char b1[16];
  char b2[16];
  [UUID1.data getBytes:b1 length:UUID1.data.length];
  [UUID2.data getBytes:b2 length:UUID2.data.length];
  
  if (memcmp(b1, b2, UUID1.data.length) == 0)
    return true;
  else
    return false;
}

+ (NSString *) centralManagerStateToString:(int) state
{
  switch(state)
  {
    case CBManagerStateUnknown:
      return @"State unknown (CBManagerStateUnknown)";
    case CBManagerStateResetting:
      return @"State resetting (CBManagerStateResetting)";
    case CBManagerStateUnsupported:
      return @"State BLE unsupported (CBManagerStateUnsupported)";
    case CBManagerStateUnauthorized:
      return @"State unauthorized (CBManagerStateUnauthorized)";
    case CBManagerStatePoweredOff:
      return @"State BLE powered off (CBManagerStatePoweredOff)";
    case CBManagerStatePoweredOn:
      return @"State powered up and ready (CBManagerStatePoweredOn)";
    default:
      return @"State unknown";
  }
  
  return @"State unknown";
}


@end
