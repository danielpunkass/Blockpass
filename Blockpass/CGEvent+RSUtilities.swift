//
//  CGEvent+RSUtilities.swift
//  Blockpass
//
//  Created by Daniel Jalkut on 8/31/18.
//  Copyright © 2018 Daniel Jalkut. All rights reserved.
//

import Foundation
import Carbon

// Based on http://stackoverflow.com/questions/9458017/convert-cgkeycode-to-character
extension CGEvent {
	var eventString: String {
		// If control or command is down, don't try to interpret the keystroke as typing
		let ignoredModifiers: CGEventFlags = [.maskControl, .maskCommand]
		guard self.flags.intersection(ignoredModifiers).isEmpty else {
			return ""
		}

		guard
			let currentKeyboard = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
			let layoutDataPtr = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)
		else {
			return ""
		}

		// Unicode 4 character code should be the maximum case
		let maxCharacterLength = 4
		var keysDown: UInt32 = 0
		var eventCharacters = [UniChar](repeating: 0, count: maxCharacterLength)
		var actualCharacterLength: Int = 0

		let layoutData = Unmanaged<CFData>.fromOpaque(layoutDataPtr).takeUnretainedValue() as Data
		let keyTranslationErr: OSStatus = layoutData.withUnsafeBytes { (unsafeLayoutData: UnsafePointer<UCKeyboardLayout>) -> OSStatus in
			let keyCode = self.getIntegerValueField(.keyboardEventKeycode)

			let modifierKeyState = UInt32(((self.flags.rawValue) >> 16) & 0xFF)
			return UCKeyTranslate(unsafeLayoutData, UInt16(keyCode), UInt16(kUCKeyActionDisplay), modifierKeyState, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &keysDown, maxCharacterLength, &actualCharacterLength, &eventCharacters)
		}

		guard keyTranslationErr == noErr else {
			return ""
		}

		return CFStringCreateWithCharacters(kCFAllocatorDefault, eventCharacters, 1) as String
	}
}

