//
//  QSBTextField.m
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

#import "QSBTextField.h"
#import <objc/message.h>
#import "GTMMethodCheck.h"
#import "GTMNSNumber+64Bit.h"
#import "NSString+CaseInsensitive.h"
#import "NSAttributedString+Attributes.h"

static const CGFloat kQSBTextFieldCursorInset = 6;
static const CGFloat kQSBTextFieldLineHeight = 30;
static const CGFloat kQSBTextFieldTextBaselineOffset = 20;

@interface QSBTextField ()
- (BOOL)isAtEnd;
- (BOOL)isAtEndOfPivots;
- (void)deleteCompletion;
- (void)handleMoveBack:(id)sender command:(SEL)command;
- (void)handleMoveForward:(id)sender command:(SEL)command;

- (NSString*) completion;
@end

@interface NSTextView (QSBNSTextViewPrivates)
// Undocument API. We override it because it is called (instead of
// drawInsertionPointInRect:color:turnedOn:) for the first blink of the cursor,
// and we don't want that first blink looking funny.
- (void)_drawInsertionPointInRect:(NSRect)arg1 color:(NSColor *)arg2;
@end

@interface NSAttributedString (QSBTextField)
// Return the range of pivot attachments in a attributed string.
- (NSRange)qsb_rangeOfPivotAttachments;
@end

@interface QSBTypesetter : NSATSTypesetter
@end

@implementation QSBTypesetter

- (void)willSetLineFragmentRect:(NSRect *)lineRect
                  forGlyphRange:(NSRange)glyphRange
                       usedRect:(NSRect *)usedRect
                 baselineOffset:(CGFloat *)baselineOffset {
  lineRect->size.height = kQSBTextFieldLineHeight;
  usedRect->size.height = kQSBTextFieldLineHeight;
  *baselineOffset = kQSBTextFieldTextBaselineOffset;
}

@end


@implementation QSBTextField

GTM_METHOD_CHECK(NSString, qsb_hasPrefix:options:)
GTM_METHOD_CHECK(NSAttributedString, attrStringWithString:attributes:);

- (void)awakeFromNib {
  [self setEditable:YES];
  [self setFieldEditor:YES];
  [self setSelectable:YES];

  NSTextContainer *container = [self textContainer];
  [container setWidthTracksTextView:NO];
  [container setHeightTracksTextView:NO];
  [container setContainerSize:NSMakeSize(1.0e7, 1.0e7)];

  NSLayoutManager *layoutMgr = [self layoutManager];
  QSBTypesetter *setter = [[[QSBTypesetter alloc] init] autorelease];
  [layoutMgr setTypesetter:setter];
}

#pragma mark NSResponder overrides

#if 0
// Useful chunk of debugging code when you are trying to figure out what
// command is being sent by a key combination.
- (void)doCommandBySelector:(SEL)aSelector {
  HGSLog(@"%@", NSStringFromSelector(aSelector));
  [super doCommandBySelector:aSelector];
}
#endif  // 0

- (void)keyDown:(NSEvent *)theEvent {
  [self deleteCompletion];
  [super keyDown:theEvent];
}

- (void)copy:(id)sender {
  BOOL handled = NO;
  if ([self selectedRange].length == 0) {
    NSResponder *nextResponder = [self nextResponder];
    handled = [nextResponder tryToPerform:_cmd with:sender];
  }
  if (!handled) {
    [super copy:sender];
  }
}

- (void)moveRight:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveWordRight:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveRightAndModifySelection:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveWordRightAndModifySelection:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveWordForward:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveForwardAndModifySelection:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveWordForwardAndModifySelection:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveToEndOfLine:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveToEndOfLineAndModifySelection:(id)sender {
  [self handleMoveForward:sender command:_cmd];
}

