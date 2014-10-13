//
//  ServerManagerDelegate.h
//  File Drop
//
//  Created by 熊典 on 14-2-3.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ServerManager,NSString;
@protocol ServerManagerDelegate <NSObject>
-(void)serverManager:(ServerManager*)manager didBeginFileTransportWithUser:(NSString*)userName totalBytes:(NSString*)bytes;
-(void)serverManager:(ServerManager*)manager didBeginRecievingFileNamed:(NSString*)fileName;
-(void)serverManager:(ServerManager*)manager didReachProgress:(double)progress;
-(void)serverManager:(ServerManager*)manager didFinishFileTransportWithUser:(NSString *)userName;
-(void)serverManager:(ServerManager*)manager didFailFileTransportWithUser:(NSString *)userName;
@end
