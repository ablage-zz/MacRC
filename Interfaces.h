/*
 *  Interfaces.h
 *  BluetoothRemoteFramework
 *
 *  Created by Marcel Erz on 8/14/08.
 *  Copyright 2008 Eliah Project. All rights reserved.
 *
 */

#import "Types.h"


#pragma mark Delegates for general bluetooth devices
@interface NSObject(BR_GeneralDelegate)
- (void)BluetoothRemoteErrorOccured:(int)code WithText:(NSString*)errorText WhichWasFatal:(BOOL)fatal;
- (void)BluetoothRemoteLog:(NSString*)logText WithCode:(int)code AndPriority:(BR_LogPriority)priority;
@end


#pragma mark Delegates for Bluetooth Inquiry
@interface NSObject(BR_Inquiry)
- (void)BluetoothSearchStarted;
- (BOOL)BluetoothRemoteShouldConnect:(id)device;
- (void)BluetoothRemoteConnected:(id)device;
- (void)BluetoothRemoteDisconnected:(id)device;
- (void)BluetoothSearchCompleted;
@end


#pragma mark Delegates for Wiimote
@interface NSObject(BR_WiiDelegate)
- (void)WiiRemoteButton:(BR_WiiButtons)button Pressed:(BOOL)pressed;
- (void)WiiRemoteBatteryLevel:(int)level;
- (void)WiiRemoteAccelerometer:(BR_WiiAccelerometer)value;
- (void)WiiRemoteIrValues:(BR_WiiIrCoordinates[])values;
- (void)WiiRemoteDataFromRam:(unsigned char*)dataPointer WithOffset:(unsigned int)offset AndLength:(size_t)dataLength;
- (void)WiiRemoteExtension:(BR_WiiExtension)value;
@end


#pragma mark Delegates for BDRemote
@interface NSObject(BR_BDDelegate)
- (void)BDRemoteButton:(BR_PSButton)button;
- (void)BDRemoteButtons:(BR_PSButton*)buttons;
- (void)BDRemoteButtonReleased;
- (void)BDRemoteBatteryLevel:(int)level;
@end
