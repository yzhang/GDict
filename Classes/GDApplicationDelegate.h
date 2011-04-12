//
//  GDApplicationDelegate.h
//  GDict
//
//  Created by Zhang Yuanyi on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *const kGDBeenLaunchedPrefKey;

@class GDQueryWindowController;
@class GDPreferenceWindowController;
@class GTMCarbonHotKey;
@class GTMHotKey;

@interface GDApplicationDelegate : NSObject<NSApplicationDelegate> {
@private
	IBOutlet NSMenu *statusItemMenu;
	IBOutlet NSMenuItem *statusShowSearchBoxItem;
	IBOutlet NSMenu *dockMenu;
	IBOutlet NSMenuItem *dockShowSearchBoxItem;
	
	NSStatusItem *statusItem;
	
	GDQueryWindowController *queryWindowController;
	GDPreferenceWindowController *prefsWindowController;
	
	GTMCarbonHotKey *carbonHotKey;  // the hot key we're looking for.
}

@property (readonly, retain, nonatomic) GDQueryWindowController *queryWindowController;

// method that is called when the modifier keys are hit and we are inactive
- (void)modifiersChangedWhileInactive:(NSEvent*)event;

// method that is called when the modifier keys are hit and we are active
- (void)modifiersChangedWhileActive:(NSEvent*)event;

// method that is called when a key changes state and we are active
- (void)keysChangedWhileActive:(NSEvent*)event;

- (NSMenu*)statusItemMenu;

- (IBAction)orderFrontStandardAboutPanel:(id)sender;

- (IBAction)showPreferences:(id)sender;

- (IBAction)copySelectedText:(id)sender;
@end

#pragma mark Notifications

// Notification sent when we are reopened (finder icon clicked while we
// are running, or the dock icon clicked).
#define kQSBApplicationDidReopenNotification @"QSBApplicationDidReopenNotification"
