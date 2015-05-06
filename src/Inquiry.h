//
//  Inquiry.h
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 7/31/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h> 
#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h> 

#import "BRObject.h"
#import "Types.h"
#import "BluetoothRemoteDevice.h"


@interface BluetoothRemoteInquiry : BRObject {
	IOBluetoothUserNotification *connectNotification;
	IOBluetoothDeviceInquiry *inquiry;

	NSMutableArray *autoConnectDevices;
	
	BR_Product filter;
}

#pragma mark Static Initializer
+ (BluetoothRemoteInquiry*)inquiryWithDelegate:(NSObject*)delegateValue;
+ (BluetoothRemoteInquiry*)inquiryWithDelegate:(NSObject*)delegateValue WithFilter:(BR_Product)filterValue;

#pragma mark Start / Cancel search
- (BOOL)startSearch;
- (BOOL)cancelSearch;

#pragma mark Auto-connect list functions
- (void)addAutoConnectDevice:(BluetoothRemoteDevice*)deviceValue;
- (void)addAutoConnectDeviceByAddress:(NSData*)address;
- (void)removeAutoConnectDevice:(BluetoothRemoteDevice*)deviceValue;
- (void)removeAutoConnectDeviceByAddress:(NSData*)address;
- (void)removeAllAutoConnectDevices;
	
# pragma mark Properties
- (void)setFilter:(BR_Product)value;
- (BR_Product)filter;

# pragma mark Read-only properties
- (BOOL)isSearching;

@end
