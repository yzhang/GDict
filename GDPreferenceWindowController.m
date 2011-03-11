//
//  GDPreferencesController.m
//  GDict
//
//  Created by Zhang Yuanyi on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GDPreferenceWindowController.h"

#import "GTMGarbageCollection.h"
#import "GTMHotKeyTextField.h"
#import "GTMMethodCheck.h"

@implementation GDPreferenceWindowController

- (id)init {
	self = [super initWithWindowNibName:@"PreferencesWindow"];
	return self;
}

- (void) dealloc {
	[super dealloc];
}


-(void) awakeFromNib {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	uint keyCode = [defaults integerForKey:kQSBHotKeyKeyCodeKey];
	uint modifiers = [defaults integerForKey:kQSBHotKeyModifierFlagsKey];
	
	GTMHotKeyTextFieldCell *cell = [hotKeyField cell];
	
	GTMHotKey *hotKey = [GTMHotKey hotKeyWithKeyCode:keyCode modifiers:modifiers useDoubledModifier:NO];
	[cell setObjectValue:hotKey];
}

- (IBAction)showPreferences:(id)sender {
	NSWindow *prefWindow = [self window];
	[NSApp activateIgnoringOtherApps:YES];
	[prefWindow center];
	[prefWindow makeKeyAndOrderFront:nil];
	[prefWindow makeFirstResponder:nil];
}

- (void)hidePreferences {
	if ([self preferencesWindowIsShowing]) {
		[[self window] setIsVisible:NO];
	}
}

- (BOOL)preferencesWindowIsShowing {
	return ([[self window] isVisible]);
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
	if ([client isKindOfClass:[GTMHotKeyTextField class]]) {
		return [GTMHotKeyFieldEditor sharedHotKeyFieldEditor];
	} else {
		return nil;
	}
}

- (IBAction)hotKeyChanged:(id)sender {
	GTMHotKeyTextField *field = (GTMHotKeyTextField*)sender;
	GTMHotKeyTextFieldCell *cell = [field cell];
	
	GTMHotKey *hotKey = [cell objectValue];
	uint modifiers = [hotKey modifiers];
	uint keyCode   = [hotKey keyCode];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithInt:modifiers] forKey:kQSBHotKeyModifierFlagsKey];
	[defaults setObject:[NSNumber numberWithInt:keyCode] forKey:kQSBHotKeyKeyCodeKey];
}

@end