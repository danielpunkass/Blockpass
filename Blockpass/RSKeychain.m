//
//  RSKeychain.m
//
//  Created by daniel on 4/23/09.
//  Copyright 2009 Daniel Jalkut. All rights reserved.
//

#import "RSKeychain.h"
#import <Security/Security.h>

@implementation RSKeychain

+ (void) setSecureBytes:(const void *)bytePointer length:(NSUInteger)byteLength forItemName:(NSString*)keychainItemName accountName:(NSString*)accountName
{
    const char* itemNameUTF8String = [keychainItemName UTF8String];
	
	if (itemNameUTF8String != nil)
	{
		SecKeychainRef defaultKeychain;
		if (SecKeychainCopyDefault (&defaultKeychain) == noErr)
		{
			BOOL shouldAddNewItem = YES;

			const char *accountUTF8String = [accountName UTF8String];
		
			// Update an existing item if we have one
			SecKeychainItemRef itemRef = nil;
			OSErr err = SecKeychainFindGenericPassword (nil, strlen(itemNameUTF8String), itemNameUTF8String,
														strlen(accountUTF8String), accountUTF8String,
													NULL, NULL, &itemRef);
			if (err == noErr && itemRef)
			{		
				err = SecKeychainItemModifyContent (itemRef, NULL, byteLength, bytePointer);
				if (err == noErr)
				{
					shouldAddNewItem = NO;
				}
				
				CFRelease(itemRef);
			}
			
			if (shouldAddNewItem)
			{
				SecKeychainAddGenericPassword (defaultKeychain, strlen(itemNameUTF8String),
					itemNameUTF8String, strlen(accountUTF8String), accountUTF8String,
					byteLength, bytePointer, nil);
			}
			
			CFRelease(defaultKeychain);
		}
	}
}

+ (NSData*) secureDataForItemName:(NSString*)keychainItemName accountName:(NSString*)accountName
{
	NSData* foundData = nil;
	const char *accountNameUTF8String = [accountName UTF8String];
    const char* keychainItemNameUTF8String = [keychainItemName UTF8String];
	OSErr err = noErr;
	
	if (keychainItemNameUTF8String != nil)
	{
		UInt32 secureDataLength = 0;
		void *secureDataBuffer = NULL;
		
		err = SecKeychainFindGenericPassword (nil, strlen (keychainItemNameUTF8String),
			keychainItemNameUTF8String, strlen (accountNameUTF8String), accountNameUTF8String,
			&secureDataLength, (void **) &secureDataBuffer, nil);
		
		if (err == noErr)
		{
			foundData = [NSData dataWithBytes:(const void *)secureDataBuffer length:secureDataLength];

			SecKeychainItemFreeContent(NULL, secureDataBuffer);		
		}
		else
		{
			if (err != errSecItemNotFound)
			{
				NSLog(@"Got error %d trying to access password in keychain for %@/%@", err, keychainItemName, accountName);
			}
		}
	}
	
	return foundData;
}

+ (void) setSecureData:(NSData*)newData forItemName:(NSString*)keychainItemName accountName:(NSString*)accountName
{
	[self setSecureBytes:[newData bytes] length:[newData length] forItemName:keychainItemName accountName:accountName];
}

+ (void) setSecureString:(NSString*)passwordString forItemName:(NSString*)keychainItemName accountName:(NSString*)accountName
{
	const char *passwordUTF8String = [passwordString UTF8String];

	[self setSecureBytes:passwordUTF8String length:strlen(passwordUTF8String) forItemName:keychainItemName accountName:accountName];
}

+ (NSString*) secureStringForItemName:(NSString*)keychainItemName accountName:(NSString*)accountName
{
	NSData* passwordItemData = [self secureDataForItemName:keychainItemName accountName:accountName];
	NSString *foundPassword = [[NSString alloc] initWithData:passwordItemData encoding:NSUTF8StringEncoding];

	return foundPassword;
}


@end
