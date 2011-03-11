//
//  NSAttributedString+Attributes.h
//
//  Functions for working with attributes in NSAttributedStrings
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

#import "NSAttributedString+Attributes.h"

@implementation NSAttributedString (QSBAttributedStringAttributeAdditions)
+ (id)attrStringWithString:(NSString*)string {
  return [self attrStringWithString:string attributes:nil];
}

+ (id)attrStringWithString:(NSString*)string
                attributes:(NSDictionary*)attributes {
  if (!string) return nil;
  id attrString;
  
  if (!attributes) {
    attrString = [[self alloc] initWithString:string];
  } else {
    attrString = [[self alloc] initWithString:string attributes:attributes];
  }
  return [attrString autorelease];
}
@end

@implementation NSMutableAttributedString(QSBAttributedStringAttributeAdditions)

- (void)addAttribute:(NSString *)name value:(id)value {
  if (name && value) {
    NSUInteger length = [self length];
    if (length > 0) {
      NSRange range = NSMakeRange(0, length);
      [self addAttribute:name value:value range:range];
      [self fixAttributesInRange:range];          
    }
  }
}

- (void)addAttributes:(NSDictionary *)attrs {
  if (attrs) {
    NSUInteger length = [self length];
    if (length > 0) {
      NSRange range = NSMakeRange(0, length);
      [self beginEditing];
      [self addAttributes:attrs range:range];
      [self fixAttributesInRange:range];
      [self endEditing];    
    }
  }
}

- (void)addAttributes:(NSDictionary *)attrs 
           fontTraits:(NSFontTraitMask)traits
    toTextDelimitedBy:(NSString*)preDelimiter 
        postDelimiter:(NSString*)postDelimiter {
  if (preDelimiter 
      && postDelimiter
      && [preDelimiter length] > 0
      && [postDelimiter length] > 0) {
    [self beginEditing];
    NSString *plainText = [self string];
    NSRange aRange = NSMakeRange(0,[plainText length]);
    while (aRange.location != NSNotFound) {
      NSRange startRange = [plainText rangeOfString:preDelimiter 
                                            options:NSCaseInsensitiveSearch 
                                              range:aRange];
      if (startRange.location != NSNotFound) {
        aRange.length -= startRange.length + startRange.location - aRange.location;
        aRange.location = startRange.location + startRange.length;
      
        NSRange endRange = [plainText rangeOfString:postDelimiter 
                                            options:NSCaseInsensitiveSearch 
                                              range:aRange];
        if (endRange.location != NSNotFound) {
          aRange.location = endRange.location - startRange.length;
          NSRange attrRange = NSMakeRange(startRange.location, aRange.location - startRange.location);
          [self deleteCharactersInRange:endRange];
          [self deleteCharactersInRange:startRange];
          plainText = [self string];
          if (traits != 0) {
            [self applyFontTraits:traits range:attrRange];
          }
          if (attrs != 0) {
            [self addAttributes:attrs range:attrRange];
          }
          if (traits != 0 && attrs != 0) {
            [self fixAttributesInRange:attrRange];
          }
          // we could have nested tags, so we have to continue the search
          // from the start, not from the end.
          aRange.location = startRange.location;
          aRange.length = [self length] - aRange.location;
        }
        else {
          aRange.location = NSNotFound;
        }
      }
      else {
        aRange.location = NSNotFound;
      }
      
    }
    [self endEditing];
  }
}

@end
