//
//  Wiimote.m
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 7/31/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import "Wiimote.h"

#import "Interfaces.h"
#import "Private.h"

// Discoverable: Press 1 and 2


@implementation Wiimote

- (id)initWithDevice:(IOBluetoothDevice*)deviceValue AndDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct {
	self = [super initWithDevice:deviceValue AndDelegate:delegateValue AsProduct:brproduct];
	if (self) {
		product = BR_Product_WiiRemote;
		
		inputChannel = nil;
		outputChannel = nil;
		
		for(int i = 0; i < 4; i++) {
			led[i] = NO;
		}
		
		vibration = NO;
		irCamera = NO;
		irSensitivity = BR_WiiIrSensitivity_Normal;
		batteryLevel = -1;
		extension = BR_WiiExtension_NotConnected;
		
		WR_Buttons = (BR_WiiButtons)BR_Button_WR_Unpressed;
		
		WR_Accelerometer.X = 0;
		WR_Accelerometer.Y = 0;
		WR_Accelerometer.Z = 0;
		WR_Accelerometer.X_zero = 0;
		WR_Accelerometer.Y_zero = 0;
		WR_Accelerometer.Z_zero = 0;
		WR_Accelerometer.X_1G = 0;
		WR_Accelerometer.Y_1G = 0;
		WR_Accelerometer.Z_1G = 0;
		
		for(int i = 0; i < 4; i++) {
			irData[i].x = 0;
			irData[i].y = 0;
			irData[i].size = 0;
			irData[i].intensity = 0;
			irData[i].xMin = 0;
			irData[i].xMax = 0;
			irData[i].yMin = 0;
			irData[i].yMax = 0;
		}
		irFormat = BR_Ir_Basic;
		
		requestedAddress = -1;
		requestedLength = 0;
		accessDestination = BR_WiiReadWrite_EEPROM;
		
		accelerometerX = 0;
	}
	return self;
}
- (void)dealloc {
	
	[super dealloc];
}


+ (id)wiimoteConnectTo:(IOBluetoothDevice*)deviceValue WithDelegate:(NSObject*)delegateValue AsProduct:(BR_Product)brproduct {
	return [[[Wiimote alloc] initWithDevice:deviceValue AndDelegate:delegateValue AsProduct:brproduct] autorelease];
}


- (BOOL)open {
	if ([super open]) {
		
		BOOL result = [self openChannel:19 With:inputChannel];
		result = result && [self openChannel:17 With:outputChannel];
		
		if (!result) {
			[self close];
			return NO;
			
		} else {
			result = result && [self setFirstLed:NO SecondLed:NO ThirdLed:NO FourthLed:NO];
			
			[self requestStatus];
			
			// Request Accelerometer calibration data
			[self readDataAt:0x0020 WithSize:7 From:BR_WiiReadWrite_EEPROM]; 
			
			return result;
		}
		
	} else {
		return NO;
	}
}
- (BOOL)close {
	BOOL result = [self closeChannel:outputChannel];
	result = result && [self closeChannel:inputChannel];
	result = result && [super close];
	return result;
}


- (BOOL)setFirstLed:(BOOL)led1 SecondLed:(BOOL)led2 ThirdLed:(BOOL)led3 FourthLed:(BOOL)led4 {
	[self setLed:0 Enabled:led1];
	[self setLed:1 Enabled:led2];
	[self setLed:2 Enabled:led3];
	[self setLed:3 Enabled:led4];

	return [self flushLed];
}
- (void)setLed:(int)nmbr Enabled:(BOOL)enabled {
	if ((nmbr < 0) || (nmbr >=4)) {
		[self errorCode:100 WhichWasFatal:NO WithText:[NSString stringWithFormat:@"Led index %d is not possible.", nmbr]];
	} else {
		led[nmbr] = enabled;
	}
}
- (BOOL)flushLed {
	uint8 report = BR_Report_PlayerLed;
	uint8 data[] = {0x00};
	
	if (led[0]) data[0] |= 0x10;
	if (led[1]) data[0] |= 0x20;
	if (led[2]) data[0] |= 0x40;
	if (led[3]) data[0] |= 0x80;
	
	return [self sendReport:report WithData:data AndLength:1];
}

