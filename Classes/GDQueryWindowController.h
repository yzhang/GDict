//
//  GDQueryWindowController.h
//  GDict
//
//  Created by Zhang Yuanyi on 2/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern const NSTimeInterval kGDAppearDelay;
extern const NSTimeInterval kGDShowDuration;
extern const NSTimeInterval kGDHideDuration;

#define kGDAlwaysOnTopPrefKey @"GDAlwaysOnTop"

@class GDResultsWindowController;
@class QSBTextField;

@interface GDQueryWindowController : NSWindowController {
	IBOutlet NSProgressIndicator *spinner;

@private
	IBOutlet QSBTextField *queryTextField;
	IBOutlet NSView *resultsOffsetterView;
	
	IBOutlet NSWindow *shieldWindow_;
	
	IBOutlet GDResultsWindowController *resultsWindowController;
	
	// controls whether we put the pasteboard data in the qsb
	__weak NSTimer *findPasteBoardChangedTimer;
	NSInteger findPasteBoardChangeCount;  // used to detect if the pasteboard has changed
	BOOL insertFindPasteBoardString;  // should we use the find pasteboard string
	BOOL isSearching;
	
	NSTimer * keeper;
}

@property(retain) IBOutlet NSProgressIndicator *spinner;

// Designated initializer
- (id)init;

// Attempt to set the height of the results window while insuring that
// the results window fits comfortably on the screen along with the
// search box window.
- (NSRect)setResultsWindowFrameWithHeight:(CGFloat)height;

// Change search window visibility
- (IBAction)showSearchWindow:(id)sender;
- (IBAction)hideSearchWindow:(id)sender;

// Reset the current query by unrolling all pivots, if any, and hiding the
// results window.  If no results are showing then hide the query window.
- (IBAction)qsb_clearSearchString:(id)sender;

// Just clears the search string.
- (void)resetSearching;

// Search for a string in the UI
- (void)startSearching:(NSString *)string;

- (void)timeoutSearching:(NSTimer*)timer;

- (void)stopSearching;

// The hot key was hit.
- (void)hitHotKey:(id)sender;

- (void)prepareSearching;

- (IBAction)copySelectedText:(id)sender;

@end
