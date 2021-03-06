//
//  AppDelegate.swift
//  Blockpass
//
//  Created by Daniel Jalkut on 11/21/14.
//  Copyright (c) 2014 Daniel Jalkut. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, RSStringMatchingKeyboardTapDelegate
{
	@IBOutlet weak var passwordPrompt : NSPanel?
	@IBOutlet weak var secureStringTextField : NSSecureTextField?

	var myPasswordBlocker : RSStringMatchingKeyboardTap? = nil

	var passwordPromptNibObjects : NSArray? = nil

	let keychainItemName = "Blockpass"
	let keychainAccountName = "main password"

	func saveSecretTextToKeychain(_ secretText : String) -> Void
	{
		RSKeychain.setSecureString(secretText, forItemName:keychainItemName, accountName:keychainAccountName)
	}

	func getSecretTextFromKeychain() -> String?
	{
		return RSKeychain.secureString(forItemName: keychainItemName, accountName:keychainAccountName)
	}

	@IBAction func dismissPasswordPrompt(_ sender: AnyObject)
	{
		let response = NSApplication.ModalResponse(sender.tag)
		NSApp.stopModal(withCode: response)
	}

	func passwordByPromptingUser() -> String?
	{
		var userPassword : String? = nil

		if (self.passwordPrompt == nil)
		{
			let panelNib : NSNib = NSNib(nibNamed:"PasswordPromptPanel", bundle:nil)!
		    panelNib.instantiate(withOwner: self, topLevelObjects: &passwordPromptNibObjects)
		}

		let thePrompt = self.passwordPrompt!
		// Present the panel modally and at high layer since we're a faceless background app
		thePrompt.center()

		thePrompt.level = .statusBar

		thePrompt.makeKeyAndOrderFront(nil)

		let promptStatus = NSApp.runModal(for: thePrompt)
		if (promptStatus == .OK)
		{
			userPassword = self.secureStringTextField!.stringValue
		}

		thePrompt.orderOut(nil)

		// Prompt here and if it's "" then change to nil
		return userPassword
	}

	func applicationDidFinishLaunching(_ aNotification: Notification)
	{
		// Make sure we have ability to intercept keys
		let promptFlag = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
		let myDict: CFDictionary = NSDictionary(dictionary: [promptFlag: true])
		AXIsProcessTrustedWithOptions(myDict)

		// Unfortunately the prompting mechanism doesn't seem to work from an LSUIElement app
		if (!AXIsProcessTrustedWithOptions(myDict))
		{
			NSLog("Don't have accessibility access, so we're prompting...")
			let warnAlert = NSAlert()
			warnAlert.messageText = "Blockpass relies upon having permission to 'control your computer'. If the permission prompt did not appear automatically, go to System Preferences, Security & Privacy, Privacy, Accessibility, and add Blockpass to the list of allowed apps. Then relaunch Blockpass.";
			warnAlert.layout()
			let warnPanel = warnAlert.window as! NSPanel
			warnPanel.level = .statusBar
 			warnAlert.runModal();
		    NSApp.terminate(nil)
		}
		else
		{
			var matchedString : String? = getSecretTextFromKeychain()

			// Override keychain stored value if option key is held down
		    let keyFlags = NSEvent.modifierFlags

		    let overrideKeychain = keyFlags.contains(.option)

			if ((matchedString == nil) || overrideKeychain)
			{
				let newMatchedString = passwordByPromptingUser()
				if (newMatchedString == nil)
				{
					NSLog("User declined to supply a new password string...")
				}
				else
				{
					matchedString = newMatchedString
					saveSecretTextToKeychain(matchedString!)
				}
			}

			// If we still don't have a string to match on, just quit
			guard let actualMatchedString = matchedString else {
				NSLog("No stored password and no user-supplied password. Quitting…")
				NSApp.terminate(nil)
				return
			}

			myPasswordBlocker = RSStringMatchingKeyboardTap(stringToMatch: actualMatchedString, delegate:self)
		}

		// Register our default ignored app identifiers
		let defaultIgnoredApps : [String] = ["com.apple.ScreenSharing"]
		UserDefaults.standard.register(defaults: ["IgnoredAppIdentifiers": defaultIgnoredApps])
	}

	func applicationWillTerminate(aNotification: NSNotification)
	{
		// Insert code here to tear down your application
	}

	func shouldIgnoreMatches() -> Bool
	{
		// Work around problems where Terminal password entry (e.g. sudo prompt) and Screen Sharing
		// (e.g. legitimate secure entry into Screen Sharing app) cause false alarms because secure
		// keyboard entry is not enabled while typing passwords.

		var shouldIgnore : Bool = false

		func ignoredAppIDs() -> [String]
		{
		    return UserDefaults.standard.stringArray(forKey: "IgnoredAppIdentifiers") ?? []
		}

		guard let frontAppID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }

		if (ignoredAppIDs().contains(frontAppID))
		{
			NSLog("Allowing blocked password typing in whitelisted app: %@.", frontAppID)
			shouldIgnore = true
		}

		return shouldIgnore
	}

	func keyboardTap(_ theTap: RSStringMatchingKeyboardTap, didMatchString theString: String)
	{
		if (!shouldIgnoreMatches())
		{
			// Just put up a dialog to block the remaining keys of the password
		    NSApp.activate(ignoringOtherApps: true)
			let dummyAlert = NSAlert()
			dummyAlert.messageText = "Hey dummy, don't type your password where everybody can see it!"
			dummyAlert.icon = NSImage(named: NSImage.cautionName)
			dummyAlert.runModal()
		}
	}
}