- (void)requestStatus {
	uint8 report = BR_Report_StatusInformationRequest;
	uint8 data[] = {0x00};

	[self sendReport:report WithData:data AndLength:1];	
}

- (void)setVibration:(BOOL)enabled {
	vibration = enabled;
	[self flushLed]; // Use LEDs to send vibration status
}
- (BOOL)vibration {
	return vibration;
}

- (void)setIrCamera:(BOOL)enabled {
	irCamera = enabled;
	
	uint8 camEnabled[] = {0x00};
	camEnabled[0] = (enabled) ? 0x04 : 0x00;
		
	[self sendReport:BR_Report_IrCameraEnable1 WithData:camEnabled AndLength:1];
	usleep(10000);
	[self sendReport:BR_Report_IrCameraEnable2 WithData:camEnabled AndLength:1];
	usleep(10000);

	if (enabled) {
		uint8 sensitivityBlock1[9];
		uint8 sensitivityBlock2[2];
		
		if (irSensitivity == BR_WiiIrSensitivity_Highest) {
			sensitivityBlock1[0] = 0x02;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x71;
			sensitivityBlock1[4] = 0x01;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0x72;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0x20;
			sensitivityBlock2[0] = 0x1f;
			sensitivityBlock2[1] = 0x03;
		}
		else if (irSensitivity == BR_WiiIrSensitivity_VeryHigh) {
			sensitivityBlock1[0] = 0x02;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x71;
			sensitivityBlock1[4] = 0x01;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0xc8;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0x36;
			sensitivityBlock2[0] = 0x35;
			sensitivityBlock2[1] = 0x03;
		}
		else if (irSensitivity == BR_WiiIrSensitivity_High) {
			sensitivityBlock1[0] = 0x00;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x00;
			sensitivityBlock1[4] = 0x00;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0x90;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0x41;
			sensitivityBlock2[0] = 0x40;
			sensitivityBlock2[1] = 0x00;
		}
		else if (irSensitivity == BR_WiiIrSensitivity_Normal) {
			sensitivityBlock1[0] = 0x02;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x71;
			sensitivityBlock1[4] = 0x01;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0xaa;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0x64;
			sensitivityBlock2[0] = 0x63;
			sensitivityBlock2[1] = 0x03;
		}
		else if (irSensitivity == BR_WiiIrSensitivity_Low) {
			sensitivityBlock1[0] = 0x02;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x71;
			sensitivityBlock1[4] = 0x01;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0x96;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0xb4;
			sensitivityBlock2[0] = 0xb3;
			sensitivityBlock2[1] = 0x04;
		}
		else if (irSensitivity == BR_WiiIrSensitivity_VeryLow) {
			sensitivityBlock1[0] = 0x00;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x00;
			sensitivityBlock1[4] = 0x00;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0x90;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0xc0;
			sensitivityBlock2[0] = 0x40;
			sensitivityBlock2[1] = 0x00;
		} else {
			sensitivityBlock1[0] = 0x02;
			sensitivityBlock1[1] = 0x00;
			sensitivityBlock1[2] = 0x00;
			sensitivityBlock1[3] = 0x71;
			sensitivityBlock1[4] = 0x01;
			sensitivityBlock1[5] = 0x00;
			sensitivityBlock1[6] = 0x64;
			sensitivityBlock1[7] = 0x00;
			sensitivityBlock1[8] = 0xfe;
			sensitivityBlock2[0] = 0xfd;
			sensitivityBlock2[1] = 0x05;
		}			

		uint8 byte1[] = {0x01};
		[self writeData:byte1 At:0xB00030 AndLength:1 To:BR_WiiReadWrite_Register];
		usleep(10000);

		[self writeData:sensitivityBlock1 At:0xb00000 AndLength:9 To:BR_WiiReadWrite_Register];
		usleep(10000);
		
		[self writeData:sensitivityBlock2 At:0xb0001a AndLength:2 To:BR_WiiReadWrite_Register];
		usleep(10000);

		uint8 byte2[] = {(uint8)irFormat};
		[self writeData:byte2 At:0xB00033 AndLength:1 To:BR_WiiReadWrite_Register];
		usleep(10000);
		
		uint8 byte3[] = {0x08};
		[self writeData:byte3 At:0xB00030 AndLength:1 To:BR_WiiReadWrite_Register];
		usleep(10000);
	}
}
- (BOOL)irCamera {
	return irCamera;
}

