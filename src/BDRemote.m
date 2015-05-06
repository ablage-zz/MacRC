//
//  BDRemote.m
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 8/14/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import "BDRemote.h"
#import "Interfaces.h"


// Discoverable: Press Start and Enter


@implementation BDRemote

#pragma mark Init / Deinit

- (id)initWithDevice:(IOBluetoothDevice*)deviceValue AndDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct {
	self = [super initWithDevice:deviceValue AndDelegate:delegateValue AsProduct:brproduct];
	if (self) {
		[self logCode:150 WithPriority:0 AndText:@"Init BD-Remote"];

		outputChannel = nil;
		
		batteryLevel = -1;
		buttons[0] = BR_Button_BD_Released;
		buttons[1] = BR_Button_BD_Released;
		buttons[2] = BR_Button_BD_Released;
		buttons[3] = BR_Button_BD_Released;
	}
	return self;
}
- (void)dealloc {
	
	[super dealloc];
}


#pragma mark Static initializer

+ (id)bdremoteConnectTo:(IOBluetoothDevice*)deviceValue WithDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct {
	return [[[BDRemote alloc] initWithDevice:deviceValue AndDelegate:delegateValue AsProduct:brproduct] autorelease];	
}


#pragma mark Open / Close connection

- (BOOL)open {
	if ([super open]) {
		
		BOOL result = [self openChannel:19 With:outputChannel];
		
		if (!result) {
			[self close];
			return NO;
			
		} else {
			return YES;
		}
		
	} else {
		return NO;
	}
}
- (BOOL)close {
	BOOL result = [self closeChannel:outputChannel];
	result = result && [super close];
	return result;
}


#pragma mark Receiving data

- (void)receivedData:(uint8*)dataPointer WithLength:(size_t)dataLength {
	if (dataLength == 13) {
		
		int offset = 0;
		
		uint8 original_button = dataPointer[offset + 5];
		
		uint8 add_button1 = dataPointer[offset + 2];
		uint8 add_button2 = dataPointer[offset + 3];
		uint8 add_button3 = dataPointer[offset + 4];
		
		BOOL releasedButton = ((original_button == BR_Button_BD_Released) && (dataPointer[offset + 11] == 0));
		BOOL multipleButton = ((original_button == BR_Button_BD_Released) && (dataPointer[offset + 11] == 1));
		
		uint8 bdbattery = dataPointer[offset + 12];
		bdbattery = (uint8)((((float)(bdbattery % 6)) / 5.0) * 255); // Get it into 0-255
		
		// Buttons
		if (releasedButton) {
			
			// Released button
			
			if (buttons[0] != BR_Button_BD_Released) {
				if ([self respondsToDelegateSelector:@selector(BDRemoteButtonReleased)]) [delegate BDRemoteButtonReleased];
				if ([self respondsToDelegateSelector:@selector(BDRemoteButton:)]) [delegate BDRemoteButton:original_button];
			}
			
			buttons[0] = BR_Button_BD_Released;
			buttons[1] = BR_Button_BD_Released;
			buttons[2] = BR_Button_BD_Released;
			buttons[3] = BR_Button_BD_Released;
			
			
		} else if (multipleButton) {
			
			// Multiple buttons pressed
			
			buttons[0] = original_button;
			buttons[1] = add_button1;
			buttons[2] = add_button2;
			buttons[3] = add_button3;

			if ([self respondsToDelegateSelector:@selector(BDRemoteButtons:)]) [delegate BDRemoteButtons:buttons];
			
			
		} else {
			
			// Button pressed
			
			buttons[1] = BR_Button_BD_Released;
			buttons[2] = BR_Button_BD_Released;
			buttons[3] = BR_Button_BD_Released;
			
			if (buttons[0] != original_button) {
				buttons[0] = original_button;
								
				// Send to delegate
				if ([self respondsToDelegateSelector:@selector(BDRemoteButton:)]) [delegate BDRemoteButton:original_button];
			}
		}
		
		// Battery
		if (batteryLevel != bdbattery) {
			if ([self respondsToDelegateSelector:@selector(BDRemoteBatteryLevel:)]) [delegate BDRemoteBatteryLevel:bdbattery];
		}
		batteryLevel = bdbattery;
		
	} else {
		[self errorCode:150 WhichWasFatal:NO WithText:@"Received data package with not support length of %d.", dataLength];
	}
}


#pragma mark Properties

- (BR_PSButton)button:(int)sequence {
	if ((sequence < 0) || (sequence > 3)) {
		[self errorCode:152 WhichWasFatal:NO WithText:@"Unknown button number requested (%d).", sequence];
		return BR_Button_BD_Released;
		
	} else {
		return buttons[sequence];
	}
}
- (int)batteryLevel; {
	return batteryLevel;
}

@end
