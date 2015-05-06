/*
 *  Types.h
 *  BluetoothRemoteFramework
 *
 *  Created by Marcel Erz on 8/5/08.
 *  Copyright 2008 Eliah Project. All rights reserved.
 *
 */


#pragma mark Supported bluetooth products
typedef enum {
	BR_Product_Undefined		= 0,
	
	BR_Product_WiiRemote		= 1,
	BR_Product_WiiBalanceBoard	= 2,
	
	BR_Product_BDRemote			= 4,
	
	BR_Product_None				= 1024
} BR_Product;



#pragma mark Wiimote IR camera format
typedef enum {
	BR_Ir_Basic		= 0x01,
	BR_Ir_Extended	= 0x03,
	BR_Ir_Full		= 0x05
} BR_WiiIrDataFormat;

#pragma mark Wii Ir-Sensitivity
typedef enum {
	BR_WiiIrSensitivity_Highest = 0x06,
	BR_WiiIrSensitivity_VeryHigh = 0x05,
	BR_WiiIrSensitivity_High = 0x04,
	BR_WiiIrSensitivity_Normal = 0x03,
	BR_WiiIrSensitivity_Low = 0x02,
	BR_WiiIrSensitivity_VeryLow = 0x01,
	BR_WiiIrSensitivity_Lowest = 0x00
} BR_WiiIrSensitivity;

#pragma mark Place of read/write (at Wiimote)
typedef enum {
	BR_WiiReadWrite_EEPROM = 0x00,
	BR_WiiReadWrite_Register = 0x04
} BR_WiiReadWriteDestination;

#pragma mark Wii Accelerometer
typedef struct _BR_WiiAccelerometer {
	unsigned char X;
	unsigned char Y;
	unsigned char Z;
	unsigned char X_zero;
	unsigned char Y_zero;
	unsigned char Z_zero;
	unsigned char X_1G;
	unsigned char Y_1G;
	unsigned char Z_1G;
} BR_WiiAccelerometer;

#pragma mark Wii Ir-Data
typedef struct _BR_WiiIrCoordinates {
	int x;
	int y;
	int size;
	int intensity;
	int xMin;
	int xMax;
	int yMin;
	int yMax;
} BR_WiiIrCoordinates;

#pragma mark Wii-Extension ID
typedef enum {
	BR_WiiExtension_NotConnected		= 0x0000,
	BR_WiiExtension_BalanceBoard		= 0x2A2C,
	BR_WiiExtension_ClassicController	= 0x0101,
	BR_WiiExtension_Nunchuk				= 0x0000,
	BR_WiiExtension_GuitarHero			= 0x0103
} BR_WiiExtension;

#pragma mark WiiRemote Keys
typedef unsigned short BR_WiiButtons;
typedef enum _BR_WR_Buttons {
	BR_Button_WR_Unpressed	= 0x0000,
	
	BR_Button_WR_Left		= 0x0100,
	BR_Button_WR_Right		= 0x0200,
	BR_Button_WR_Down		= 0x0400,
	BR_Button_WR_Up			= 0x0800,
	BR_Button_WR_Plus		= 0x1000,
	BR_Button_WR_Two		= 0x0001,
	BR_Button_WR_One		= 0x0002,
	BR_Button_WR_B			= 0x0004,
	BR_Button_WR_A			= 0x0008,
	BR_Button_WR_Minus		= 0x0010,
	BR_Button_WR_Home		= 0x0080
} BR_WR_Buttons;



#pragma mark BDRemote Keys
typedef unsigned char BR_PSButton;
typedef enum _BR_BD_Buttons {
	BR_Button_BD_Released	= 0xFF,
	
	BR_Button_BD_1			= 0x00,
	BR_Button_BD_2			= 0x01,
	BR_Button_BD_3			= 0x02,
	BR_Button_BD_4			= 0x03,
	BR_Button_BD_5			= 0x04,
	BR_Button_BD_6			= 0x05,
	BR_Button_BD_7			= 0x06,
	BR_Button_BD_8			= 0x07,
	BR_Button_BD_9			= 0x08,
	BR_Button_BD_0			= 0x09,
	BR_Button_BD_EJECT		= 0x16,
	BR_Button_BD_AUDIO		= 0x64,
	BR_Button_BD_ANGLE		= 0x65,
	BR_Button_BD_SUBTITLE	= 0x63,
	BR_Button_BD_CLEAR		= 0x0F,
	BR_Button_BD_TIME		= 0x28,
	BR_Button_BD_RED		= 0x81,
	BR_Button_BD_GREEN		= 0x82,
	BR_Button_BD_BLUE		= 0x80,
	BR_Button_BD_YELLOW		= 0x83,
	BR_Button_BD_DISPLAY	= 0x70,
	BR_Button_BD_TOP_MENU	= 0x1A,
	BR_Button_BD_MENU		= 0x40,
	BR_Button_BD_RETURN		= 0x0E,
	BR_Button_BD_OPTIONS	= 0x5C,
	BR_Button_BD_BACK		= 0x5D,
	BR_Button_BD_X			= 0x5E,
	BR_Button_BD_VIEW		= 0x5F,
	BR_Button_BD_UP			= 0x54,
	BR_Button_BD_RIGHT		= 0x55,
	BR_Button_BD_DOWN		= 0x56,
	BR_Button_BD_LEFT		= 0x57,
	BR_Button_BD_ENTER		= 0x0B,
	BR_Button_BD_L1			= 0x5A,
	BR_Button_BD_L2			= 0x58,
	BR_Button_BD_L3			= 0x51,
	BR_Button_BD_R1			= 0x5B,
	BR_Button_BD_R2			= 0x59,
	BR_Button_BD_R3			= 0x52,
	BR_Button_BD_PS			= 0x43,
	BR_Button_BD_SELECT		= 0x50,
	BR_Button_BD_START		= 0x53,
	BR_Button_BD_LEFT_SCAN	= 0x33,
	BR_Button_BD_RIGHT_SCAN	= 0x34,
	BR_Button_BD_PREVIOUS	= 0x30,
	BR_Button_BD_NEXT		= 0x31,
	BR_Button_BD_LEFT_STEP	= 0x60,
	BR_Button_BD_RIGHT_STEP	= 0x61,
	BR_Button_BD_PLAY		= 0x32,
	BR_Button_BD_STOP		= 0x38,
	BR_Button_BD_PAUSE		= 0x39
} BR_BD_Buttons;




#pragma mark Log Priorities
typedef enum _BR_LogPriority {
	BR_Priority_Information	= 1,
	BR_Priority_Action		= 2
} BR_LogPriority;