- (void)setIrCameraSensitivity:(BR_WiiIrSensitivity)sensitivity {
	if (sensitivity != irSensitivity) {
		irSensitivity = sensitivity;
		if ([self irCamera]) {
			[self setIrCamera:NO];
			[self setIrCamera:YES];
		}
	}
}
- (BR_WiiIrSensitivity)irCameraSensitivity {
	return irSensitivity;
}

- (void)setIrCameraFormat:(BR_WiiIrDataFormat)format {
	if (irFormat != format) {
		irFormat = format;
		if ([self irCamera]) {
			[self setIrCamera:NO];
			[self setIrCamera:YES];
		}
	}
}
- (BR_WiiIrDataFormat)irCameraFormat {
	return irFormat;
}

- (int)batteryLevel {
	return batteryLevel;
}
- (BOOL)isExtensionConnected {
	return ([self extension] != BR_WiiExtension_NotConnected);
}
- (BR_WiiExtension)extension {
	return extension;
}

- (BR_WiiButtons)wiiRemoteButtons {
	return WR_Buttons;
}
- (BR_WiiAccelerometer)accelerometer {
	return WR_Accelerometer;
}


- (BOOL)sendReport:(const uint8)reportNo WithData:(const uint8*)data AndLength:(size_t)dataLength {
	
	uint8 buffer[256];
	
	memset(buffer, 0, 256); // Get enough space for data
	buffer[0] = reportNo; // Report-ID
	memcpy(buffer + 1, data, dataLength); // Data
	dataLength += 1; // Add the header

	// Get Vibration (need to be send in each report)
	buffer[1] |= [self getVibrationBitMask];
	
	return [self sendData:buffer WithLength:dataLength OnChannel:outputChannel];
}
- (BOOL)requestUpdate {
	uint8 data[] = {0x04, 0x37}; //TODO: dynamic report
	return [self sendReport:(uint8)BR_Report_DataReportingMode WithData:data AndLength:2];
}

- (BOOL)writeData:(const uint8*)data At:(uint32)address AndLength:(size_t)dataLength To:(BR_WiiReadWriteDestination)destination {
	uint8 buffer[21];
	
	memset(buffer, 0, 21);
	
	if (CFByteOrderGetCurrent() == CFByteOrderBigEndian) {
		memcpy(buffer + 1, &address, 3); // Address
	} else {
		unsigned int temp = (((UInt32)CFSwapInt32HostToBig((SInt32)address)) << 8);
		memcpy(buffer + 1, &temp, 3); // Address
	}
	buffer[4] = (uint8)(dataLength & 0xFF); // Size
	memcpy(buffer + 5, data, dataLength); // Data
	
	buffer[0] |= (uint8)destination;
	
	return [self sendReport:BR_Report_WriteMemoryRegisterRequest WithData:buffer AndLength:dataLength + 5];
}
- (BOOL)readDataAt:(uint32)address WithSize:(size_t)size From:(BR_WiiReadWriteDestination)destination {
	uint8 buffer[6];
	
	if (requestedAddress != -1) {
		[self errorCode:101 WhichWasFatal:NO WithText:@"Still waiting for reply of previous reading at %d.", requestedAddress];
		return NO;
		
	} else {
		memset(buffer, 0, 6);
	
		if (CFByteOrderGetCurrent() == CFByteOrderBigEndian) {
			memcpy(buffer + 1, &address, 3); // Address
			memcpy(buffer + 4, &size, 2); // Size
		} else {
			unsigned int temp = (((UInt32)CFSwapInt32HostToBig((SInt32)address)) << 8); 
			memcpy(buffer + 1, &temp, 3); // Address
			
			temp = (UInt16)CFSwapInt16HostToBig((SInt16)size);
			memcpy(buffer + 4, &temp, 2); // Size
		}
		
		buffer[0] |= (uint8)destination;
		
		requestedAddress = address;
		requestedLength = size;
		accessDestination = destination;
		
		return [self sendReport:(uint8)BR_Report_ReadMemoryRegisterRequest WithData:buffer AndLength:6];
		
	}
}


