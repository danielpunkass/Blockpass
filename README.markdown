Blockpass - Hey dummy, don't type your password where everybody can see it!
===========================================================================

Overview
--------

Blockpass aims to save you from the heart-stopping problem of typing your computer's lock-screen password into a plain text field such as a chat, Twitter, etc., and pressing return before you realize you've just shared your password with a friend, or the world.

Blockpass is a standard Mac OS X application that runs as a "faceless background application." As such it doesn't show up in the Dock. It also has no user NSStatusItem show it won't show up in the menu bar either. It simply runs quietly in the background, waiting for you to type your password (or whatever string you configure it with), and jolts you with an alert condemning the action.

Requirements
------------

Blockpass is written with a combination of Objective C and Swift, and expects to build for a deployment target of 10.10 or higher. It has not been tested in other environments.

Blockpass requires that you enable "access for assistive devices" in the System Preferences Accessibility pane.

Installation
------------

To install Blockpass you need to first build the application, run the app, and arrange for the app to be run every time you log in to your Mac. You can arrange this in the "Login Items" section of your user settings in the System Preferences "Users & Groups" pane.

Configuration
-------------

The first time you run Blockpass, it will prompt you for a secret string, which will be saved securely in the keychain. The string you enter will dictate which keystrokes cause Blockpass to later interrupt you and prevent your typing the password in plain text. 

If at any time after you first run and configure Blockpass, you wish to change the stored password, you can do so by holding the option key while Blockpass launches. First "killall Blockpass" from the Terminal, then relaunch the app.

Security
--------

Blockpass stores your configured password string securely in the System Keychain, using the application name "Blockpass" and account name "main password". It is read from the keychain at launch time unless the option key is held down to override the saved value with a new value.

Un-Installation
---------------

Because Blockpass has no user interface, to quit the app you will have to "killall Blockpass" from the Terminal.

Should you decide you want to stop using Blockpass entirely, simply delete the app from your computer, remove it from your login items, and "killall Blockpass" from the Terminal, or restart your Mac to be sure it is no longer running.

Caveats
-------

This project is not particularly supported. I'm sharing this because of the outpouring of requests to do so after I [blogged about a related issue](http://bitsplitting.org/2014/12/09/insecure-keyboard-entry/). I've tried to make the tool as user-friendly as possible given time constraints, but do not expect the world from me! I hope you enjoy the tool and code.
