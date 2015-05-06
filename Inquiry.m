//
//  Inquiry.m
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 7/31/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import "Inquiry.h"

#import "Interfaces.h"

#import "Wiimote.h"
#import "BDRemote.h"


@implementation BluetoothRemoteInquiry


#pragma mark Init / Deinit

- (id)init {
	self = [super init];
	if (self) {
		inquiry = nil;
		filter = BR_Product_Undefined;
		autoConnectDevices = [[[NSMutableArray alloc] init] retain];

		connectNotification = [IOBluetoothDevice registerForConnectNotifications:self selector:@selector(connected:withDevice:)];
		[connectNotification retain];
	}
	return self;
}
- (void)dealloc {
	if (autoConnectDevices != nil) {
		[autoConnectDevices removeAllObjects];
		[autoConnectDevices release];
		autoConnectDevices = nil;
	}
	
	if (connectNotification != nil) {
		[connectNotification unregister];
		[connectNotification release];
		connectNotification = nil;
	}

	if (inquiry != nil) {
		[self cancelSearch];
	}
	
	[super dealloc];
}


#pragma mark Static initializer

+ (BluetoothRemoteInquiry*)inquiryWithDelegate:(NSObject*)delegateValue {
	BluetoothRemoteInquiry *lInquiry = [[[BluetoothRemoteInquiry alloc] init] autorelease];
	[lInquiry setDelegate:delegateValue];
	return lInquiry;
}
+ (BluetoothRemoteInquiry*)inquiryWithDelegate:(NSObject*)delegateValue WithFilter:(BR_Product)filterValue {
	BluetoothRemoteInquiry *lInquiry = [[[BluetoothRemoteInquiry alloc] init] autorelease];
	[lInquiry setDelegate:delegateValue];
	[lInquiry setFilter:filterValue];
	return lInquiry;
}


#pragma mark Start / Cancel search

- (BOOL)startSearch {
	[self logCode:1 WithPriority:0 AndText:@"Start search."];
	
	if ([self isSearching]) {
		[self errorCode:1 WhichWasFatal:NO WithText:@"Search already in progress."];
		return NO;
	}
	if (delegate == nil) {
		[self errorCode:2 WhichWasFatal:YES WithText:@"No object to notify about new devices."];
		return NO;
	}
	
	inquiry = [IOBluetoothDeviceInquiry inquiryWithDelegate:self];
	[inquiry setInquiryLength:20];
	
	if (![self isSearching]) {
		[self errorCode:3 WhichWasFatal:YES WithText:@"Failed to start inquiry."];
		return NO;
	}
	
	[self logCode:2 WithPriority:0 AndText:@"Start searching..."];
	IOReturn result = [inquiry start];
	if (result != kIOReturnSuccess) {
		[self errorCode:4 WhichWasFatal:YES WithText:@"Start of search denied."];  
		
		[inquiry setDelegate:nil];
		[inquiry release];
		inquiry = nil;
		
		return NO;
	}
	
	return YES;
}
- (BOOL)cancelSearch {
	[self logCode:3 WithPriority:0 AndText:@"Cancel search."];

	if (![self isSearching]) {
		[self errorCode:5 WhichWasFatal:NO WithText:@"No search is running."];
		return NO;
	}
	
	IOReturn result = [inquiry stop];
	if (result != kIOReturnSuccess) {
		[self errorCode:6 WhichWasFatal:YES WithText:@"Couldn't stop search."];
		return NO;
	}
	
	[inquiry setDelegate:nil];
	[inquiry release];
	inquiry = nil;

	[self logCode:4 WithPriority:0 AndText:@"Search cancelled."];
	
	return YES;
}


#pragma mark Verifying devices for connecting

