//
//  GDApplicationDelegate.m
//  GDict
//
//  Created by Zhang Yuanyi on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GDApplicationDelegate.h"
#import "GDQueryWindowController.h"
#import "GDPreferenceWindowController.h"

#import "GTMCarbonEvent.h"
#import "GTMGarbageCollection.h"
#import "GTMGeometryUtils.h"
#import "GTMMethodCheck.h"
#import "GTMSystemVersion.h"
#import "GTMHotKeyTextField.h"
#import "GTMNSWorkspace+Running.h"
#import "GTMNSObject+KeyValueObserving.h"

#define kQSBIconInMenubarKey                  @"QSBIconInMenubar"
#define kQSBIconInMenubarDefault              YES
#define kQSBIconInDockKey                     @"QSBIconInDock"
#define kQSBIconInDockDefault                 NO

// Default hotkey is ControlSpace
#define kQSBHotKeyKeyDefault [NSDictionary dictionaryWithObjectsAndKeys: \
								[NSNumber numberWithUnsignedInt:524320], \
								kQSBHotKeyModifierFlagsKey, \
								[NSNumber numberWithUnsignedInt:2], \
								kQSBHotKeyKeyCodeKey, \
								nil]


NSString *const kGDBeenLaunchedPrefKey = @"QSBBeenLaunchedPrefKey";

@interface GDApplicationDelegate ()
// our hotkey has been hit, let's do something about it
- (void)hitHotKey:(id)sender;

// Called when we should update how our status icon appears
- (void)updateIconInMenubar;

// Called when we want to update menus with a proper app name
- (void)updateMenuWithAppName:(NSMenu* )menu;

- (void)hotKeyValueChanged:(GTMKeyValueChangeNotification *)note;
@end

@implementation GDApplicationDelegate

@synthesize queryWindowController;

+(void) initialize {	
	NSDictionary *defaults = [NSDictionary 
							  dictionaryWithObjectsAndKeys:
							    [NSNumber numberWithInt:30],    @"LoadingTimeout",
								[NSNumber numberWithFloat:0.9], @"AlphaValue",
								[NSNumber numberWithBool:NO], kGDAlwaysOnTopPrefKey,
								[NSNumber numberWithBool:kQSBIconInMenubarDefault], kQSBIconInMenubarKey,
							    [NSNumber numberWithBool:kQSBIconInDockDefault], kQSBIconInDockKey,
								[NSNumber numberWithUnsignedInt:524320], kQSBHotKeyModifierFlagsKey,
								[NSNumber numberWithUnsignedInt:2], kQSBHotKeyKeyCodeKey,
								@"Chinese (Simplified)", @"Language",
							  nil];
		
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (id)init {
	if ((self = [super init])) {
		queryWindowController = [[GDQueryWindowController alloc] init];
		
		BOOL iconInDock
		= [[NSUserDefaults standardUserDefaults] boolForKey:kQSBIconInDockKey];
		if (iconInDock) {
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			TransformProcessType(&psn, kProcessTransformToForegroundApplication);
		}
		
		[NSApp setServicesProvider:self];
		NSUpdateDynamicServices();
	}
	
	return self;
}

- (void)lookupFromService:(NSPasteboard *)pasteboard
                       userData:(NSString *)userData
                          error:(NSString **)error {
	NSString *pboardString = [pasteboard stringForType:NSPasteboardTypeString];
	[queryWindowController startSearching:pboardString];
}

- (void)dealloc {
	[queryWindowController release];
	[super dealloc];
}

- (void)updateHotKeyRegistration {
	GTMCarbonEventDispatcherHandler *dispatcher
    = [GTMCarbonEventDispatcherHandler sharedEventDispatcherHandler];
	
	// Remove any hotkey we currently have.
	if (carbonHotKey) {
		[dispatcher unregisterHotKey:carbonHotKey];
		[carbonHotKey release];
		carbonHotKey = nil;
	}
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
			
	uint modifiers = [ud integerForKey:kQSBHotKeyModifierFlagsKey];
	uint keycode   = [ud integerForKey:kQSBHotKeyKeyCodeKey];
	
	carbonHotKey = [[dispatcher registerHotKey:keycode
									  modifiers:modifiers
										 target:self
										 action:@selector(hitHotKey:)
									   userInfo:nil
									whenPressed:YES] retain];

}

- (void)awakeFromNib {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults gtm_addObserver:self
				   forKeyPath:kQSBHotKeyKeyCodeKey
					 selector:@selector(hotKeyValueChanged:)
					 userInfo:nil
					  options:0];
	[defaults gtm_addObserver:self
				   forKeyPath:kQSBHotKeyModifierFlagsKey
					 selector:@selector(hotKeyValueChanged:)
					 userInfo:nil
					  options:0];
	
	// set up all our menu bar UI
	[self updateIconInMenubar];

	[statusShowSearchBoxItem setTarget:queryWindowController];
	[statusShowSearchBoxItem setAction:@selector(hitHotKey:)];
	[dockShowSearchBoxItem setTarget:queryWindowController];
	[dockShowSearchBoxItem setAction:@selector(hitHotKey:)];
	
	NSLog(@"awaked");
}

