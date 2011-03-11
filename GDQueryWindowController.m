//
//  GDQueryWindowController.m
//  GDict
//
//  Created by Zhang Yuanyi on 2/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GDQueryWindowController.h"
#import "GDApplicationDelegate.h"
#import "QSBCustomPanel.h"
#import "QSBTextField.h"
#import "GDResultsWindowController.h"

#import <objc/runtime.h>
#import <Quartz/Quartz.h>

#import "GTMTypeCasting.h"
#import "GTMMethodCheck.h"
#import "GTMNSImage+Scaling.h"
#import "GTMNSObject+KeyValueObserving.h"
#import "GTMNSAppleEventDescriptor+Foundation.h"

// Adds a weak reference to QLPreviewPanel so that we work on Leopard.
__asm__(".weak_reference _OBJC_CLASS_$_QLPreviewPanel");

const NSTimeInterval kGDShowDuration = 0.1;
const NSTimeInterval kGDHideDuration = 0.3;

static NSString * const kGDHideGDWhenInactivePrefKey = @"hideQSBWhenInactive";

static NSString * const kGDQueryWindowFrameTopPrefKey
= @"GDSearchWindow Top GDSearchResultsWindow";
static NSString * const kGDQueryWindowFrameLeftPrefKey
= @"GDSearchWindow Left GDSearchResultsWindow";

// NSNumber value in seconds that controls how fast the QSB clears out
// an old query once it's put in the background.
static NSString *const kGDResetQueryTimeoutPrefKey
= @"QSBResetQueryTimeoutPrefKey";

@interface GDQueryWindowController ()
- (BOOL)firstLaunch;

// Checks the find pasteboard to see if it's changed
- (void)checkFindPasteboard:(NSTimer *)timer;

// Given a proposed frame, returns a frame that fully exposes
// the proposed frame on |screen| as close to it's original position as
// possible.
// Args:
//    proposedFrame - the frame to be adjusted to fit on the screen
//    respectingDock - if YES, we won't cover the dock.
//    screen - the screen the rect is on
// Returns:
//   The frame rect offset such that if used to position the window
//   will fully exposes the window on the screen. If the proposed
//   frame is bigger than the screen, it is anchored to the upper
//   left.  The size of the proposed frame is never adjusted.
- (NSRect)fullyExposedFrameForFrame:(NSRect)proposedFrame
                     respectingDock:(BOOL)respectingDock
                           onScreen:(NSScreen *)screen;

- (void)updateWindowVisibilityBasedOnQueryString;

// Notifications
- (void)aWindowDidBecomeKey:(NSNotification *)notification;
- (void)applicationDidReopen:(NSNotification *)notification;
@end

@implementation GDQueryWindowController

@synthesize spinner;

- (id)init {
	self = [self initWithWindowNibName:@"QueryWindow"];
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)awakeFromNib {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(applicationDidReopen:)
			   name:kQSBApplicationDidReopenNotification
			 object:NSApp];
	
	[nc addObserver:self
		   selector:@selector(applicationDidBecomeActive:)
			   name:NSApplicationDidBecomeActiveNotification
			 object:NSApp];
	
	[nc addObserver:self
		   selector:@selector(applicationWillResignActive:)
			   name:NSApplicationWillResignActiveNotification
			 object:NSApp];
	
	// named aWindowDidBecomeKey instead of windowDidBecomeKey because if we
	// used windowDidBecomeKey we would be called twice for our window (once
	// for the notification, and once because we are the search window's delegate)
	[nc addObserver:self
		   selector:@selector(aWindowDidBecomeKey:)
			   name:NSWindowDidBecomeKeyNotification
			 object:nil];
	
	// get the pasteboard count and make sure we change it to something different
	// so that when the user first brings up the QSB its query is correct.
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSTimeInterval resetInterval;
	resetInterval = [userDefaults floatForKey:kGDResetQueryTimeoutPrefKey];
	if (resetInterval < 1) {
		resetInterval = 60; // One minute
		[userDefaults setDouble:resetInterval forKey:kGDResetQueryTimeoutPrefKey];
		// No need to worry about synchronize here as somebody else will sync us
	}
	
	// subtracting one just makes sure that we are initialized to something other
	// than what |changeCount| is going to be. |Changecount| always increments.
	NSPasteboard *findPasteBoard = [NSPasteboard generalPasteboard];
	findPasteBoardChangeCount = [findPasteBoard changeCount] - 1;
	isSearching = NO;
}

