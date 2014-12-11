//
//  RSKeychain.h
//
//  Created by daniel on 4/23/09.
//  Copyright 2009 Daniel Jalkut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSKeychain : NSObject

// Keychain data is ultimately encoding-agnostic. If you know it's a string you can use the convenience methods for strings,
// but if you want to store/retreive something else e.g. an archived object as NSData, you can.

+ (void) setSecureData:(NSData*)newData forItemName:(NSString*)keychainItemName accountName:(NSString*)accountName;
+ (NSData*) secureDataForItemName:(NSString*)keychainItemName accountName:(NSString*)accountName;

+ (void) setSecureString:(NSString*)passwordString forItemName:(NSString*)keychainItemName accountName:(NSString*)accountName;
+ (NSString*) secureStringForItemName:(NSString*)keychainItemName accountName:(NSString*)accountName;

@end
