//
//  ServerManager.h
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "ServerManagerDelegate.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ServerManager : NSObject<UIAlertViewDelegate,MCNearbyServiceAdvertiserDelegate,MCSessionDelegate>{
    AsyncSocket *serverSocket;
    NSMutableArray *sockets;
    NSInteger size;
    NSMutableData *respondData;
    BOOL isSendingFile;
    AsyncSocket *currentSocket;
    double totalSize;
    double progressCount;
    NSString *currentUserName;
    id<ServerManagerDelegate> delegate;
    UIAlertView *acceptAlert;
    NSString *currentPath;
    NSString *currentFileName;
    double currentSize;
    NSString *message;
    NSString *rootPath;
    
    //Multipeer
    MCPeerID *peerID;
    MCPeerID *myPeerID;
    MCSession *session;
    MCNearbyServiceAdvertiser *advertiser;
}
-(BOOL)startServer;
-(void)close;
@property id<ServerManagerDelegate> delegate;
@property NSString* rootPath;
@end
