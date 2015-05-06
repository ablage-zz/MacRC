//
//  Wiimote.h
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 7/31/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BluetoothRemoteDevice.h"
#import "Types.h"


@interface Wiimote : BluetoothRemoteDevice {
	IOBluetoothL2CAPChannel *inputChannel;
	IOBluetoothL2CAPChannel *outputChannel;
	
	BOOL led[4];
	BOOL vibration;
	BOOL irCamera;
	BR_WiiIrSensitivity irSensitivity;
	int batteryLevel;
	BR_WiiExtension extension;
	
	BR_WiiButtons WR_Buttons;
	BR_WiiAccelerometer WR_Accelerometer;
	BR_WiiIrCoordinates irData[4];
	BR_WiiIrDataFormat irFormat;
	
	// Values, which will be temp. saved
	// - Read request
	uint32 requestedAddress;
	size_t requestedLength;
	BR_WiiReadWriteDestination accessDestination;
	// - Accelerometer
	int accelerometerX;
}

+ (id)wiimoteConnectTo:(IOBluetoothDevice*)deviceValue WithDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct;


- (id)initWithDevice:(IOBluetoothDevice*)deviceValue AndDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct;
- (void)dealloc;

- (BOOL)open;
- (BOOL)close;

- (BOOL)setFirstLed:(BOOL)led1 SecondLed:(BOOL)led2 ThirdLed:(BOOL)led3 FourthLed:(BOOL)led4;
- (void)setLed:(int)nmbr Enabled:(BOOL)enabled;
- (BOOL)flushLed;

- (void)requestStatus;

- (void)setVibration:(BOOL)enabled;
- (BOOL)vibration;

- (void)setIrCamera:(BOOL)enabled;
- (BOOL)irCamera;

- (void)setIrCameraFormat:(BR_WiiIrDataFormat)format;
- (BR_WiiIrDataFormat)irCameraFormat;

- (int)batteryLevel;
- (BOOL)isExtensionConnected;
- (BR_WiiExtension)extension;

- (void)setIrCameraSensitivity:(BR_WiiIrSensitivity)sensitivity;
- (BR_WiiIrSensitivity)irCameraSensitivity;


- (BOOL)sendReport:(const uint8)reportNo WithData:(const uint8*)data AndLength:(size_t)dataLength;
- (BOOL)requestUpdate;


- (BOOL)writeData:(const uint8*)data At:(uint32)address AndLength:(size_t)dataLength To:(BR_WiiReadWriteDestination)destination;
- (BOOL)readDataAt:(uint32)address WithSize:(size_t)size From:(BR_WiiReadWriteDestination)destination;

- (void)receivedData:(uint8*)data WithLength:(size_t)dataLength;
- (void)receivedDataFromRam:(uint8*)dataPointer WithOffset:(uint32)offset AndLength:(size_t)dataLength; // (private)
- (void)receivedButtons:(uint8*)dataPointer WithOffset:(uint32)offset; // (private)
- (void)receivedAccelerometer:(uint8*)dataPointer WithOffset:(uint32)offset ForReport:(uint8)reportNo; // (private)
- (void)receivedExtensionData:(uint8*)dataPointer WithOffset:(uint32)offset AndSize:(size_t)size; // (private)
- (void)receivedIrData:(uint8*)dataPointer WithOffset:(uint32)offset AndSize:(size_t)size ForReport:(uint8)reportNo; // (private)
- (void)receivedStatus:(uint8*)dataPointer WithOffset:(uint32)offset; // (private)

- (uint8)getVibrationBitMask;
- (uint8)decryptByte:(uint8)byte;

@end