- (BOOL)verifyDevice:(IOBluetoothDevice*)device {
	BOOL allowedToConnect = true;
	NSString *productName = [device getName];

	if ((((filter & BR_Product_WiiRemote) == BR_Product_WiiRemote) || (filter == BR_Product_Undefined)) && ([productName isEqualToString:@"Nintendo RVL-CNT-01"])) {
		
		[self logCode:5 WithPriority:0 AndText:@"Found Wiimote '%@'.", productName];
		
		if ([self respondsToDelegateSelector:@selector(BluetoothRemoteShouldConnect:)]) allowedToConnect = [delegate BluetoothRemoteShouldConnect:device];

		if (allowedToConnect) {
			[self logCode:6 WithPriority:0 AndText:@"Connecting to device '%@'.", productName];
			Wiimote *wiimote = [Wiimote wiimoteConnectTo:device WithDelegate:delegate AsProduct:BR_Product_WiiRemote];
			
			if ([wiimote isConnected] == NO) {
				[self errorCode:9 WhichWasFatal:YES WithText:@"Could not connect to device %@.", productName];
				
				[wiimote release];
				
			} else {
				[self logCode:7 WithPriority:0 AndText:@"Connected to '%@'.", productName];
				
				if ([self respondsToDelegateSelector:@selector(BluetoothRemoteConnected:)]) [delegate BluetoothRemoteConnected:wiimote];
			}
			return YES;
		} else {
			[self logCode:8 WithPriority:0 AndText:@"Denied to connect to device '%@'.", productName];
			return NO;
		}
		
	} else if ((((filter & BR_Product_WiiBalanceBoard) == BR_Product_WiiBalanceBoard) || (filter == BR_Product_Undefined)) && ([productName isEqualToString:@"Nintendo RVL-WBC-01"])) {
		
		[self logCode:9 WithPriority:0 AndText:@"Found Wii-BalanceBoard '%@'.", productName];
		
		if ([self respondsToDelegateSelector:@selector(BluetoothRemoteShouldConnect:)]) allowedToConnect = [delegate BluetoothRemoteShouldConnect:device];
		
		if (allowedToConnect) {
			[self logCode:6 WithPriority:0 AndText:@"Connecting to device '%@'.", productName];
			Wiimote *wiimote = [Wiimote wiimoteConnectTo:device WithDelegate:delegate AsProduct:BR_Product_WiiBalanceBoard];
			
			if ([wiimote isConnected] == NO) {
				[self errorCode:9 WhichWasFatal:YES WithText:@"Could not connect to device %@.", productName];
				
				[wiimote release];
				
			} else {
				[self logCode:7 WithPriority:0 AndText:@"Connected to '%@'.", productName];
				
				if ([self respondsToDelegateSelector:@selector(BluetoothRemoteConnected:)]) [delegate BluetoothRemoteConnected:wiimote];
			}
			return YES;
		} else {
			[self logCode:8 WithPriority:0 AndText:@"Denied to connect to device '%@'.", productName];
			return NO;
		}
		
	} else if ((((filter & BR_Product_BDRemote) == BR_Product_BDRemote) || (filter == BR_Product_Undefined))) { // && ([productName isEqualToString:@"BD Remote Control"])
		
		[self logCode:10 WithPriority:0 AndText:@"Found BD-Remote '%@'.", productName];
		
		if ([self respondsToDelegateSelector:@selector(BluetoothRemoteShouldConnect:)]) allowedToConnect = [delegate BluetoothRemoteShouldConnect:device];
		
		if (allowedToConnect) {
			[self logCode:6 WithPriority:0 AndText:@"Connecting to device '%@'.", productName];
			BDRemote *bdremote = [BDRemote bdremoteConnectTo:device WithDelegate:delegate AsProduct:BR_Product_BDRemote];

			if ([bdremote isConnected] == NO) {
				[self errorCode:9 WhichWasFatal:YES WithText:@"Could not connect to device %@.", productName];
				
				[bdremote release];
				
			} else {
				[self logCode:7 WithPriority:0 AndText:@"Connected to '%@'.", productName];
				
				if ([self respondsToDelegateSelector:@selector(BluetoothRemoteConnected:)]) [delegate BluetoothRemoteConnected:bdremote];
			}
			return YES;
		} else {
			[self logCode:8 WithPriority:0 AndText:@"Denied to connect to device '%@'.", productName];
			return NO;
		}
		
	} else if (filter == BR_Product_None) {
		[self logCode:11 WithPriority:0 AndText:@"Device found '%@'.", productName];
		
	} else {
		[self logCode:12 WithPriority:0 AndText:@"Unknown or unwanted device '%@'.", productName];
	}

	return NO;
}


#pragma mark Auto-connect list functions

