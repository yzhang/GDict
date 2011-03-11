//
//  GDResultsWindowController.m
//  GDict
//
//  Created by Zhang Yuanyi on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GDResultsWindowController.h"
#import "GDQueryWindowController.h"

#import <WebKit/WebKit.h>

#import "GTMTypeCasting.h"
#import "GTMNSAnimation+Duration.h"
#import "GTMMethodCheck.h"

#import "QSBCustomPanel.h"

@implementation GDResultsWindowController

- (id)init {
	self = [super initWithWindowNibName:@"ResultsWindow"];
	isSearching = NO;
	
	languages = [NSDictionary dictionaryWithObjectsAndKeys:
				 @"ar",    @"Arabic",
				 @"zh-CN", @"Chinese (Simplified)",
				 @"zh-TW", @"Chinese (Traditional)",
				 @"fr",    @"French",
				 @"de",    @"German",
				 @"pt",    @"Portuguese",
				 @"ru",    @"Russian",
				 @"es",    @"Spanish",
				 nil];
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)awakeFromNib {
	[resultsWebView setPreferencesIdentifier:@"GDict"];
    [[resultsWebView preferences] setUserStyleSheetEnabled:YES];
    [[resultsWebView preferences] setUserStyleSheetLocation:
	 [NSURL fileURLWithPath:
	  [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GDict.css"]]];
}

- (void)windowDidLoad {
	QSBCustomPanel *window = (QSBCustomPanel*)[self window];
	NSLog(@"results key");
	[window setCanBecomeKeyWindow:NO];
	[window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[window setAlphaValue:0];
	[window setLevel:kCGStatusWindowLevel + 1];
	[window orderFront:nil];
	[window setIgnoresMouseEvents:YES];
}

- (IBAction)hideResultsWindow:(id)sender {
	NSWindow *window = [self window];
	if ([window ignoresMouseEvents]) return;
	
	[window setIgnoresMouseEvents:YES];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] gtm_setDuration:kGDHideDuration
											   eventMask:kGTMLeftMouseUpAndKeyDownMask];
	[[window animator] setAlphaValue:0.0];
	[NSAnimationContext endGrouping];
}

- (IBAction)showResultsWindow:(id)sender {
	NSWindow *window = [self window];
	if (![window ignoresMouseEvents]) return;
	[window setIgnoresMouseEvents:NO];
	if (![window parentWindow]) {
		NSWindow *queryWindow = [queryWindowController window];
		[queryWindow addChildWindow:window ordered:NSWindowBelow];
	}
	
	//NSRect frame = [window frame];
	NSRect frame = [window frame];
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] gtm_setDuration:kGDShowDuration
											   eventMask:kGTMLeftMouseUpAndKeyDownMask];
	[[window animator] setAlphaValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"AlphaValue"]];
	NSRect newFrame
    = [queryWindowController setResultsWindowFrameWithHeight:NSHeight(frame)];
	
	NSView *resultsView = [window contentView];
	frame = [resultsView frame];
	frame.size.width = NSWidth(newFrame);
	[resultsView setFrame:frame];
	[NSAnimationContext endGrouping];
}

- (void)startSearching:(NSString*)queryString {
	[self showResultsWindow:self];

	NSString *language = [[NSUserDefaults standardUserDefaults]
							objectForKey:@"Language"];
	NSString *locale   = [languages objectForKey:language];
	
	NSString *url = [[NSString alloc]initWithFormat: 
		 @"http://www.google.com/dictionary?langpair=en|%@&q=%@&hl=en&aq=f",
		 locale,
		 [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

	if (![resultsWebView isLoading]) {
		[resultsWebView setMainFrameURL:url];
	}
}

- (void)stopSearching:(BOOL)timeout {	
	if ([resultsWebView isLoading]) {
		[resultsWebView stopLoading:self];
	}
	
	if (timeout) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"timeout" ofType:@"html"];
		[resultsWebView setMainFrameURL:path];
	} else {
		[self hideResultsWindow:self];
	}
}

- (void)resetSearchResults {
	[self hideResultsWindow:self];
	[resultsWebView setMainFrameURL:@"about:blank"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	[queryWindowController prepareSearching];
}

@end
