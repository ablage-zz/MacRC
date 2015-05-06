//
//  BDRemote.h
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 8/14/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BluetoothRemoteDevice.h"
#import "Types.h"


@interface BDRemote : BluetoothRemoteDevice {
	IOBluetoothL2CAPChannel *outputChannel;

	BR_PSButton buttons[4];
	int batteryLevel;
}

#pragma mark Init
- (id)initWithDevice:(IOBluetoothDevice*)deviceValue AndDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct;

#pragma mark Static initializer
+ (id)bdremoteConnectTo:(IOBluetoothDevice*)deviceValue WithDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct;

#pragma mark Open / close connection
- (BOOL)open;
- (BOOL)close;

#pragma mark Receiving data
- (void)receivedData:(uint8*)data WithLength:(size_t)dataLength;

#pragma mark Properties
- (BR_PSButton)button:(int)sequence;
- (int)batteryLevel;

@end
