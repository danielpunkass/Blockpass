//
//  RSStringMatchingKeyboardTap.h
//  Blockpass
//
//  Created by Daniel Jalkut on 11/21/14.
//  Copyright (c) 2014 Daniel Jalkut. All rights reserved.
//

// NOTE: It is expected that the client of this class will assert and/or arrange
// for the user to grant permission to use "assistive devices" functionality e.g.
// as checkable and grantable via the AXIsProcessTrustedWithOptions function.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class RSStringMatchingKeyboardTap;

@protocol RSStringMatchingKeyboardTapDelegate

- (void) keyboardTap:(RSStringMatchingKeyboardTap*)theTap didMatchString:(NSString*)theString;

@end

@interface RSStringMatchingKeyboardTap : NSObject

@property (assign) id<RSStringMatchingKeyboardTapDelegate> delegate;

@property CFMachPortRef eventTap;
@property NSString* stringToMatch;
@property NSString* matchedSubstring;

- (instancetype) initWithString:(NSString*)stringToMatch delegate:(id<RSStringMatchingKeyboardTapDelegate>) delegate;

@end