- (void)addAutoConnectDevice:(BluetoothRemoteDevice*)deviceValue {
	if (![deviceValue isConnected]) {
		[self errorCode:10 WhichWasFatal:NO WithText:@"Device is not connected. Cannot add it to the auto-connect list."];
	} else {
		NSData *data = [deviceValue address];
		if ([autoConnectDevices containsObject:data]) {
			[self errorCode:12 WhichWasFatal:NO WithText:@"Cannot add device to the auto-connect list. It exists already."];
		} else {
			[autoConnectDevices addObject:data];
		}
	}
}
- (void)addAutoConnectDeviceByAddress:(NSData*)address {
	if ([autoConnectDevices containsObject:address]) {
		[self errorCode:13 WhichWasFatal:NO WithText:@"Cannot add address to the auto-connect list. It exists already."];
	} else {
		[autoConnectDevices addObject:address];
	}
}
- (void)removeAutoConnectDevice:(BluetoothRemoteDevice*)deviceValue {
	if (![deviceValue isConnected]) {
		[self errorCode:11 WhichWasFatal:NO WithText:@"Device is not connected. Cannot remove it from the auto-connect list."];
	} else {
		NSData *data = [deviceValue address];
		if ([autoConnectDevices containsObject:data]) {
			[autoConnectDevices removeObject:data];
		} else {
			[self errorCode:14 WhichWasFatal:NO WithText:@"Cannot remove device from the auto-connect list. It doesn't exists in the list."];
		}
	}
}
- (void)removeAutoConnectDeviceByAddress:(NSData*)address {
	if ([autoConnectDevices containsObject:address]) {
		[autoConnectDevices removeObject:address];
	} else {
		[self errorCode:15 WhichWasFatal:NO WithText:@"Cannot remove device from the auto-connect list. It doesn't exists in the list."];
	}
}
- (void)removeAllAutoConnectDevices {
	[autoConnectDevices removeAllObjects];
}


#pragma mark Connect-notification

- (void)connected:(IOBluetoothUserNotification*)notification 
	   withDevice:(IOBluetoothDevice*)deviceValue {
	
	if ([autoConnectDevices containsObject:[NSData dataWithBytes:[deviceValue getAddress] length:6]]) {
		[self logCode:13 WithPriority:0 AndText:@"Device '%@' connected. Found in auto-connect list.", [deviceValue getName]];
		[self verifyDevice:deviceValue];
	} else {
		[self logCode:14 WithPriority:0 AndText:@"Device '%@' connected. Not found in auto-connect list.", [deviceValue getName]];
	}
}


#pragma mark Inquiry delegates

- (void) deviceInquiryStarted:(IOBluetoothDeviceInquiry*)sender {
	if ([self respondsToDelegateSelector:@selector(BluetoothSearchStarted)]) [delegate BluetoothSearchStarted];
}
- (void)deviceInquiryDeviceNameUpdated:(IOBluetoothDeviceInquiry*)sender
								device:(IOBluetoothDevice*)device 
					  devicesRemaining:(int)devicesRemaining {
	[self logCode:15 WithPriority:0 AndText:@"Device name updated: '%@'.", [device getName]];
	[self verifyDevice:device];
}
- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry*)sender 
						  device:(IOBluetoothDevice*)device {
	[self verifyDevice:device];
}
- (void)deviceInquiryComplete:(IOBluetoothDeviceInquiry*)sender 
						error:(IOReturn)error 
					  aborted:(BOOL)aborted {
	
	if (aborted) return ;
	
	if (error == 56) {
		[self errorCode:8 WhichWasFatal:YES WithText:@"Please turn on bluetooth."];
		
	} else if (error != kIOReturnSuccess) {
		[self logCode:18 WithPriority:0 AndText:@"Search was aborted by the system."];
		[self cancelSearch];
		
	} else {
		[self cancelSearch];
	}
	
	if ([self respondsToDelegateSelector:@selector(BluetoothSearchCompleted)]) [delegate BluetoothSearchCompleted];
	
	[self logCode:16 WithPriority:0 AndText:@"Search completed."];
}


# pragma mark Properties

- (void)setFilter:(BR_Product)value {
	filter = value;
	[self logCode:17 WithPriority:0 AndText:@"Filter set to %d.", (int)value];
}
- (BR_Product)filter {
	return filter;
}


# pragma mark Read-only properties

- (BOOL)isSearching {
	return (inquiry != nil);
}

@end




