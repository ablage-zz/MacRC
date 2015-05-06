//
//  BluetoothRemoteDevice.h
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 8/5/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothL2CAPChannel.h>

#import "BRObject.h"


@interface BluetoothRemoteDevice : BRObject {
	IOBluetoothDevice *device;
	IOBluetoothUserNotification *disconnectNotification;

	BR_Product product;
}

# pragma mark Init
- (id)initWithDevice:(IOBluetoothDevice*)deviceValue AndDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct;

#pragma mark Open / Close connection
- (BOOL)open;
- (BOOL)close;

#pragma mark Open / Close channel
- (BOOL)openChannel:(int)channel With:(IOBluetoothL2CAPChannel*)l2CapChannel;
- (BOOL)closeChannel:(IOBluetoothL2CAPChannel*)l2CapChannel;

#pragma mark Sending data
- (BOOL)sendData:(const uint8*)dataPointer WithLength:(size_t)dataLength OnChannel:(IOBluetoothL2CAPChannel*)channel;

#pragma mark Read-only properties
- (BR_Product)product;
- (NSString*)name;
- (NSData*)address;
- (BOOL)isConnected;

@end

#pragma mark Abstract definition of BluetoothRemoteDevice
@interface BluetoothRemoteDevice(BluetoothRemoteDevice_Interface) 

- (void)receivedData:(uint8*)dataPointer WithLength:(size_t)dataLength;

@end
