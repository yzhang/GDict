//
//  GDBackgroundView.h
//  GDict
//
//  Created by Zhang Yuanyi on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSBBackgroundView : NSView {
@private
	NSImage *cachedView_;  // (STRONG) cached version of the view
	NSColor *backgroundColor_;  // (STRONG) bound to user defaults
	BOOL glossy_;  // Whether to draw gradients
	// |innerView_| is where the background will draw. The rest is just shadow.
	IBOutlet NSView *innerView_; 
}
@end

