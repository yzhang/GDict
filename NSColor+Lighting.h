//
//  NSColor+Lighting.h
//
//  Copyright (c) 2008 Google Inc. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "GTMDefines.h"

enum {
  GTMColorationBaseHighlight,
  GTMColorationBaseMidtone,
  GTMColorationBaseShadow,
  GTMColorationBasePenumbra,
  GTMColorationLightHighlight,
  GTMColorationLightMidtone,
  GTMColorationLightShadow,
  GTMColorationLightPenumbra,
  GTMColorationDarkHighlight,
  GTMColorationDarkMidtone,
  GTMColorationDarkShadow,
  GTMColorationDarkPenumbra
};
typedef NSUInteger GTMColorationUse;

@interface NSColor (ColorAndLighting)

// Create a color modified by lightening or darkening it (-1.0 to 1.0)
-(NSColor *)colorWithLighting:(CGFloat)light;

// As above, but you can increase plasticity to make it
// desaturate as it gets darker or lighter
-(NSColor *)colorWithLighting:(CGFloat)light plasticity:(CGFloat)plastic;

// Returns a color adjusted for a specific usage
- (NSColor *)adjustedFor:(GTMColorationUse)use;
- (NSColor *)adjustedFor:(GTMColorationUse)use faded:(BOOL)fade;

// Returns whether the color is in the dark half of the spectrum
- (BOOL)isDarkColor;

// Returns a color that is legible on this color
-(NSColor *)legibleTextColor;
@end
