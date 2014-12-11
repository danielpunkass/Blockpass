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

	func saveSecretTextToKeychain(secretText : String) -> Void
	{
		RSKeychain.setSecureString(secretText, forItemName:keychainItemName, accountName:keychainAccountName)
	}

	func getSecretTextFromKeychain() -> String?
	{
		return RSKeychain.secureStringForItemName(keychainItemName, accountName:keychainAccountName)
	}

	@IBAction func dismissPasswordPrompt(sender: AnyObject)
	{
		NSApp.endSheet(self.passwordPrompt!, returnCode:sender.tag())
	}

	func passwordByPromptingUser() -> String?
	{
		var userPassword : String? = nil

		if (self.passwordPrompt == nil)
		{
			let panelNib : NSNib = NSNib(nibNamed:"PasswordPromptPanel", bundle:nil)!
			panelNib.instantiateWithOwner(self, topLevelObjects:&passwordPromptNibObjects)
		}

		let thePrompt = self.passwordPrompt!
		// Present the panel modally and at high layer since we're a faceless background app
		thePrompt.center()

		// NSStatusWindowLevel doesn't seem available in Swift? And the types for CG constants 
		// are mismatched Int vs Int32 so we have to do this dance
		thePrompt.level = Int(CGWindowLevelForKey(CGWindowLevelKey(kCGStatusWindowLevelKey)))

		thePrompt.makeKeyAndOrderFront(nil)

		let promptStatus = NSApp.runModalForWindow(thePrompt)
		if (promptStatus == NSModalResponseOK)
		{
			userPassword = self.secureStringTextField!.stringValue
		}

		thePrompt.orderOut(nil)

		// Prompt here and if it's "" then change to nil
		return userPassword
	}

	func applicationDidFinishLaunching(aNotification: NSNotification)
	{
		// Make sure we have ability to intercept keys
		let promptFlag = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
		let myDict: CFDictionary = [promptFlag: true]
		AXIsProcessTrustedWithOptions(myDict)

		// Unfortunately the prompting mechanism doesn't seem to work from an LSUIElement app
		if (AXIsProcessTrustedWithOptions(myDict) == UInt8(0))
		{
			NSLog("Don't have accessibility access, so we're prompting...")
			let warnAlert = NSAlert();
			warnAlert.messageText = "Blockpass relies upon having permission to 'control your computer'. If the permission prompt did not appear automatically, go to System Preferences, Security & Privacy, Privacy, Accessibility, and add Blockpass to the list of allowed apps. Then relaunch Blockpass.";
			warnAlert.layout()
			let warnPanel = warnAlert.window as NSPanel
			warnPanel.level = Int(CGWindowLevelForKey(CGWindowLevelKey(kCGStatusWindowLevelKey)))
 			warnAlert.runModal();
			NSApplication.sharedApplication().terminate(nil)
		}
		else
		{
			var matchedString : String? = getSecretTextFromKeychain()

			// Override keychain stored value if option key is held down
			let keyFlags = NSEvent.modifierFlags()
			let optionKeyFlags = NSEventModifierFlags.AlternateKeyMask
			let overrideKeychain = ((keyFlags & optionKeyFlags).rawValue) != 0
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
			if (matchedString == nil)
			{
				NSLog("No stored password and no user-supplied password. Quitting…")
				NSApplication.sharedApplication().terminate(nil)
			}
			else
			{
				myPasswordBlocker = RSStringMatchingKeyboardTap(string:matchedString, delegate:self)
			}
		}

		// Register our default ignored app identifiers
		let defaultIgnoredApps : NSArray = ["com.apple.Terminal", "com.apple.ScreenSharing"]
		NSUserDefaults.standardUserDefaults().registerDefaults(["IgnoredAppIdentifiers": defaultIgnoredApps])
	}

	func applicationWillTerminate(aNotification: NSNotification)
	{
		// Insert code here to tear down your application
	}

	func shouldIgnoreMatches() -> Bool
	{
		var shouldIgnore : Bool = false

		func ignoredAppIDs() -> NSArray
		{
			if let myArray : NSArray = NSUserDefaults.standardUserDefaults().objectForKey("IgnoredAppIdentifiers") as? NSArray
			{
				return myArray
			}
			else
			{
				return NSArray()
			}
		}

		func frontAppID() -> String
		{
			let frontApp : NSRunningApplication = NSWorkspace.sharedWorkspace().frontmostApplication!
			return frontApp.bundleIdentifier!
		}
		// Work around problems where Terminal password entry (e.g. sudo prompt) and Screen Sharing
		// (e.g. legitimate secure entry into Screen Sharing app) cause false alarms because secure 
		// keyboard entry is not enabled while typing passwords.
		if (ignoredAppIDs().containsObject(frontAppID()))
		{
			NSLog("Allowing blocked password typing in whitelisted app: %@.", frontAppID())
			shouldIgnore = true
		}

		return shouldIgnore
	}

	func keyboardTap(theTap: RSStringMatchingKeyboardTap!, didMatchString theString: String!)
	{
		if (self.shouldIgnoreMatches() == false)
		{
			// Just put up a dialog to block the remaining keys of the password
			NSApplication.sharedApplication().activateIgnoringOtherApps(true)
			let dummyAlert = NSAlert()
			dummyAlert.messageText = "Hey dummy, don't type your password where everybody can see it!"
			dummyAlert.icon = NSImage(named:NSImageNameCaution)
			dummyAlert.runModal()
		}
	}
}

