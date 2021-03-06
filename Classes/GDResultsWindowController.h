//
//  GDResultsWindowController.h
//  GDict
//
//  Created by Zhang Yuanyi on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GDQueryWindowController;
@class WebView;

@interface GDResultsWindowController : NSWindowController {
@private
	IBOutlet GDQueryWindowController *queryWindowController;
	IBOutlet WebView *resultsWebView;
    IBOutlet NSButton *prev;
    IBOutlet NSButton *next;
    
	BOOL isSearching;
	NSDictionary *languages;
}

@property (retain) NSDictionary *languages;
@property (retain) IBOutlet WebView *resultsWebView;

- (IBAction)hideResultsWindow:(id)sender;
- (IBAction)showResultsWindow:(id)sender;

- (void)startSearching:(NSString*)queryString;
- (void)stopSearching:(BOOL)timeout;

- (void)resetSearchResults;

@end
