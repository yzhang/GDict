//
//  NSString+CaseInsensitive.m
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

#import "NSString+CaseInsensitive.h"

@implementation NSString (GMNSStringCaseInsensitiveAdditions)

- (BOOL)qsb_hasPrefix:(NSString *)aString 
              options:(NSStringCompareOptions)options {
  return ([self length] >= [aString length]) &&
    ([self compare:aString
           options:options 
             range:NSMakeRange(0, [aString length])] == NSOrderedSame);}

- (BOOL)qsb_hasSuffix:(NSString *)aString 
              options:(NSStringCompareOptions)options {
  NSUInteger aLength = [aString length];
  NSUInteger bLength = [self length];
  NSInteger start = bLength - aLength;
  
  return start < 0 ? NO : [self compare:aString
                                options:options 
                                  range:NSMakeRange(start, 
                                                    aLength)] == NSOrderedSame;
}

- (BOOL)qsb_contains:(NSString *)aString 
             options:(NSStringCompareOptions)options {
  return [self rangeOfString:aString 
                     options:options].location != NSNotFound;
}
@end