- (void)receivedData:(uint8*)dataPointer WithLength:(size_t)dataLength {
	//controller status (expansion port and battery level data) - received when report 0x15 sent to Wiimote (getCurrentStatus:) or status of expansion port changes.
	if (dataPointer[1] == BR_Report_StatusInformation) {
		[self receivedStatus:dataPointer WithOffset:2];
		return ;
	}
	
	if (dataPointer[1] == BR_Report_ReadMemoryRegisterData) { // Received RAM data
		[self receivedButtons:dataPointer WithOffset:2];
		[self receivedDataFromRam:dataPointer WithOffset:4 AndLength:dataLength];
		return ;
	}
	if (dataPointer[1] == BR_Report_WriteMemoryRegisterData) { // Write data response
		return ;
	}
	
	if ((dataPointer[1] & 0xF0) == 0x30) {
		
		// Buttons
		if (dataPointer[1] != BR_DataReport_Extension21) {
			[self receivedButtons:dataPointer WithOffset:2];
		}
		
		// Acceleromator
		if ((dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3) || (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Ir12) || (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Extension16) || (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Ir10_Extension6) || (dataPointer[1] != BR_DataReport_1_Interleaved_CoreButtons2_Accelerometer1_Ir16) || (dataPointer[1] != BR_DataReport_2_Interleaved_CoreButtons2_Accelerometer1_Ir16)) {
			[self receivedAccelerometer:dataPointer WithOffset:4 ForReport:dataPointer[1]];
		}
		
		// Extension
		if (dataPointer[1] != BR_DataReport_CoreButtons2_Extension8) {
			[self receivedExtensionData:dataPointer WithOffset:4 AndSize:8];
		}
		else if (dataPointer[1] != BR_DataReport_CoreButtons2_Extension19) {
			[self receivedExtensionData:dataPointer WithOffset:2 AndSize:19];
		}
		else if (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Extension16) {
			[self receivedExtensionData:dataPointer WithOffset:7 AndSize:16];
		}
		else if (dataPointer[1] != BR_DataReport_CoreButtons2_Ir10_Extension9) {
			[self receivedExtensionData:dataPointer WithOffset:14 AndSize:9];
		}
		else if (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Ir10_Extension6) {
			[self receivedExtensionData:dataPointer WithOffset:17 AndSize:6];
		}
		else if (dataPointer[1] != BR_DataReport_Extension21) {
			[self receivedExtensionData:dataPointer WithOffset:2 AndSize:21];
		}
		
		// Ir-Data
		if (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Ir12) {
			[self receivedIrData:dataPointer WithOffset:7 AndSize:12 ForReport:dataPointer[1]];
		}
		else if (dataPointer[1] != BR_DataReport_CoreButtons2_Ir10_Extension9) {
			[self receivedIrData:dataPointer WithOffset:4 AndSize:10 ForReport:dataPointer[1]];
		}
		else if (dataPointer[1] != BR_DataReport_CoreButtons2_Accelerometer3_Ir10_Extension6) {
			[self receivedIrData:dataPointer WithOffset:7 AndSize:10 ForReport:dataPointer[1]];
		}
		else if ((dataPointer[1] != BR_DataReport_1_Interleaved_CoreButtons2_Accelerometer1_Ir16) || (dataPointer[1] != BR_DataReport_2_Interleaved_CoreButtons2_Accelerometer1_Ir16)) {
			[self receivedIrData:dataPointer WithOffset:5 AndSize:18 ForReport:dataPointer[1]];
		}
	}
}

