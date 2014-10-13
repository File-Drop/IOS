//
//  PortSearcher.h
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
typedef void (^PortSearcherResultBlock)(NSDictionary* result);
typedef void (^PortSearcherFinishBlock)();

@interface PortSearcher : NSObject{
    NSMutableArray *sockets;
    NSInteger number;
    NSArray *components;
    PortSearcherResultBlock resultBlock;
    PortSearcherFinishBlock finishBlock;
    NSInteger limitedDevice;
    NSInteger limitedDevice2;
    NSInteger limitedDevice1;
    BOOL upReached;
    BOOL downReached;
}
-(void)searchDevices:(NSString*)ip port:(NSInteger)port withResultBlock:(PortSearcherResultBlock)block onFinish:(PortSearcherFinishBlock)fblock;
-(void)addDeviceManual:(NSString*)ip;
@end
