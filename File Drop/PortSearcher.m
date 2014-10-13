//
//  PortSearcher.m
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "PortSearcher.h"

@implementation PortSearcher
-(void)searchDevices:(NSString *)ip port:(NSInteger)port withResultBlock:(PortSearcherResultBlock)block onFinish:(PortSearcherFinishBlock)fblock{
    components=[ip componentsSeparatedByString:@"."];
    sockets=[NSMutableArray array];
    resultBlock=block;
    finishBlock=fblock;
    limitedDevice=50;
    limitedDevice1=25;
    limitedDevice2=25;
    downReached=NO;
    upReached=NO;
    number=0;
    NSInteger index=[[components objectAtIndex:3] integerValue];
    for (NSInteger i=index+1; i>=0; i--) {
        NSString *currentIP=[NSString stringWithFormat:@"%@.%@.%@.%ld",[components objectAtIndex:0],[components objectAtIndex:1],[components objectAtIndex:2],(long)i];
        [self testIP:currentIP port:port down:YES];
        if (i==0) {
            downReached=YES;
        }
    }
    for (NSInteger i=index+1; i<=255; i++) {
        NSString *currentIP=[NSString stringWithFormat:@"%@.%@.%@.%ld",[components objectAtIndex:0],[components objectAtIndex:1],[components objectAtIndex:2],(long)i];
        [self testIP:currentIP port:port down:NO];
        if (i==255) {
            upReached=YES;
        }
    }
}
-(void)testIP:(NSString*)ip port:(NSInteger)port down:(BOOL)down{
    if (number>limitedDevice) {
        return;
    }
    if (down) {
        if (limitedDevice1<0&&!upReached) {
            return;
        }
        limitedDevice1--;
    }else{
        if(limitedDevice2<0&&!downReached){
            return;
        }
        limitedDevice2--;
    }
    [self testIP:ip port:port];
}
-(void)testIP:(NSString*)ip port:(NSInteger)port{
    number++;
    NSError *err=nil;
    AsyncSocket *socket=[[AsyncSocket alloc] initWithDelegate:self];
    [sockets addObject:socket];
    NSArray *componentsnow=[ip componentsSeparatedByString:@"."];
    [socket setUserData:[[componentsnow objectAtIndex:3] integerValue]];
    [socket connectToHost:ip onPort:port error:&err];
}
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"didConnect");
    [sock writeData:[@"ask for info" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:1];
    [sock readDataWithTimeout:3 tag:-1];
}
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    number--;
    NSString *nameInfo= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *name,*device;
    if ([nameInfo rangeOfString:@":" options:NSBackwardsSearch].location==NSNotFound) {
        name=nameInfo;
        device=@"unknown";
    }else{
        name=[nameInfo substringToIndex:[nameInfo rangeOfString:@":" options:NSBackwardsSearch].location];
        device=[nameInfo substringFromIndex:[nameInfo rangeOfString:@":" options:NSBackwardsSearch].location+1];
    }
    resultBlock([NSDictionary dictionaryWithObjectsAndKeys:name,@"name",device,@"device",[NSString stringWithFormat:@"%@.%@.%@.%ld",[components objectAtIndex:0],[components objectAtIndex:1],[components objectAtIndex:2],[sock userData]],@"ip", nil]);
    if (number==0) {
        finishBlock();
    }
}
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
    number--;
//    NSLog(@"%ld,%d",[sock userData],number);
    if (number==0) {
        finishBlock();
    }
    [sockets removeObject:sock];
}
-(void)addDeviceManual:(NSString *)ip{
    [self testIP:ip port:12345];
}

@end