- (void)moveLeft:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveWordLeft:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveLeftAndModifySelection:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveWordLeftAndModifySelection:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveWordBackward:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveBackwardAndModifySelection:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveWordBackwardAndModifySelection:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveToBeginningOfLine:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)moveToBeginningOfLineAndModifySelection:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)deleteBackward:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)deleteBackwardByDecomposingPreviousCharacter:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)deleteWordBackward:(id)sender {
  [self handleMoveBack:sender command:_cmd];
}

- (void)deleteToBeginningOfLine:(id)sender {
  [NSApp sendAction:@selector(qsb_clearSearchString:)
                                to:nil from:self];
}

- (void)deleteToBeginningOfParagraph:(id)sender {
  [NSApp sendAction:@selector(qsb_clearSearchString:)
                                to:nil from:self];
}

- (void)insertTab:(id)sender {
	NSLog(@"insert Tab");
  if (![[NSApp currentEvent] isARepeat]) {
	  NSLog(@"inserted");
	  [super setString:[self completion]];
    //[NSApp sendAction:@selector(qsb_pivotOnSelection:)
     //                             to:nil from:self];
  }
}

- (void)insertTabIgnoringFieldEditor:(id)sender {
  return [self insertTab:sender];
}

- (void)insertBacktab:(id)sender {
  if (![[NSApp currentEvent] isARepeat]) {
    [NSApp sendAction:@selector(qsb_unpivotOnSelection:)
                                  to:nil from:self];
  }
}

#pragma mark NSUserInterfaceValidations Protocol

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
  BOOL validated = NO;
  if ([anItem action] == @selector(copy:)) {
    NSResponder *nextResponder = [self nextResponder];
    validated = [nextResponder tryToPerform:_cmd with:anItem];
  } else {
    validated = [super validateUserInterfaceItem:anItem];
  }
  return validated;
}

#pragma mark NSTextView Overrides

- (NSDictionary *)typingAttributes {
  NSDictionary *typingAttributes = [super typingAttributes];
  NSMutableDictionary *newAttributes
    = [NSMutableDictionary dictionaryWithDictionary:typingAttributes];
  [newAttributes setObject:[NSNumber numberWithInt:0]
                    forKey:NSBaselineOffsetAttributeName];
  [newAttributes setObject:[NSFont systemFontOfSize:[NSFont systemFontSize]]
                    forKey:NSFontAttributeName];
  return newAttributes;
}

- (void)didChangeText {
  [super didChangeText];
  [self complete:self];
}

- (NSString*) completion {
	NSTextStorage *storage = [self textStorage];
	NSRange range = NSMakeRange(0, [storage length]);
	NSInteger idx = 0;
	NSArray *completions = [self completionsForPartialWordRange:range
											indexOfSelectedItem:&idx];
	if ([completions count]) {
		return [completions objectAtIndex:0];
	}
	return @"";
}

- (void)complete:(id)sender {
  [self deleteCompletion];
  NSTextStorage *storage = [self textStorage];
  NSRange range = NSMakeRange(0, [storage length]);

  if ([[self completion] length]) {
    [self insertCompletion:[self completion]
       forPartialWordRange:range
                  movement:0
                   isFinal:YES];
  }
}

