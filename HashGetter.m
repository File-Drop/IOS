//
//  HashGetter.m
//  File Drop
//
//  Created by 熊典 on 14-3-4.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "HashGetter.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation HashGetter
// Custom method to calculate the SHA-256 hash using Common Crypto
- (NSString *)hashedValueForAccountName:(NSString*)userAccountName
{
    const int HASH_SIZE = 32;
    unsigned char hashedChars[HASH_SIZE];
    const char *accountName = [userAccountName UTF8String];
    size_t accountNameLen = strlen(accountName);
    
    // Confirm that the length of the user name is small enough
    // to be recast when calling the hash function.
    
    if (accountNameLen > UINT32_MAX) {
        NSLog(@"Account name too long to hash: %@", userAccountName);
        return nil;
    }
    CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
    
    // Convert the array of bytes into a string showing its hex representation.
    NSMutableString *userAccountHash = [[NSMutableString alloc] init];
    for (int i = 0; i < HASH_SIZE; i++) {
        // Add a dash every four bytes, for readability.
        if (i != 0 && i%4 == 0) {
            [userAccountHash appendString:@"-"];
        }
        [userAccountHash appendFormat:@"%02x", hashedChars[i]];
    }
    return userAccountHash;
}
-(NSString*)hasValueForDevice{
    return [self hashedValueForAccountName:[NSString stringWithFormat:@"%@God*Oh",[[[UIDevice currentDevice] identifierForVendor] UUIDString]]];
}
@end
