//
//  BRObject.h
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 8/14/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Types.h"


@interface BRObject : NSObject {
	
@protected
	NSObject *delegate;
}

#pragma mark Properties
- (void)setDelegate:(NSObject*)value;
- (NSObject*)delegate;

#pragma mark Check delegate for responder
- (BOOL)respondsToDelegateSelector:(SEL)aSelector;

#pragma mark Logging
- (void)errorCode:(int)code WhichWasFatal:(BOOL)fatal WithText:(NSString*)errorText, ...;
- (void)logCode:(int)code WithPriority:(BR_LogPriority)priority AndText:(NSString*)logText, ...;

@end