- (void)windowDidLoad {
	NSWindow *queryWindow = [self window];
	
	if ([self firstLaunch]) {
		[queryWindow center];
	} else {
		NSPoint topLeft = NSMakePoint(
									  [[NSUserDefaults standardUserDefaults]
									   floatForKey:kGDQueryWindowFrameLeftPrefKey],
									  [[NSUserDefaults standardUserDefaults]
									   floatForKey:kGDQueryWindowFrameTopPrefKey]);
		[queryWindow setFrameTopLeftPoint:topLeft];
		
		// Now insure that the window's frame is fully visible.
		NSRect queryFrame = [queryWindow frame];
		NSRect actualFrame = [self fullyExposedFrameForFrame:queryFrame
											  respectingDock:YES
													onScreen:[queryWindow screen]];
		[queryWindow setFrame:actualFrame display:YES];
	}
	
	[queryWindow setLevel:kCGStatusWindowLevel + 2];
	// Support spaces on Leopard.
	// http://b/issue?id=648841
	[queryWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	[queryWindow setMovableByWindowBackground:YES];
	[queryWindow invalidateShadow];
	[queryWindow setAlphaValue:0.0];
}

- (void)windowDidMove:(NSNotification *)notification {
	// The search window position on the screen has changed so record
	// this in our preferences so that we can later restore the window
	// to its new position.
	//
	// NOTE: We do this because it is far simpler than trying to use the autosave
	// approach and intercepting a number of window moves and resizes during
	// initial nib loading.
	NSRect windowFrame = [[self window] frame];
	NSPoint topLeft = windowFrame.origin;
	topLeft.y += windowFrame.size.height;
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setDouble:topLeft.x forKey:kGDQueryWindowFrameLeftPrefKey];
	[ud setDouble:topLeft.y forKey:kGDQueryWindowFrameTopPrefKey];
}

- (BOOL)firstLaunch {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	BOOL beenLaunched = [standardUserDefaults boolForKey:kGDBeenLaunchedPrefKey];
	return !beenLaunched;
}

- (IBAction)qsb_clearSearchString:(id)sender {}