- (void)insertCompletion:(NSString *)completion
     forPartialWordRange:(NSRange)charRange
                movement:(NSInteger)movement
                 isFinal:(BOOL)flag {
  if ([self hasMarkedText]) {
    return;
  }
  if ([completion length]) {
    NSTextStorage *storage = [self textStorage];
    NSArray *selection = [self selectedRanges];
    NSRange stringRange = NSMakeRange(0, [storage length]);
    [storage beginEditing];

    NSString *typedString = [[self string] substringWithRange:charRange];
    NSRange substringRange
      = [completion rangeOfString:typedString
                          options:(NSWidthInsensitiveSearch
                                   | NSCaseInsensitiveSearch
                                   | NSDiacriticInsensitiveSearch)];

    // If this string isn't found at the beginning or with a space prefix,
    // find the range of the last word and proceed with that.
    if (substringRange.location == NSNotFound || (substringRange.location &&
            [completion characterAtIndex:substringRange.location - 1] != ' ')) {
      NSString *lastWord =
      [[typedString componentsSeparatedByString:@" "] lastObject];
      substringRange
        = [completion rangeOfString:lastWord
                            options:(NSWidthInsensitiveSearch
                                     | NSCaseInsensitiveSearch
                                     | NSDiacriticInsensitiveSearch)];
    }

    NSString *wordCompletion = @"";

    // Make sure we don't capitalize what the user typed
    if (substringRange.location == 0
        && [completion length] >= stringRange.length) {

      completion = [typedString stringByAppendingString:
                     [completion substringFromIndex:stringRange.length]];

    // if our search string appears at the beginning of a word later in the
    // string, pull the remainder of the word out as a completion
    } else if (substringRange.location != NSNotFound
               && substringRange.location
               && [completion characterAtIndex:substringRange.location - 1] == ' ') {
      NSRange wordRange = NSMakeRange(NSMaxRange(substringRange),
                              [completion length] - NSMaxRange(substringRange));
      // Complete the current word
      NSRange nextSpaceRange = [completion rangeOfString:@" "
                                                 options:0
                                                   range:wordRange];

      if (nextSpaceRange.location != NSNotFound)
        wordRange.length = nextSpaceRange.location - wordRange.location;

      wordCompletion = [completion substringWithRange:wordRange];
    }

    NSString *textFieldString = [storage string];
    if ([completion qsb_hasPrefix:textFieldString
                          options:(NSWidthInsensitiveSearch
                                   | NSCaseInsensitiveSearch
                                   | NSDiacriticInsensitiveSearch)]) {
      [storage replaceCharactersInRange:charRange withString:completion];
      lastCompletionRange_ = NSMakeRange(NSMaxRange(stringRange),
                                         [completion length] - charRange.length);
    } else {
      NSString *appendString = [NSString stringWithFormat:@"%@ (%@)",
                                                          wordCompletion,
                                                          completion];
      NSUInteger length = [storage length];
      [storage replaceCharactersInRange:NSMakeRange(length, 0)
                             withString:appendString];
      lastCompletionRange_ = NSMakeRange(length, [appendString length]);
    }

    [storage addAttribute:NSForegroundColorAttributeName
                    value:[NSColor lightGrayColor]
                    range:lastCompletionRange_];
    // Allow ligatures but then beat them into submission over
    // the auto-completion.
    if (lastCompletionRange_.location > 0 && lastCompletionRange_.length > 0) {
      NSUInteger fullLength = NSMaxRange(lastCompletionRange_);
      NSRange ligatureRange = NSMakeRange(0, fullLength);
      [storage addAttribute:NSLigatureAttributeName
                      value:[NSNumber numberWithInt:1]
                      range:ligatureRange];
      // De-ligature over the typed/autocompleted transition.
      [storage addAttribute:NSLigatureAttributeName
                      value:[NSNumber numberWithInt:0]
                      range:lastCompletionRange_];
    }
    [storage endEditing];
    [self setSelectedRanges:selection];
  }
}

- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color {
  NSScrollView *view = [self enclosingScrollView];
  NSRect visibleRect = [view documentVisibleRect];
  rect.origin.y = NSMinY(visibleRect) + kQSBTextFieldCursorInset;
  rect.size.height = NSHeight(visibleRect) - (kQSBTextFieldCursorInset * 2);
  [super _drawInsertionPointInRect:rect color:color];
}

- (void)drawInsertionPointInRect:(NSRect)rect
                           color:(NSColor *)color
                        turnedOn:(BOOL)flag {
  NSScrollView *view = [self enclosingScrollView];
  NSRect visibleRect = [view documentVisibleRect];
  rect.origin.y = NSMinY(visibleRect) + kQSBTextFieldCursorInset;
  rect.size.height = NSHeight(visibleRect) - (kQSBTextFieldCursorInset * 2);
  [super drawInsertionPointInRect:rect color:color turnedOn:flag];
}

