//
//  HashGetter.h
//  File Drop
//
//  Created by 熊典 on 14-3-4.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HashGetter : NSObject
- (NSString *)hashedValueForAccountName:(NSString*)userAccountName;
-(NSString*)hasValueForDevice;
@end