- (IBAction)showSearchWindow:(id)sender {
	NSWindow *modalWindow = [NSApp modalWindow];
	if (!modalWindow) {
		// a window must be "visible" for it to be key. This makes it "visible"
		// but invisible to the user so we can accept keystrokes while we are
		// busy opening the window. We order it front as a invisible window, and
		// then slowly fade it in.
		NSWindow *queryWindow = [self window];
		
		[(QSBCustomPanel *)queryWindow setCanBecomeKeyWindow:YES];
		[queryWindow setIgnoresMouseEvents:NO];
		[queryWindow makeKeyAndOrderFront:nil];
		[queryWindow setAlphaValue: [[NSUserDefaults standardUserDefaults] floatForKey:@"AlphaValue"]];
	} else {
		// Bring whatever modal up front.
		[NSApp activateIgnoringOtherApps:YES];
		[modalWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction)hideSearchWindow:(id)sender {
	QSBCustomPanel *queryWindow = (QSBCustomPanel *)[self window];
	if ([queryWindow ignoresMouseEvents]) {
		return;
	}
	
	// Must be called BEFORE resignAsKeyWindow otherwise we call hide again
	[queryWindow setIgnoresMouseEvents:YES];
	[queryWindow setCanBecomeKeyWindow:NO];
	[queryWindow resignAsKeyWindow];

	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:kGDHideDuration];
	[[queryWindow animator] setAlphaValue:0.0];
	[NSAnimationContext endGrouping];
	
	[resultsWindowController hideResultsWindow:self];
}

- (NSRect)setResultsWindowFrameWithHeight:(CGFloat)newHeight {
	NSWindow *queryWindow = [self window];
	NSWindow *resultsWindow = [resultsWindowController window];
	BOOL resultsVisible = [resultsWindow isVisible];
	NSRect baseFrame = [resultsOffsetterView frame];
	baseFrame.origin = [queryWindow convertBaseToScreen:baseFrame.origin];
	// Always start with the baseFrame and enlarge it to fit the height
	NSRect proposedFrame = baseFrame;
	proposedFrame.origin.y -= newHeight; // one more for borders
	proposedFrame.size.height = newHeight;
	NSRect actualFrame = proposedFrame;
	if (resultsVisible) {
		// If the results panel is visible then we first size and position it
		// and then reposition the search box.
		
		// second, determine a frame that actually fits within the screen.
		actualFrame = [self fullyExposedFrameForFrame:proposedFrame
									   respectingDock:YES
											 onScreen:[queryWindow screen]];
		if (!NSEqualRects(actualFrame, proposedFrame)) {
			// We need to move the query window as well as the results window.
			NSPoint deltaPoint
			= NSMakePoint(actualFrame.origin.x - proposedFrame.origin.x,
						  actualFrame.origin.y - proposedFrame.origin.y);
			
			NSRect queryFrame = NSOffsetRect([queryWindow frame],
											 deltaPoint.x, deltaPoint.y);
			[[queryWindow animator] setFrame:queryFrame display:YES];
		}
		NSPoint upperLeft = NSMakePoint(NSMinX(actualFrame), NSMaxY(actualFrame));
		[resultsWindow setFrameTopLeftPoint:upperLeft];
		[[resultsWindow animator] setFrame:actualFrame display:YES];
	}
	return actualFrame;
}

- (void)hitHotKey:(id)sender {
	if (![[self window] ignoresMouseEvents]) {
		[self hideSearchWindow:self];
	} else {
		[self showSearchWindow:self];
	}
}

- (void)aWindowDidBecomeKey:(NSNotification *)notification {
	NSLog(@"become key");
	NSWindow *window = [notification object];
	NSWindow *queryWindow = [self window];

	if ([window isEqual:queryWindow]) {
		[self checkFindPasteboard:nil];
		if (insertFindPasteBoardString) {
			insertFindPasteBoardString = NO;
			//NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
//			NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
//			NSDictionary *options = [NSDictionary dictionary];
//			NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
//			if (copiedItems != nil) {
//				NSString *text = [copiedItems objectAtIndex:0];
//				if([text length] < 40) {
//					[queryTextField selectAll:self];
//					[queryTextField insertText:text];
//					[queryTextField selectAll:self];
//					[self startSearching:text];
//				}
//			}
		}
	} else if ([queryWindow isVisible]) {
		NSLog(@"hide");
		// We check for QLPreviewPanel because we don't want to hide for quicklook
		[self hideSearchWindow:self];
	}
	
}

- (void)windowDidResignKey:(NSNotification *)notification {
	// If we've pivoted and have a token in the search text box we will just
	// blow everything away (http://b/issue?id=1567906), otherwise we will
	// select all of the text, so the next time the user brings us up we will
	// immediately replace their selection with what they type.
	if (![[self window] ignoresMouseEvents]) {
		[self hideSearchWindow:self];
	}
}

#pragma mark NSTimer Callbacks

- (void)checkFindPasteboard:(NSTimer *)timer {
	NSInteger newCount
    = [[NSPasteboard generalPasteboard] changeCount];
	insertFindPasteBoardString = newCount != findPasteBoardChangeCount;
	findPasteBoardChangeCount = newCount;
}

- (void)startSearching:(NSString *)string {
	if(isSearching) return;
	
	[spinner startAnimation:self];

	if(string != [queryTextField string]) {
		[queryTextField selectAll:self];
		[queryTextField insertText:string];
		[queryTextField selectAll:self];
	}
	
	[queryTextField setEditable:NO];
	
	
	[resultsWindowController startSearching:string];

	[[self window] makeFirstResponder: queryTextField];

	isSearching = YES;
	
	keeper = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"LoadingTimeout"]
											  target:self 
											selector:@selector(timeoutSearching:)
											userInfo:nil
											 repeats:NO];
}

