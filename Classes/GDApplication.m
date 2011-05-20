//
//  GDApplication.m
//  GDict
//
//  Created by Zhang Yuanyi on 2/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GDApplication.h"
#import "GTMCarbonEvent.h"
#import "GTMDebugSelectorValidation.h"

#import "GDApplicationDelegate.h"
#import "GDQueryWindowController.h"

//#import "GDQueryWindowController.h"

static const EventTypeSpec kModifierEventTypeSpec[]
= { { kEventClassKeyboard, kEventRawKeyModifiersChanged } };
static const size_t kModifierEventTypeSpecSize
= sizeof(kModifierEventTypeSpec) / sizeof(EventTypeSpec);

static const EventTypeSpec kApplicationEventTypeSpec[]
= { { kEventClassApplication, kEventAppFrontSwitched } };
static const size_t kApplicationEventTypeSpecSize
= sizeof(kApplicationEventTypeSpec) / sizeof(EventTypeSpec);

@implementation GDApplication

// Allows me to intercept the "control" double tap to activate QSB. There
// appears to be no way to do this from straight Cocoa.
- (void)awakeFromNib {
	GTMCarbonEventMonitorHandler *monitorHandler
    = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
	[monitorHandler registerForEvents:kModifierEventTypeSpec
								count:kModifierEventTypeSpecSize];
	[monitorHandler setDelegate:self];
	
	GTMCarbonEventApplicationEventHandler *applicationHandler
    = [GTMCarbonEventApplicationEventHandler sharedApplicationEventHandler];
	[applicationHandler registerForEvents:kApplicationEventTypeSpec
									count:kApplicationEventTypeSpecSize];
	[applicationHandler setDelegate:self];
}

- (void) dealloc {
	GTMCarbonEventMonitorHandler *monitorHandler
    = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
	[monitorHandler unregisterForEvents:kModifierEventTypeSpec
								  count:kModifierEventTypeSpecSize];
	[monitorHandler setDelegate:nil];
	
	GTMCarbonEventApplicationEventHandler *applicationHandler
    = [GTMCarbonEventApplicationEventHandler sharedApplicationEventHandler];
	[applicationHandler unregisterForEvents:kApplicationEventTypeSpec
									  count:kApplicationEventTypeSpecSize];
	[applicationHandler setDelegate:nil];
	
	[super dealloc];
}

// Verify that our delegate will respond to things it is supposed to.
- (void)setDelegate:(id)anObject {
	if (anObject) {
		GTMAssertSelectorNilOrImplementedWithArguments(anObject,
													   @selector(modifiersChangedWhileActive:),
													   @encode(NSEvent *), nil);
		GTMAssertSelectorNilOrImplementedWithArguments(anObject,
													   @selector(modifiersChangedWhileInactive:),
													   @encode(NSEvent *), nil);
		GTMAssertSelectorNilOrImplementedWithArguments(anObject,
													   @selector(keysChangedWhileActive:),
													   @encode(NSEvent *), nil);
	}
	[super setDelegate:anObject];
}

- (void)sendEvent:(NSEvent *)theEvent {
	GDApplicationDelegate *delegate = (GDApplicationDelegate *)[self delegate];
	NSEventType type = [theEvent type];
	if (type == NSFlagsChanged) {
		[delegate modifiersChangedWhileActive:theEvent];
	} else if (type == NSKeyDown || type == NSKeyUp) {
		[delegate keysChangedWhileActive:theEvent];
	}
	[super sendEvent:theEvent];
}

- (OSStatus)gtm_eventHandler:(GTMCarbonEventHandler *)sender
               receivedEvent:(GTMCarbonEvent *)event
                     handler:(EventHandlerCallRef)handler {
	OSStatus status = eventNotHandledErr;
	EventClass theClass = [event eventClass];
	EventKind theKind = [event eventKind];
	if (theClass == kEventClassKeyboard &&
		theKind == kEventRawKeyModifiersChanged) {
		UInt32 modifiers;
		if ([event getUInt32ParameterNamed:kEventParamKeyModifiers
									  data:&modifiers]) {
			NSUInteger cocoaMods = GTMCarbonToCocoaKeyModifiers(modifiers);
			NSEvent *nsEvent = [NSEvent keyEventWithType:NSFlagsChanged
												location:[NSEvent mouseLocation]
										   modifierFlags:cocoaMods
											   timestamp:[event time]
											windowNumber:0
												 context:nil
											  characters:nil
							 charactersIgnoringModifiers:nil
											   isARepeat:NO
												 keyCode:0];
			GDApplicationDelegate *delegate
			= (GDApplicationDelegate *)[self delegate];
			[delegate modifiersChangedWhileInactive:nsEvent];
		}
	} else if (theClass == kEventClassApplication &&
			   theKind == kEventAppFrontSwitched) {
		ProcessSerialNumber psn;
		if ([event getParameterNamed:kEventParamProcessID
								type:typeProcessSerialNumber
								size:sizeof(psn)
								data:&psn]) {
			ProcessSerialNumber myPSN;
			MacGetCurrentProcess(&myPSN);
			Boolean equal;
			if (SameProcess(&psn, &myPSN, &equal) == noErr && !equal) {
				GDApplicationDelegate *delegate
				= (GDApplicationDelegate *)[self delegate];
                BOOL alwaysOnTop = [[NSUserDefaults standardUserDefaults]                        boolForKey:kGDAlwaysOnTopPrefKey];
                if(!alwaysOnTop) {
                    [[delegate queryWindowController] hideSearchWindow:self];
                }
			}
		}
	}
	return status;
}

@end