- (void)setString:(NSString *)string {
  if (!string) {
    string = @"";
  }

  NSAttributedString *attrString
    = [NSAttributedString attrStringWithString:string
                                    attributes:[self typingAttributes]];
  NSTextStorage *storage = [self textStorage];
  NSRange rangeOfPivotAttachments
    = [[self textStorage] qsb_rangeOfPivotAttachments];
  [storage beginEditing];
  NSRange replaceRange = NSMakeRange(0, [storage length]);
  replaceRange.length -= NSMaxRange(rangeOfPivotAttachments);
  replaceRange.location = NSMaxRange(rangeOfPivotAttachments);
  [storage replaceCharactersInRange:replaceRange withAttributedString:attrString];
  [storage endEditing];
}

- (void)setSelectedRanges:(NSArray *)rangeValues
                 affinity:(NSSelectionAffinity)affinity
           stillSelecting:(BOOL)stillSelectingFlag {
  NSRange rangeOfPivotAttachments
    = [[self textStorage] qsb_rangeOfPivotAttachments];
  NSString *fullString = [self string];
  NSMutableArray *newRangeValues
    = [NSMutableArray arrayWithCapacity:[rangeValues count]];
  for (NSValue *rangeValue in rangeValues) {
    NSRange range = [rangeValue rangeValue];

    // Keep the selection out of our pivot attachments
    if (rangeOfPivotAttachments.length) {
      if (range.location < rangeOfPivotAttachments.length) {
        if (range.length > rangeOfPivotAttachments.length) {
          range.length -= rangeOfPivotAttachments.length;
        } else {
          range.length = 0;
        }
        range.location = rangeOfPivotAttachments.length;
      }
    }

    // Keep the selection out of our completion range.
    if (lastCompletionRange_.length != 0) {
      if (lastCompletionRange_.location < NSMaxRange(range)) {
        if (range.location >= lastCompletionRange_.location) {
          range.location = lastCompletionRange_.location;
        }
        range.length = lastCompletionRange_.location - range.location;
      }
    }

    // Adjust the selection ranges to prevent mid-glyph selections.
    // Insure that the selection range does not start or end in the middle of
    // a composed character sequence.  If the selection is of zero length then
    // adjust the selection start forwards, otherwise adjust the selection start
    // backwards and the selection end forwards.
    if (NSMaxRange(range) < [fullString length]) {
      // Adjust the selection start.
      NSRange adjustedRange
        = [fullString rangeOfComposedCharacterSequenceAtIndex:range.location];
      if (range.length) {
        // Adjust the selection end forward.
        NSUInteger selectionEnd = NSMaxRange(range) - 1;
        NSRange newEndRange
          = [fullString rangeOfComposedCharacterSequenceAtIndex:selectionEnd];
        NSUInteger adjustedSelectionEnd = NSMaxRange(newEndRange);
        adjustedRange.length = adjustedSelectionEnd - adjustedRange.location;
      } else {
        // When we have an empty selection and the adjusted length
        // is more than one character and start location has changed then
        // adjust selection start forward.
        if (adjustedRange.location != range.location
            && adjustedRange.length > 1) {
          adjustedRange.location += adjustedRange.length;
        }
        adjustedRange.length = 0;
      }
      range = adjustedRange;
    }

    [newRangeValues addObject:[NSValue valueWithRange:range]];
  }
  [super setSelectedRanges:newRangeValues
                  affinity:affinity
            stillSelecting:stillSelectingFlag];
}

#pragma mark NSDragging Overrides

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
  [self deleteCompletion];
  return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
  [self complete:self];
  [super draggingExited:sender];
}

#pragma mark Private Methods

