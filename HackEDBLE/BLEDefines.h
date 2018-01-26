
//
//  BLEDefines.h
//  HackEDBLE
//
//  Created by Knud S Knudsen on 2018-01-24.
//  Copyright © 2018 TechConficio. All rights reserved.
//

// The BLE Nano uses the Nordic Semi UART service and characteristics.
//
// The base service is defined with the second 16 bits set to zero, which
// establishes the base UUID
//
// The Nordic UART Service
//const uint8_t UUID_BASE[] = {0x71, 0x3D, 0, 0, 0x50, 0x3E, 0x4C, 0x75, 0xBA, 0x94, 0x31, 0x48, 0xF1, 0x8D, 0x94, 0x1E};
//const uint8_t UUID_TX[]   = {0x71, 0x3D, 0, 3, 0x50, 0x3E, 0x4C, 0x75, 0xBA, 0x94, 0x31, 0x48, 0xF1, 0x8D, 0x94, 0x1E};
//const uint8_t UUID_RX[]   = {0x71, 0x3D, 0, 2, 0x50, 0x3E, 0x4C, 0x75, 0xBA, 0x94, 0x31, 0x48, 0xF1, 0x8D, 0x94, 0x1E};

// Base service
#define BLE_NANO_SERVICE_UUID "713D0000-503E-4C75-BA94-3148F18D941E"
// Tx service characteristic
#define BLE_NANO_TX_CHAR_UUID "713D0003-503E-4C75-BA94-3148F18D941E"
// Rx service characteristic
#define BLE_NANO_RX_CHAR_UUID "713D0002-503E-4C75-BA94-3148F18D941E"


