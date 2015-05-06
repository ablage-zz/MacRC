//
//  Private.h
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 7/31/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#pragma mark Reports for Wiimote
typedef enum {
	// Output (towards the remote)
	BR_Report_PlayerLed						= 0x11, // Size: 1
	BR_Report_DataReportingMode				= 0x12, // Size: 2
	BR_Report_IrCameraEnable1				= 0x13, // Size: 1
	BR_Report_SpeakerEnable					= 0x14, // Size: 1
	BR_Report_StatusInformationRequest		= 0x15, // Size: 1
	BR_Report_WriteMemoryRegisterRequest	= 0x16, // Size: 21
	BR_Report_ReadMemoryRegisterRequest		= 0x17, // Size: 6
	BR_Report_SpeakerData					= 0x18, // Size: 21
	BR_Report_SpeakerMute					= 0x19, // Size: 1
	BR_Report_IrCameraEnable2				= 0x1a, // Size: 1
	
	// Input (towards the host)
	BR_Report_StatusInformation				= 0x20, // Size: 6
	BR_Report_ReadMemoryRegisterData		= 0x21, // Size: 21
	BR_Report_WriteMemoryRegisterData		= 0x22, // Size: 4
	
	// Data-reports; Input (towards the host)
	BR_DataReport_CoreButtons2										= 0x30, // Size: 2
	BR_DataReport_CoreButtons2_Accelerometer3						= 0x31, // Size: 5
	BR_DataReport_CoreButtons2_Extension8							= 0x32, // Size: 10
	BR_DataReport_CoreButtons2_Accelerometer3_Ir12					= 0x33, // Size: 17
	BR_DataReport_CoreButtons2_Extension19							= 0x34, // Size: 21
	BR_DataReport_CoreButtons2_Accelerometer3_Extension16			= 0x35, // Size: 21
	BR_DataReport_CoreButtons2_Ir10_Extension9						= 0x36, // Size: 21
	BR_DataReport_CoreButtons2_Accelerometer3_Ir10_Extension6		= 0x37, // Size: 21
	BR_DataReport_Extension21										= 0x3d, // Size: 21
	BR_DataReport_1_Interleaved_CoreButtons2_Accelerometer1_Ir16	= 0x3e, // Size: 19
	BR_DataReport_2_Interleaved_CoreButtons2_Accelerometer1_Ir16	= 0x3f  // Size: 19
} BR_WiiReport_BitMask;













// Keys
//TODO: Still need to be implemented
typedef UInt16 WiiKeys_BitMask;
enum {
	Key_CC_Left		= 0x0002,
	Key_CC_Right	= 0x8000,
	Key_CC_Down 	= 0x4000,
	Key_CC_Up		= 0x0001,
	Key_CC_ZR		= 0x0004,
	Key_CC_ZL		= 0x0080,
	Key_CC_A		= 0x0010,
	Key_CC_B		= 0x0040,
	Key_CC_X		= 0x0008,
	Key_CC_Y		= 0x0020,
	Key_CC_Plus		= 0x0400,
	Key_CC_H		= 0x0800,
	Key_CC_Minus	= 0x1000,
	Key_CC_LT		= 0x2000,
	Key_CC_RT		= 0x0200,

	Key_NC_Z		= 0x0001,
	Key_NC_C		= 0x0002,

	Key_GH_Plus		= 0x0400,
	Key_GH_Minus	= 0x1000,
	Key_GH_Down		= 0x4000,
	Key_GH_Up		= 0x0001,
	Key_GH_Yellow	= 0x0008,
	Key_GH_Green	= 0x0010,
	Key_GH_Blue		= 0x0020,
	Key_GH_Red		= 0x0040,
	Key_GH_Orange	= 0x0080,

	Key_BB_Power	= 0x0008
};