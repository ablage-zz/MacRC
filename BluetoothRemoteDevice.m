//
//  BluetoothRemoteDevice.m
//  WiimoteFramework
//
//  Created by Marcel Erz on 8/5/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import "BluetoothRemoteDevice.h"

#import "Interfaces.h"
#import "Private.h"


@implementation BluetoothRemoteDevice

# pragma mark Init / Deinit

- (id)initWithDevice:(IOBluetoothDevice*)deviceValue AndDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct {
	self = [super init];
	if (self) {
		
		product = brproduct;
		
		device = deviceValue;
		[device retain];
		
		[self setDelegate:delegateValue];
		
		// Connect to device
		if ([self open] == NO) {
			[self errorCode:50 WhichWasFatal:YES WithText:@"Couldn't connect to the device."];
		}
	}
	return self;
}
- (void)dealloc {
	[self close];
	[device release];
	
	[super dealloc];
}


#pragma mark Open / Close connection

- (BOOL)open {
	int i = 0;
	IOReturn result;
	
	if (device == nil) {
		[self errorCode:51 WhichWasFatal:YES WithText:@"Device is not initialized."];
		return NO;
	}
	
	[self logCode:51 WithPriority:0 AndText:@"Opening connection to '%@'.", [device getName]];
	i = 0;
	while ((result = [device openConnection]) != kIOReturnSuccess){
		if (i >= 10){
			[self errorCode:52 WhichWasFatal:YES WithText:[NSString stringWithFormat:@"Could not open connection to device '%@'.", [device getName]]];
			return NO;
		}
		i++;
		usleep(10000);
	}
	
	disconnectNotification = [device registerForDisconnectNotification:self selector:@selector(disconnected:fromDevice:)];
	[disconnectNotification retain];
	
	i = 0;
	while ((result = [device performSDPQuery:nil]) != kIOReturnSuccess){
		if (i == 10){
			[self errorCode:53 WhichWasFatal:YES WithText:[NSString stringWithFormat:@"Could not request device information from '%@'.", [device getName]]];
			return NO;
		}
		i++;
		usleep(10000);
	}
	
	return YES;
}
- (BOOL)close {
	if (disconnectNotification != nil){
		[disconnectNotification unregister];
		[disconnectNotification release];
		disconnectNotification = nil;
	}
	
	if (device != nil) {
		[self logCode:52 WithPriority:0 AndText:@"Closing connection to '%@'.", [device getName]];
		
		if ([device isConnected]) {
			IOReturn result = kIOReturnSuccess;

			for(int i = 0; i < 10; i++) {
				result = [device closeConnection];
				
				if (result == kIOReturnSuccess) {
					break;
				}
				usleep(10000);
			}
			if (result != kIOReturnSuccess) {
				[self errorCode:54 WhichWasFatal:YES WithText:@"Could not disconnect from device '%@'.", [device getName]];
				return NO;
			}
		}
	}
	
	if ([self respondsToDelegateSelector:@selector(BluetoothRemoteDisconnected:)]) [delegate BluetoothRemoteDisconnected:self];
	
	return YES;
}


#pragma mark Open / Close channel

- (BOOL)openChannel:(int)channel With:(IOBluetoothL2CAPChannel*)l2CapChannel {
	[self logCode:53 WithPriority:0 AndText:@"Open channel."];

	int i = 0;
	IOReturn result;
	
	while ((result = [device openL2CAPChannelSync:&l2CapChannel withPSM:channel delegate:self]) != kIOReturnSuccess) {
		if (i == 10){
			[self errorCode:55 WhichWasFatal:YES WithText:[NSString stringWithFormat:@"Could not open channel %d.", channel]];
			l2CapChannel = nil;
			return NO;			
		}
		i++;
		usleep(10000);
	}	
	[l2CapChannel retain];
	
	return YES;
}
- (BOOL)closeChannel:(IOBluetoothL2CAPChannel*)l2CapChannel {
	if (l2CapChannel != nil) {
		[self logCode:54 WithPriority:0 AndText:@"Closing channel."];

		IOReturn result = kIOReturnSuccess;

		if ([device isConnected]) {
			[l2CapChannel setDelegate:nil];

			for(int i = 0; i < 10; i++) {
				result = [l2CapChannel closeChannel];

				if (result == kIOReturnSuccess) {
					break;
				}
				usleep(10000);
			}
			
		}
		[l2CapChannel release];

		if (result != kIOReturnSuccess) {
			[self errorCode:56 WhichWasFatal:YES WithText:@"Could not disconnect channel."];
			return NO;
		} else {
			return YES;	
		}
	}
	return YES;
}


#pragma mark Bluetooth notification

- (void)disconnected:(IOBluetoothUserNotification*)notification fromDevice:(IOBluetoothDevice*)deviceValue {
	if ([[deviceValue getAddressString] isEqualToString:[device getAddressString]]){
		[self close];
	}	
}


#pragma mark l2CapChannel delegates

- (void)l2capChannelClosed:(IOBluetoothL2CAPChannel*)l2capChannel {
	[self close];
	[self logCode:55 WithPriority:0 AndText:@"Channel closed."];
}
- (void)l2capChannelData:(IOBluetoothL2CAPChannel*)l2capChannel data:(void *)dataPointer length:(size_t)dataLength {
	if (![self isConnected]) {
		[self logCode:56 WithPriority:0 AndText:@"Received data (length %d) without connection.", dataLength];
		return;
	}

	[self logCode:57 WithPriority:0 AndText:@"Received data with length %d.", dataLength];

	if ([self respondsToSelector:@selector(receivedData:WithLength:)]) {
		[self receivedData:(uint8*)dataPointer WithLength:dataLength];
	}
}


#pragma mark Sending data

- (BOOL)sendData:(const uint8*)dataPointer WithLength:(size_t)dataLength OnChannel:(IOBluetoothL2CAPChannel*)channel {
	
	[self logCode:58 WithPriority:0 AndText:@"Sending data with length %d to channel %d.", dataLength, [channel getPSM]];

	IOReturn result;
	uint8 buffer[256];

	memset(buffer, 0, 256); // Clear buffer
	buffer[0] = 0x52; // Bluetooth header
	memcpy(buffer + 1, dataPointer, dataLength); // Data
	dataLength += 1; // Add the header

	usleep(10000); // Wait
	
	for (int i = 0; i < 10; i++) {
		// Send data
		result = [channel writeSync:buffer length:dataLength];		
		
		// Successful?
		if (result == kIOReturnSuccess) {
			break;
		}
		usleep(10000); // Wait
	}
	
	if (result != kIOReturnSuccess) {
		[self errorCode:57 WhichWasFatal:NO WithText:@"Could not send data."];
		return NO;
		
	} else {
		return YES;
	}
}


#pragma mark Read-only properties

- (BR_Product)product {
	return product;
}
- (NSString*)name {
	if (device == nil) {
		return [NSString stringWithFormat:@"Undefined"];
	} else {
		return [device getName];
	}
}
- (NSData*)address {
	if (device == nil) {
		NSData *temp = [NSData data];
		return temp;
	} else {
		return [NSData dataWithBytes:[device getAddress] length:6];
	}
}

- (BOOL)isConnected {
	if (device == nil) {
		return NO;
	} else {
		return [device isConnected];
	}
}

@end