- (void)timeoutSearching:(NSTimer*)timer {
	if(!isSearching) return;
	
	[resultsWindowController stopSearching:YES];
	[self prepareSearching];
}

- (void)stopSearching{
	if(!isSearching) return;
	
	[resultsWindowController stopSearching:NO];
	[self prepareSearching];
}

- (void)prepareSearching {
	if(!isSearching) return;
	
	[keeper invalidate];
	NSWindow *queryWindow = [self window];
	[queryTextField setEditable:YES];
	[queryWindow makeFirstResponder: queryTextField];
	[spinner stopAnimation:self];
	isSearching = NO;
}

- (void)resetSearching {
	[resultsWindowController resetSearchResults];
}

- (void)updateWindowVisibilityBasedOnQueryString {
	if(isSearching) return;
	
	if ([[queryTextField string] length]) {
		[resultsWindowController showResultsWindow:self];
	} else {
		[resultsWindowController hideResultsWindow:self];
	}
}

- (void)textDidChange:(NSNotification *)notification {
	//[self resetSearching];
}

- (void)textDidEndEditing:(NSNotification *)notification {
	[self resetSearching];
	[queryTextField selectAll:self];
	[self startSearching:[queryTextField string]];
}

- (void)cancelOperation:(id)sender {
	if(isSearching) {
		[self stopSearching];
	} else {
		[self hideSearchWindow:self];
	}
}

// Delegate callback for the window menu, this propogates the dropdown of
// search sites

#pragma mark NSApplication Notification Methods

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	if ([NSApp keyWindow] == nil) {
		[self showSearchWindow:self];
	}
}

- (void)applicationDidReopen:(NSNotification *)notification {
	if (![NSApp keyWindow]) {
		[self showSearchWindow:self];
	}
}

- (void)applicationWillResignActive:(NSNotification *)notification {
	if ([[self window] isVisible]) {
		BOOL hideWhenInactive = YES;
		NSNumber *hideNumber = [[NSUserDefaults standardUserDefaults]
								objectForKey:kGDHideGDWhenInactivePrefKey];
		if (hideNumber) {
			hideWhenInactive = [hideNumber boolValue];
		}
		if (hideWhenInactive) {
			[self hideSearchWindow:self];
		}
	}
}

- (NSRect)fullyExposedFrameForFrame:(NSRect)proposedFrame
                     respectingDock:(BOOL)respectingDock
                           onScreen:(NSScreen *)screen {
	// If we can't find a screen for this window, use the main one.
	if (!screen) {
		screen = [NSScreen mainScreen];
	}
	NSRect screenFrame = respectingDock ? [screen visibleFrame] : [screen frame];
	if (!NSContainsRect(screenFrame, proposedFrame)) {
		if (proposedFrame.origin.y < screenFrame.origin.y) {
			proposedFrame.origin.y = screenFrame.origin.y;
		}
		if (NSMaxX(proposedFrame) > NSMaxX(screenFrame)) {
			proposedFrame.origin.x = NSMaxX(screenFrame) - NSWidth(proposedFrame);
		}
		if (proposedFrame.origin.x < screenFrame.origin.x) {
			proposedFrame.origin.x = screenFrame.origin.x;
		}
		if (NSMaxY(proposedFrame) > NSMaxY(screenFrame)) {
			proposedFrame.origin.y = NSMaxY(screenFrame) - NSHeight(proposedFrame);
		}
	}
	return proposedFrame;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	BOOL valid = YES;
	SEL action = [menuItem action];
	SEL showSearchWindowSel = @selector(hitHotKey:);
	SEL hideSearchWindowSel = @selector(hideSearchWindow:);
	BOOL searchWindowActive = ![[self window] ignoresMouseEvents];
	if (action == showSearchWindowSel && searchWindowActive) {
		[menuItem setAction:hideSearchWindowSel];
		[menuItem setTitle:@"Hide GDict"];
	} else if (action == hideSearchWindowSel && !searchWindowActive) {
		[menuItem setAction:showSearchWindowSel];
		[menuItem setTitle:@"Show GDict"];
	}
	
	return valid;
}
@end
