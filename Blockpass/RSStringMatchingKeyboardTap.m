//
//  RSStringMatchingKeyboardTap.m
//  Blockpass
//
//  Created by Daniel Jalkut on 11/21/14.
//  Copyright (c) 2014 Daniel Jalkut. All rights reserved.
//

#import "RSStringMatchingKeyboardTap.h"

// For TIS stuff
#import <Carbon/Carbon.h>

@implementation RSStringMatchingKeyboardTap

// From http://stackoverflow.com/questions/9458017/convert-cgkeycode-to-character
CFStringRef copyStringForEvent(CGEventRef event)
{
    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
    CFDataRef layoutData =
    TISGetInputSourceProperty(currentKeyboard,
                              kTISPropertyUnicodeKeyLayoutData);
    const UCKeyboardLayout *keyboardLayout =
    (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);

    UInt32 keysDown = 0;
    UniChar chars[4];
    UniCharCount realLength;

    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    CGEventFlags modifiers = CGEventGetFlags(event);
    static const CGEventFlags cmdModifiers = kCGEventFlagMaskCommand | kCGEventFlagMaskControl | kCGEventFlagMaskAlternate;
    modifiers &= ~cmdModifiers;
    
    UCKeyTranslate(keyboardLayout,
               keyCode,
               kUCKeyActionDisplay,
               (modifiers >> 16) & 0xFF,
               LMGetKbdType(),
               kUCKeyTranslateNoDeadKeysBit,
               &keysDown,
               sizeof(chars) / sizeof(chars[0]),
               &realLength,
               chars);
    CFRelease(currentKeyboard);

    return CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 1);
}

CGEventRef myKeyEventCallback(CGEventTapProxy proxy,
  CGEventType type, CGEventRef event, void *userInfo)
{
	RSStringMatchingKeyboardTap* theTap = (__bridge RSStringMatchingKeyboardTap*)userInfo;

	// Get the newly typed key character
    NSString* newKeyString = CFBridgingRelease(copyStringForEvent(event));

	// Test for accumulated match with blocked substring
	NSString* blockedString = [theTap stringToMatch];
	NSString* runningSubstringMatch = [[theTap matchedSubstring] stringByAppendingString:newKeyString];

	if ([blockedString hasPrefix:runningSubstringMatch])
	{
		// Complete match? burn everything!
		if ([blockedString isEqualToString:runningSubstringMatch])
		{
			// Immediately reset the running substring match because the delegate might
			// actually put up a modal dialog that e.g. then fires us and we re-enter,
			// generating a false match
			[theTap setMatchedSubstring:@""];
			[theTap notifyDelegateOfMatchedString:runningSubstringMatch];
		}
	}
	else
	{
		runningSubstringMatch = @"";
	}

	[theTap setMatchedSubstring:runningSubstringMatch];

	return event;
}

- (instancetype) initWithString:(NSString*)stringToMatch delegate:(id<RSStringMatchingKeyboardTapDelegate>) delegate
{
    if (self = [super init])
	{
		[self setMatchedSubstring:@""];
		[self setStringToMatch:stringToMatch];
		[self setDelegate:delegate];

		CFMachPortRef newEventTap = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly,
CGEventMaskBit(kCGEventKeyDown), myKeyEventCallback, (__bridge void*)self);
		if (newEventTap != NULL)
		{
			CFRunLoopSourceRef newRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newEventTap, 0);
			CFRunLoopAddSource(CFRunLoopGetCurrent(), newRunLoopSource, kCFRunLoopCommonModes);
			CFRelease(newRunLoopSource);

			[self setEventTap:newEventTap];
		}
		else
		{
			NSLog(@"Failed to install event tap! Maybe the app doesn't have access to assistive devices?");
			self = nil;
		}
    }
    return self;
}

- (void)dealloc
{
    CFRelease(_eventTap);
	_eventTap = NULL;
}

- (void) notifyDelegateOfMatchedString:(NSString*)matchedString
{
	[[self delegate] keyboardTap:self didMatchString:matchedString];
}

@end
