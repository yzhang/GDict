//
//  GDPreferencesController.h
//  GDict
//
//  Created by Zhang Yuanyi on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GTMHotKeyTextField;
@class GTMHotKeyTextFieldCell;

// Dictionary key for hot key configuration information modifier flags.
// NSNumber of a unsigned int. Modifier flags are stored using Cocoa constants
// (same as NSEvent) you will need to translate them to Carbon modifier flags
// for use with RegisterEventHotKey()
#define kQSBHotKeyModifierFlagsKey @"Modifiers"

// Dictionary key for hot key configuration of virtual key code.  NSNumber of
// unsigned int. For double-modifier hotkeys (see below) this value is ignored.
#define kQSBHotKeyKeyCodeKey @"KeyCode"

@interface GDPreferenceWindowController : NSWindowController {
@private
	IBOutlet NSPopUpButton *languagePopUp1;
	IBOutlet NSPopUpButton *languagePopUp2;
	IBOutlet GTMHotKeyTextField *hotKeyField;
}

- (IBAction)hotKeyChanged:(id)sender;

- (id)init;

// Manage and report the visisbility of the preferences window.
- (IBAction)showPreferences:(id)sender;
- (void)hidePreferences;
- (BOOL)preferencesWindowIsShowing;

@end