- (BOOL)isAtEnd {
  BOOL isatEnd = NO;
  NSRange range = [self selectedRange];
  if (range.length == 0) {
    if (lastCompletionRange_.location > 0) {
      isatEnd = range.location >= lastCompletionRange_.location;
    } else {
      isatEnd = range.location == [[self string] length];
    }
  }
  return isatEnd;
}

- (BOOL)isAtEndOfPivots {
  NSRange range = [self selectedRange];
  return (range.length == 0
          && (range.location
              == NSMaxRange([[self textStorage] qsb_rangeOfPivotAttachments])));
}

- (void)deleteCompletion {
  if (lastCompletionRange_.length > 0) {
    NSTextStorage *storage = [self textStorage];
    NSRange intersection = NSIntersectionRange(lastCompletionRange_,
                                               NSMakeRange(0, [storage length]));

    if (intersection.length > 0) {
      [storage beginEditing];
      [storage deleteCharactersInRange:intersection];
      [storage endEditing];
    }
  }
  lastCompletionRange_ = NSMakeRange(0, 0);
}

- (void)handleMoveBack:(id)sender command:(SEL)command {
  if ([self isAtEndOfPivots] && ![[NSApp currentEvent] isARepeat]) {
    [NSApp sendAction:@selector(qsb_unpivotOnSelection:)
                                  to:nil from:self];
  } else {
    struct objc_super superData = { self, class_getSuperclass([self class]) };
    objc_msgSendSuper(&superData, command, sender);
  }
}

- (void)handleMoveForward:(id)sender command:(SEL)command {
  if ([self isAtEnd] && ![[NSApp currentEvent] isARepeat]) {
    [NSApp sendAction:@selector(qsb_pivotOnSelection:)
                                  to:nil from:self];
  } else {
    struct objc_super superData = { self, class_getSuperclass([self class]) };
    objc_msgSendSuper(&superData, command, sender);
  }
}

#pragma mark Public Methods

- (void)setAttributedStringValue:(NSAttributedString *)pivotString {
  // Shift the baseline
  NSUInteger pivotLength = [pivotString length];
  NSMutableAttributedString *mutablePivotString
    = [[pivotString mutableCopy] autorelease];
  NSRange rangeOfPivotAttachments = [pivotString qsb_rangeOfPivotAttachments];
  NSNumber *baseLine
    = [NSNumber gtm_numberWithCGFloat:(kQSBTextFieldTextBaselineOffset
                                       - kQSBTextFieldLineHeight)];

  // Set our attributes appropriately so that our text and pivots look correct.
  [mutablePivotString addAttributes:[self typingAttributes]];
  [mutablePivotString addAttribute:NSBaselineOffsetAttributeName
                             value:baseLine
                             range:rangeOfPivotAttachments];

  // set it
  NSTextStorage *storage = [self textStorage];
  [storage beginEditing];
  [storage replaceCharactersInRange:NSMakeRange(0, [storage length])
               withAttributedString:mutablePivotString];
  [storage endEditing];
  [self scrollRangeToVisible:NSMakeRange(pivotLength, 1)];
}

- (NSString *)stringWithoutPivots {
  NSString *string = [self string];
  NSRange range = [[self textStorage] qsb_rangeOfPivotAttachments];
  string = [string substringFromIndex:NSMaxRange(range)];
  return string;
}

@end

@implementation NSAttributedString (QSBTextField)

- (NSRange)qsb_rangeOfPivotAttachments {
  NSString *string = [self string];
  NSString *attachmentString = [NSString stringWithFormat:@"%C",
                                NSAttachmentCharacter];
  NSRange range = [string rangeOfString:attachmentString
                                options:NSBackwardsSearch];
  if (range.location != NSNotFound) {
    range.length += range.location;
    range.location = 0;
  } else {
    range.location = 0;
    range.length = 0;
  }
  return range;
}

@end