- (void)receivedDataFromRam:(uint8*)dataPointer WithOffset:(uint32)offset AndLength:(size_t)dataLength {

	uint8 size = (dataPointer[offset] & 0xf0) >> 4;
	uint8 error = dataPointer[offset] & 0x0f;
	uint8 data[16];
	memset(data, 0, 16);
	memcpy(data, dataPointer + offset + 3, size);

	if (error == 7) {
		[self errorCode:102 WhichWasFatal:NO WithText:@"Read from read-only address %d.", requestedAddress];
		
	} else if (error == 8) {
		[self errorCode:103 WhichWasFatal:NO WithText:@"Address %d does not exist.", requestedAddress];
	}

	if (accessDestination == BR_WiiReadWrite_EEPROM) {

		// Accelerometer calibration
		if (requestedAddress == 0x0020) { 
			WR_Accelerometer.X_zero = data[0];
			WR_Accelerometer.Y_zero = data[1];
			WR_Accelerometer.Z_zero = data[2];
			WR_Accelerometer.X_1G = data[4];
			WR_Accelerometer.Y_1G = data[5];
			WR_Accelerometer.Z_1G = data[6];
			
		} else {
			[self errorCode:104 WhichWasFatal:NO WithText:@"Received unknown data from EEPROM."];
		}

	} else if (accessDestination == BR_WiiReadWrite_Register) {
		// Do nothing yet.
		
	} else {
		[self errorCode:105 WhichWasFatal:NO WithText:@"Received unknown type of data."];
	}
	
	// Send to delegate
	if ([self respondsToDelegateSelector:@selector(WiiRemoteDataFromRam:WithOffset:AndLength:)]) [delegate WiiRemoteDataFromRam:dataPointer WithOffset:offset AndLength:dataLength];
	
	// Reset to default
	requestedAddress = -1;
	requestedLength = 0;
}
- (void)receivedButtons:(uint8*)dataPointer WithOffset:(uint32)offset {
	BR_WiiButtons buttons;
	
	memcpy(&buttons, dataPointer, 2); // Data

	// Swap it, if needed
	if (CFByteOrderGetCurrent() != CFByteOrderBigEndian) {
		buttons =  (UInt16)CFSwapInt16HostToBig((SInt16)buttons);
	}
	
	BR_WiiButtons oldButtons = WR_Buttons;
	WR_Buttons = buttons;
	
	if (((oldButtons & BR_Button_WR_Left) | (buttons & BR_Button_WR_Left)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Left Pressed:((buttons & BR_Button_WR_Left) == BR_Button_WR_Left)];
		NSLog(@"BR_Button_WR_Left");
	}
	if (((oldButtons & BR_Button_WR_Right) | (buttons & BR_Button_WR_Right)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Right Pressed:((buttons & BR_Button_WR_Right) == BR_Button_WR_Right)];
		NSLog(@"BR_Button_WR_Right");
	}
	if (((oldButtons & BR_Button_WR_Down) | (buttons & BR_Button_WR_Down)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Down Pressed:((buttons & BR_Button_WR_Down) == BR_Button_WR_Down)];
		NSLog(@"BR_Button_WR_Down");
	}
	if (((oldButtons & BR_Button_WR_Up) | (buttons & BR_Button_WR_Up)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Up Pressed:((buttons & BR_Button_WR_Up) == BR_Button_WR_Up)];
		NSLog(@"BR_Button_WR_Up");
	}
	if (((oldButtons & BR_Button_WR_Plus) | (buttons & BR_Button_WR_Plus)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Plus Pressed:((buttons & BR_Button_WR_Plus) == BR_Button_WR_Plus)];
		NSLog(@"BR_Button_WR_Plus");
	}
	if (((oldButtons & BR_Button_WR_Two) | (buttons & BR_Button_WR_Two)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Two Pressed:((buttons & BR_Button_WR_Two) == BR_Button_WR_Two)];
		NSLog(@"BR_Button_WR_Two");
	}
	if (((oldButtons & BR_Button_WR_One) | (buttons & BR_Button_WR_One)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:(unsigned int)BR_Button_WR_One Pressed:((buttons & BR_Button_WR_One) == BR_Button_WR_One)];
		NSLog(@"BR_Button_WR_One");
	}
	if (((oldButtons & BR_Button_WR_B) | (buttons & BR_Button_WR_B)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_B Pressed:((buttons & BR_Button_WR_B) == BR_Button_WR_B)];
		NSLog(@"BR_Button_WR_B");
	}
	if (((oldButtons & BR_Button_WR_A) | (buttons & BR_Button_WR_A)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_A Pressed:((buttons & BR_Button_WR_A) == BR_Button_WR_A)];
		NSLog(@"BR_Button_WR_A");
	}
	if (((oldButtons & BR_Button_WR_Minus) | (buttons & BR_Button_WR_Minus)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Minus Pressed:((buttons & BR_Button_WR_Minus) == BR_Button_WR_Minus)];
		NSLog(@"BR_Button_WR_Minus");
	}
	if (((oldButtons & BR_Button_WR_Home) | (buttons & BR_Button_WR_Home)) != 0) {
		if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteButton:BR_Button_WR_Home Pressed:((buttons & BR_Button_WR_Home) == BR_Button_WR_Home)];
		NSLog(@"BR_Button_WR_Home");
	}
}
- (void)receivedAccelerometer:(uint8*)dataPointer WithOffset:(uint32)offset ForReport:(uint8)reportNo {
	if (reportNo == 0x3e) {
		accelerometerX = ((int)dataPointer[offset]);
		NSLog(@"Accel: x=%d", accelerometerX);
		
	} else if (reportNo == 0x3f) {
		// Resolve Z-axis
		BR_WiiButtons buttons = [self wiiRemoteButtons];
		uint8 z_temp = (buttons & 96) >> 5;
		z_temp |= (buttons & (96 << 8)) >> 11;
		z_temp |= (buttons & 96) >> 1;
		z_temp |= (buttons & (96 << 8)) >> 7;
		
		int y = ((int)dataPointer[offset]);
		int z = z_temp;
		
		NSLog(@"Accel: x=%d y=%d z=%d", accelerometerX, y, z);

		BOOL changed = ((WR_Accelerometer.X != accelerometerX) || (WR_Accelerometer.Y != y) || (WR_Accelerometer.Z != z));
		
		WR_Accelerometer.X = accelerometerX;
		WR_Accelerometer.Y = y;
		WR_Accelerometer.Z = z;
		
		if (changed) {
			// Send to delegate
			if ([self respondsToDelegateSelector:@selector(WiiRemoteButton:Pressed:)]) [delegate WiiRemoteAccelerometer:WR_Accelerometer];
		}

		accelerometerX = 0;
		
	} else {
		int x = ((int)dataPointer[offset]);
		int y = ((int)dataPointer[offset + 1]);
		int z = ((int)dataPointer[offset + 2]);

		NSLog(@"Accel: x=%d y=%d z=%d", x, y, z);
		
		BOOL changed = ((WR_Accelerometer.X != x) || (WR_Accelerometer.Y != y) || (WR_Accelerometer.Z != z));

		WR_Accelerometer.X = x;
		WR_Accelerometer.Y = y;
		WR_Accelerometer.Z = z;
		
		if (changed) {
			// Send to delegate
			if ([self respondsToDelegateSelector:@selector(WiiRemoteAccelerometer:)]) [delegate WiiRemoteAccelerometer:WR_Accelerometer];
		}
	}
}
- (void)receivedExtensionData:(uint8*)dataPointer WithOffset:(uint32)offset AndSize:(size_t)size {
	BR_WiiExtension attachedExtension;
	//TODO: Need to be implemented

	BOOL changed = (extension != attachedExtension);
	
	extension = attachedExtension;
	
	NSLog(@"Extension: %d", (int)attachedExtension);

	if (changed) {
		// Send to delegate
		if ([self respondsToDelegateSelector:@selector(WiiRemoteExtension:attachedExtension:)]) [delegate WiiRemoteExtension:attachedExtension];
	}
}
- (void)receivedIrData:(uint8*)dataPointer WithOffset:(uint32)offset AndSize:(size_t)size ForReport:(uint8)reportNo {
	BR_WiiIrCoordinates lirData[4];

	if (size == 10) {
		lirData[0].x = (int)dataPointer[offset + 0] | ((int)(dataPointer[offset + 2] & 48) << 4);
		lirData[0].y = (int)dataPointer[offset + 1] | ((int)(dataPointer[offset + 2] & 192) << 2);
		lirData[0].size = 8;
		lirData[0].intensity = 128;
		lirData[0].xMin = 0;
		lirData[0].xMax = 127;
		lirData[0].yMin = 0;
		lirData[0].yMax = 127;
		
		lirData[1].x = (int)dataPointer[offset + 3] | ((int)(dataPointer[offset + 2] & 3) << 8);
		lirData[1].y = (int)dataPointer[offset + 4] | ((int)(dataPointer[offset + 2] & 12) << 6);
		lirData[1].size = 8;
		lirData[1].intensity = 128;
		lirData[1].xMin = 0;
		lirData[1].xMax = 127;
		lirData[1].yMin = 0;
		lirData[1].yMax = 127;
		
		lirData[2].x = (int)dataPointer[offset + 5] | ((int)(dataPointer[offset + 7] & 48) << 4);
		lirData[2].y = (int)dataPointer[offset + 6] | ((int)(dataPointer[offset + 7] & 192) << 2);
		lirData[2].size = 8;
		lirData[2].intensity = 128;
		lirData[2].xMin = 0;
		lirData[2].xMax = 127;
		lirData[2].yMin = 0;
		lirData[2].yMax = 127;
		
		lirData[3].x = (int)dataPointer[offset + 7] | ((int)(dataPointer[offset + 7] & 3) << 8);
		lirData[3].y = (int)dataPointer[offset + 8] | ((int)(dataPointer[offset + 7] & 12) << 6);
		lirData[3].size = 8;
		lirData[3].intensity = 128;
		lirData[3].xMin = 0;
		lirData[3].xMax = 127;
		lirData[3].yMin = 0;
		lirData[3].yMax = 127;
		
		irData[0] = lirData[0];
		irData[1] = lirData[1];
		irData[2] = lirData[2];
		irData[3] = lirData[3];
		
		// Send to delegate
		if ([self respondsToDelegateSelector:@selector(WiiRemoteIrValues:)]) [delegate WiiRemoteIrValues:irData];
		
		//TODO: recalculate position on screen

	} else if (size == 12) {
		lirData[0].x = (int)dataPointer[offset + 0] | ((int)(dataPointer[offset + 2] & 48) << 4);
		lirData[0].y = (int)dataPointer[offset + 1] | ((int)(dataPointer[offset + 2] & 192) << 2);
		lirData[0].size = dataPointer[offset + 2] & 15;
		lirData[0].intensity = 128;
		lirData[0].xMin = 0;
		lirData[0].xMax = 127;
		lirData[0].yMin = 0;
		lirData[0].yMax = 127;
		
		lirData[1].x = (int)dataPointer[offset + 3] | ((int)(dataPointer[offset + 5] & 48) << 4);
		lirData[1].y = (int)dataPointer[offset + 4] | ((int)(dataPointer[offset + 5] & 192) << 2);
		lirData[1].size = dataPointer[offset + 5] & 15;
		lirData[1].intensity = 128;
		lirData[1].xMin = 0;
		lirData[1].xMax = 127;
		lirData[1].yMin = 0;
		lirData[1].yMax = 127;
		
		lirData[2].x = (int)dataPointer[offset + 6] | ((int)(dataPointer[offset + 8] & 48) << 4);
		lirData[2].y = (int)dataPointer[offset + 7] | ((int)(dataPointer[offset + 8] & 192) << 2);
		lirData[2].size = dataPointer[offset + 8] & 15;
		lirData[2].intensity = 128;
		lirData[2].xMin = 0;
		lirData[2].xMax = 127;
		lirData[2].yMin = 0;
		lirData[2].yMax = 127;
		
		lirData[3].x = (int)dataPointer[offset + 9] | ((int)(dataPointer[offset + 11] & 48) << 4);
		lirData[3].y = (int)dataPointer[offset + 10] | ((int)(dataPointer[offset + 11] & 192) << 2);
		lirData[3].size = dataPointer[offset + 11] & 15;
		lirData[3].intensity = 128;
		lirData[3].xMin = 0;
		lirData[3].xMax = 127;
		lirData[3].yMin = 0;
		lirData[3].yMax = 127;
		
		irData[0] = lirData[0];
		irData[1] = lirData[1];
		irData[2] = lirData[2];
		irData[3] = lirData[3];
		
		// Send to delegate
		if ([self respondsToDelegateSelector:@selector(WiiRemoteIrValues:)]) [delegate WiiRemoteIrValues:irData];
		
		//TODO: recalculate position on screen

	} else if (size == 18) {
		
		int i = 0;
		
		if (reportNo == BR_DataReport_2_Interleaved_CoreButtons2_Accelerometer1_Ir16) {
			i = 2;
		}
		
		lirData[0 + i].x = (int)dataPointer[offset + 0] | ((int)(dataPointer[offset + 2] & 48) << 4);
		lirData[0 + i].y = (int)dataPointer[offset + 1] | ((int)(dataPointer[offset + 2] & 192) << 2);
		lirData[0 + i].size = dataPointer[offset + 2] & 15;
		lirData[0 + i].xMin = (int)(dataPointer[offset + 3] & 128);
		lirData[0 + i].yMin = (int)(dataPointer[offset + 4] & 128);
		lirData[0 + i].xMax = (int)(dataPointer[offset + 5] & 128);
		lirData[0 + i].yMax = (int)(dataPointer[offset + 6] & 128);
		lirData[0 + i].intensity = (int)dataPointer[offset + 8];
		
		lirData[1 + i].x = (int)dataPointer[offset + 9] | ((int)(dataPointer[offset + 2] & 48) << 4);
		lirData[1 + i].y = (int)dataPointer[offset + 10] | ((int)(dataPointer[offset + 2] & 192) << 2);
		lirData[1 + i].size = dataPointer[offset + 11] & 15;
		lirData[1 + i].xMin = (int)(dataPointer[offset + 12] & 128);
		lirData[1 + i].yMin = (int)(dataPointer[offset + 13] & 128);
		lirData[1 + i].xMax = (int)(dataPointer[offset + 14] & 128);
		lirData[1 + i].yMax = (int)(dataPointer[offset + 15] & 128);
		lirData[1 + i].intensity = (int)dataPointer[offset + 17];
		
		irData[0 + i] = lirData[0 + i];
		irData[1 + i] = lirData[1 + i];
		
		if (reportNo == BR_DataReport_2_Interleaved_CoreButtons2_Accelerometer1_Ir16) {
			// Send to delegate
			if ([self respondsToDelegateSelector:@selector(WiiRemoteIrValues:)]) [delegate WiiRemoteIrValues:irData];

			//TODO: recalculate position on screen
		}
		
	} else {
		[self errorCode:106 WhichWasFatal:NO WithText:@"Unknwon IR-format with size %d.", size];
	}

	NSLog(@"Ir-Data");
}
- (void)receivedStatus:(uint8*)dataPointer WithOffset:(uint32)offset {
	uint8 flags = dataPointer[2];
	if (flags & 0x02) {
		//TODO: Need to be implemented; Initialize extension
	}
	
	uint8 lbatteryLevel = dataPointer[5];
	batteryLevel = (int)lbatteryLevel;
	
	NSLog(@"Battery: %d", lbatteryLevel);
	
	// Send to delegate
	if ([self respondsToDelegateSelector:@selector(WiiRemoteBatteryLevel:)]) [delegate WiiRemoteBatteryLevel:lbatteryLevel];
}



// Private
- (uint8)getVibrationBitMask {
	if (vibration) {
		return 0x01;
	} else {
		return 0x00;
	}
}
- (uint8)decryptByte:(uint8)byte {
	return (byte ^ 0x17) + 0x17;
}

@end
