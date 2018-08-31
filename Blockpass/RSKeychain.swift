//
//  RSKeychain.swift
//  Blockpass
//
//  Created by Daniel Jalkut on 8/31/18.
//  Copyright © 2018 Daniel Jalkut. All rights reserved.
//

import Foundation

struct RSKeychain {
	internal static func setSecureBytes(_ bytePointer: UnsafeRawPointer!, length byteLength: UInt, forItemName keychainItemName: String, accountName: String) {

		var defaultKeychain: SecKeychain! = nil
		if SecKeychainCopyDefault(&defaultKeychain) == noErr {
			var shouldAddNewItem = true

			let keychainItemNameCString = (keychainItemName as NSString).utf8String
			let keychainItemNameLength = UInt32(strlen(keychainItemNameCString))

			let accountNameCString = (accountName as NSString).utf8String
			let accountNameLength = UInt32(strlen(accountNameCString))

			// Update an existing item if we have one
			var keychainItemRef: SecKeychainItem? = nil
			if (SecKeychainFindGenericPassword(nil, keychainItemNameLength, keychainItemNameCString, accountNameLength, accountNameCString, nil, nil, &keychainItemRef) == noErr),
				let keychainItemRef = keychainItemRef {
				if SecKeychainItemModifyContent(keychainItemRef, nil, UInt32(byteLength), bytePointer) == noErr {
					shouldAddNewItem = false
				}
			}

			if shouldAddNewItem {
				SecKeychainAddGenericPassword(defaultKeychain, keychainItemNameLength, keychainItemNameCString, accountNameLength, accountNameCString, UInt32(byteLength), bytePointer, nil)
			}
		}
	}

	public static func secureData(forItemName keychainItemName: String, accountName: String) -> Data? {
		var foundData: Data? = nil

		let keychainItemNameCString = (keychainItemName as NSString).utf8String
		let keychainItemNameLength = UInt32(strlen(keychainItemNameCString))

		let accountNameCString = (accountName as NSString).utf8String
		let accountNameLength = UInt32(strlen(accountNameCString))

		var secureDataLength: UInt32 = 0
		var secureData: UnsafeMutableRawPointer? = nil
		let secureErr = SecKeychainFindGenericPassword(nil, keychainItemNameLength, keychainItemNameCString, accountNameLength, accountNameCString, &secureDataLength, &secureData, nil)
		if secureErr == noErr,
			let secureData = secureData
		{
			foundData = Data(bytes: secureData, count: Int(secureDataLength))
		}
		else {
			if secureErr != errSecItemNotFound {
				NSLog("Got error %d trying to access password in keychain for %@/%@", secureErr, keychainItemName, accountName);
			}
		}
		return foundData
	}

	public static func setSecureString(_ newString: String, forItemName keychainItemName: String, accountName: String) {
		let secureString = (newString as NSString).utf8String
		self.setSecureBytes(secureString, length: UInt(strlen(secureString)), forItemName: keychainItemName, accountName: accountName)
	}

	public static func secureString(forItemName keychainItemName: String, accountName: String) -> String? {
		guard
			let secureData = self.secureData(forItemName: keychainItemName, accountName: accountName),
			let secureString = String(data: secureData, encoding: .utf8)
		else {
			return nil
		}

		return secureString
	}
}
