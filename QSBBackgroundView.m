//
//  QSBBackgroundView.m
//
//  Copyright (c) 2006-2008 Google Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//    * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the
//  distribution.
//    * Neither the name of Google Inc. nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "QSBBackgroundView.h"
#import "GTMLinearRGBShading.h"
#import "GTMNSBezierPath+RoundRect.h"
#import "GTMNSBezierPath+Shading.h"
#import "GTMGeometryUtils.h"
#import "GTMMethodCheck.h"
#import "NSColor+Lighting.h"

@interface QSBBackgroundView ()
// Updates our cached version of the gradient.
- (NSImage*)cachedView;

// Invalidates our cached view;
- (void)invalidateCachedView;

// Draws the background view to the current context
- (void)drawInternal;
@end

@implementation QSBBackgroundView

GTM_METHOD_CHECK(NSBezierPath, gtm_fillAxiallyFrom:to:extendingStart:extendingEnd:shading:);
GTM_METHOD_CHECK(NSBezierPath, gtm_bezierPathWithRoundRect:cornerRadius:);

- (void)awakeFromNib {
	NSColor *defaultColor = [NSColor colorWithCalibratedRed:232.0/255.0
													  green:114.0/255.0
													   blue:23.0/255.0
													  alpha:1.0];
	
	[self bind:@"backgroundColor"
	  toObject:[NSUserDefaults standardUserDefaults]
   withKeyPath:@"backgroundColor"
	   options:[NSDictionary dictionaryWithObjectsAndKeys:
				defaultColor, NSNullPlaceholderBindingOption,
				NSUnarchiveFromDataTransformerName, NSValueTransformerNameBindingOption,
				nil]];
	[self bind:@"glossy"
	  toObject:[NSUserDefaults standardUserDefaults]
   withKeyPath:@"backgroundIsGlossy"
	   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
										   forKey:NSNullPlaceholderBindingOption]];
}

- (void)drawInternal {
	if (!innerView_) return;
	
	NSRect rect = [innerView_ frame];
	NSBezierPath *path = [NSBezierPath gtm_bezierPathWithRoundRect:rect 
													  cornerRadius:4.0];
	
	NSColor *midColor = backgroundColor_;
	if (!midColor) midColor = [NSColor blackColor];
	
	NSColor *colors[4];
	CGFloat positions[4];
	colors[0] = [midColor colorWithLighting:0.2 plasticity:1.0];
	positions[0] = 0.0;
	colors[1] = midColor;
	positions[1] = 0.15;
	colors[2] = [midColor colorWithLighting:-0.20];
	positions[2] = 0.9;
	colors[3] = [midColor colorWithLighting:-0.12];
	positions[3] = 1.0;
	
	// Draw a shadow around the innerView_ rect
	// The inner view lets us inset this so the shadow isn't clipped
	// To avoid artifacts, we actually do the drawing outside the frame, but have
	// the shadow cast inside
	
	NSShadow *aShadow = [[[NSShadow alloc] init] autorelease];
	aShadow.shadowBlurRadius = 10.0;
	aShadow.shadowOffset = NSMakeSize(0, -NSHeight([self frame]) - 4.0); 
	[aShadow set];
	// Fill outside our bounds
	NSRectFill(NSOffsetRect(rect, 0, NSHeight([self frame])));
	
	// Draw gray outer stroke
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] setStroke];
	[path stroke];
	
	size_t count = sizeof(positions) / sizeof(positions[0]);
	GTMLinearRGBShading *shading 
    = [GTMLinearRGBShading shadingWithColors:colors
                              fromSpaceNamed:NSCalibratedRGBColorSpace
                                 atPositions:positions
                                       count:count];
	
	[path gtm_fillAxiallyFrom:NSMakePoint(0, NSMaxY(rect))
						   to:NSMakePoint(0, NSMinY(rect))
			   extendingStart:YES
				 extendingEnd:YES
					  shading:shading];
	
	if (glossy_) {
		shading = [GTMLinearRGBShading shadingFromColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.4]
												toColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.2]
										 fromSpaceNamed:NSCalibratedRGBColorSpace];
		
		[path gtm_fillAxiallyFrom:NSMakePoint(0, NSMaxY(rect))
							   to:NSMakePoint(0, NSMidY(rect))
				   extendingStart:NO
					 extendingEnd:NO
						  shading:shading];
	}
	
	[path setClip];
	
	NSColor *strokeColor = 
    [[NSColor whiteColor] blendedColorWithFraction:0.2
                                           ofColor:midColor];
	
	[[strokeColor colorWithAlphaComponent:0.8] setStroke];
	[path setLineWidth:1.5];
	[path stroke];
}

- (void)invalidateCachedView {
	[cachedView_ release];
	cachedView_ = nil;
}

- (NSImage*)cachedView {
	if (!cachedView_) {
		cachedView_ = [[NSImage alloc] initWithSize:GTMNSRectSize([self bounds])];
		if (cachedView_) {
			[cachedView_ lockFocus];
			[self drawInternal];
			[cachedView_ unlockFocus];
		}
	}
	return cachedView_;
}

- (void)dealloc {
	[cachedView_ release];
	[super dealloc];
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	if ([self window]) {
		// when we move windows, our UI resolution may change, so update
		[self invalidateCachedView];
	}
}

- (void)drawRect:(NSRect)rect {
	[[self cachedView] drawInRect:rect
						 fromRect:rect
						operation:NSCompositeSourceOver
						 fraction:1.0f];
}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (NSColor *)backgroundColor {
	return [[backgroundColor_ retain] autorelease];
}

- (void)setBackgroundColor:(NSColor *)value {
	if (backgroundColor_ != value) {
		[backgroundColor_ release];
		backgroundColor_ = [value retain];
		[self invalidateCachedView];
		[self setNeedsDisplay:YES];
	}
}


- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];  
	[self invalidateCachedView];
}

- (BOOL)glossy {
	return glossy_;
}

- (void)setGlossy:(BOOL)value {
	if (glossy_ != value) {
		glossy_ = value;
		[self invalidateCachedView];
		[self setNeedsDisplay:YES];
	}
}



@end
