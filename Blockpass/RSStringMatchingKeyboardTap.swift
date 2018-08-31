//
//  RSStringMatchingKeyboardTap.swift
//  Blockpass
//
//  Created by Daniel Jalkut on 8/31/18.
//  Copyright © 2018 Daniel Jalkut. All rights reserved.
//

import Foundation

@objc protocol RSStringMatchingKeyboardTapDelegate {
	func keyboardTap(_ theTap: RSStringMatchingKeyboardTap, didMatchString matchingString: String) -> Void
}

class RSStringMatchingKeyboardTap: NSObject {

	weak var delegate: RSStringMatchingKeyboardTapDelegate?

	var eventTap: CFMachPort! = nil
	var stringToMatch: String
	var matchedSubstring: String

	init?(stringToMatch: String, delegate: RSStringMatchingKeyboardTapDelegate) {
		self.delegate = delegate
		self.stringToMatch = stringToMatch
		self.matchedSubstring = ""

		// Have to super.init before we can reference self for our callback
		super.init()

		let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
		let unsafeSelf: UnsafeMutableRawPointer? = Unmanaged.passUnretained(self).toOpaque()

		// We need to use this trampoline to cast the unsafe userInfo back to self, so we
		// can invoke the actual instance method.
		let myCallbackTrampoline: CGEventTapCallBack = {(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) in
			guard let userInfo = userInfo else {
				return Unmanaged.passRetained(event)
			}
			let unsafeSelf = Unmanaged<RSStringMatchingKeyboardTap>.fromOpaque(userInfo).takeUnretainedValue()
			return unsafeSelf.myKeyEventCallback(proxy: proxy, type: type, event: event)
		}

		guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly, eventsOfInterest: eventMask, callback: myCallbackTrampoline, userInfo: unsafeSelf) else {
			NSLog("Failed to initialize. Guess we're done here!")
			return nil
		}

		// Save it
		self.eventTap = eventTap

		// Schedule it
		let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
	}

	func myKeyEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
		// Get the newly typed key character
		let newKeyString = event.eventString

		// Test for accumulated match with blocked substring
		let blockedString = self.stringToMatch
		print("Got typed string \(newKeyString)")
		var runningSubstringMatch = self.matchedSubstring + newKeyString

		// Accumulate while possibly matching
		if blockedString.hasPrefix(runningSubstringMatch) {
			// Complete match? Burn everything!
			if blockedString == runningSubstringMatch {
				// Immediately reset the running substring match because the delegate might
				// actually put up a modal dialog that e.g. then fires us and we re-enter,
				// generating a false match.
				self.matchedSubstring = ""

				self.delegate?.keyboardTap(self, didMatchString: runningSubstringMatch)

				runningSubstringMatch = ""
			}
		}
		else {
			// No match, start over
			runningSubstringMatch = ""
		}

		self.matchedSubstring = runningSubstringMatch

		return Unmanaged.passRetained(event)
	}
}
