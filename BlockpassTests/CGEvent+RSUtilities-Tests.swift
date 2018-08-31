//
//  CGEvent+RSUtilities-Tests.swift
//  Blockpass
//
//  Created by Daniel Jalkut on 8/31/18.
//  Copyright © 2018 Daniel Jalkut. All rights reserved.
//

import XCTest

enum TestingError: Error {
	case genericError
}

class CGEvent_RSUtilities_Tests: XCTestCase {

	// Only works with ASCII chars
	func fakeEventWithKeycode(_ keyCode: CGKeyCode) -> CGEvent {
		return CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)!
	}

	func testUpperCharacterStringExtraction() {
		let keyCode = CGKeyCode(38) // J
		let fakeEvent = fakeEventWithKeycode(keyCode)
		fakeEvent.flags = [.maskShift]
		XCTAssertEqual("J", fakeEvent.eventString)
	}

	func testLowerCharacterStringExtraction() {
		let keyCode = CGKeyCode(38) // J
		let fakeEvent = fakeEventWithKeycode(keyCode)
		XCTAssertEqual("j", fakeEvent.eventString)
	}

	func testNumericStringExtraction() {
		let keyCode = CGKeyCode(20) // 3
		let fakeEvent = fakeEventWithKeycode(keyCode)
		XCTAssertEqual("3", fakeEvent.eventString)
	}

}