- (void)hotKeyValueChanged:(GTMKeyValueChangeNotification *)note {
	[self updateHotKeyRegistration];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	[self updateHotKeyRegistration];
	[self updateMenuWithAppName:[NSApp mainMenu]];
	[self updateMenuWithAppName:dockMenu];
	[self updateMenuWithAppName:statusItemMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[queryWindowController window];
	[[NSApplication sharedApplication] activateIgnoringOtherApps : YES];
	[queryWindowController showSearchWindow:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:kQSBApplicationDidReopenNotification
					  object:NSApp];
	return NO;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
	return dockMenu;
}

- (void)hitHotKey:(id)sender {
	[queryWindowController hitHotKey:self];
}

- (NSMenu*)statusItemMenu {
	return statusItemMenu;
}

- (void)updateMenuWithAppName:(NSMenu* )menu {
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *newName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
	NSArray *items = [menu itemArray];
	for (NSMenuItem *item in items) {
		NSString *appName = @"$APPNAME$";
		NSString *title = [item title];
		
		if ([title rangeOfString:appName].length != 0) {
			NSString *newTitle = [title stringByReplacingOccurrencesOfString:appName
																  withString:newName];
			[item setTitle:newTitle];
		}
		NSMenu *subMenu = [item submenu];
		if (subMenu) {
			[self updateMenuWithAppName:subMenu];
		}
	}
}

- (void)updateIconInMenubar {
	BOOL iconInMenubar
    = [[NSUserDefaults standardUserDefaults] boolForKey:kQSBIconInMenubarKey];
	BOOL iconInDock
	= [[NSUserDefaults standardUserDefaults] boolForKey:kQSBIconInDockKey];
	
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	if (iconInMenubar || !iconInDock) {
		NSImage *defaultImg = [NSImage imageNamed:@"statusIcon"];
		NSImage *altImg = [NSImage imageNamed:@"statusIcon"];

		CGFloat itemWidth = [defaultImg size].width + 8.0;
		statusItem = [[statusBar statusItemWithLength:itemWidth] retain];
		[statusItem setMenu:statusItemMenu];
		[statusItem setHighlightMode:YES];
		[statusItem setImage:defaultImg];
		[statusItem setAlternateImage:altImg];
	} else if (statusItem) {
		[statusBar removeStatusItem:statusItem];
		[statusItem autorelease];
		statusItem = nil;
	}
}

// method that is called when the modifier keys are hit and we are inactive
- (void)modifiersChangedWhileInactive:(NSEvent*)event {}

- (void)modifiersChangedWhileActive:(NSEvent*)event {}

- (void)keysChangedWhileActive:(NSEvent*)event {}

- (IBAction)orderFrontStandardAboutPanel:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanelWithOptions:nil];
}

- (IBAction)showPreferences:(id)sender {
	if (!prefsWindowController) {
		prefsWindowController = [[GDPreferenceWindowController alloc] init];
	}
	[prefsWindowController showPreferences:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)copySelectedText:(id)sender {
    [queryWindowController copySelectedText:sender];
}
@end
