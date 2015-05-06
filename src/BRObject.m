//
//  BRObject.m
//  BluetoothRemoteFramework
//
//  Created by Marcel Erz on 8/14/08.
//  Copyright 2008 Eliah Project. All rights reserved.
//

#import "BRObject.h"
#import "Interfaces.h"


@implementation BRObject

#pragma mark Init / Deinit

- (id)init {
	self = [super init];
	if (self) {
		delegate = nil;
	}
	return self;
}
- (void)dealloc {
	if (delegate != nil) {
		[delegate release];
		delegate = nil;
	}
	
	[super dealloc];
}


#pragma mark Properties

- (void)setDelegate:(NSObject*)value {
	[value retain];
	[delegate release];
	delegate = value;
}
- (NSObject*)delegate {
	return delegate;
}


#pragma mark Check delegate for responder

- (BOOL)respondsToDelegateSelector:(SEL)aSelector {
	NSObject *localDelegate = [self delegate];
	return ((localDelegate != nil) && ([localDelegate respondsToSelector:aSelector]));
}


#pragma mark Logging

- (void)errorCode:(int)code WhichWasFatal:(BOOL)fatal WithText:(NSString*)errorText, ... {
	if ([self respondsToDelegateSelector:@selector(BluetoothRemoteErrorOccured:WithText:WhichWasFatal:)]) {
		
		NSBundle *main = [NSBundle mainBundle];
		NSString *text = [main localizedStringForKey:[NSString stringWithFormat:@"$d", code]
											   value:errorText
											   table:@"Error"];
		
		// Format text
		va_list params;
		va_start(params, errorText);
		text = [[[NSString alloc] initWithFormat:text arguments:params] retain];
		va_end(params);
		
		[delegate BluetoothRemoteErrorOccured:code WithText:text WhichWasFatal:fatal];
		[text release];
	} 
}
- (void)logCode:(int)code WithPriority:(BR_LogPriority)priority AndText:(NSString*)logText, ... {
	if ([self respondsToDelegateSelector:@selector(BluetoothRemoteLog:WithCode:AndPriority:)]) {
		
		// Get Bundle and localized text
		NSBundle *main = [NSBundle mainBundle];
		NSString *text = [main localizedStringForKey:[NSString stringWithFormat:@"$d", code]
											   value:logText
											   table:@"Log"];
		
		// Format text
		va_list params;
		va_start(params, logText);
		text = [[[NSString alloc] initWithFormat:text arguments:params] retain];
		va_end(params);
		
		// Call delegate
		[delegate BluetoothRemoteLog:text WithCode:code AndPriority:priority];
		[text release];
	} 
}

@end
