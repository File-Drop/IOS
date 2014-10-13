//
//  SendFileViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-4.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface SendFileViewController : UIViewController<UIAlertViewDelegate,MCSessionDelegate>{
    NSArray *paths;
    NSMutableArray *expandedPaths;
    NSString* userName;
    NSString* ip;
    AsyncSocket *socket;
    double totalSize;
    NSInteger fileIndex;
    double progressCount;
    NSString *rootPath;
    FILE *fileStream;
    double currentFileSize;
    double readedFileSize;
    NSString *sendType;
    NSString *textToSend;
    BOOL shouldStop;
    
    MCNearbyServiceBrowser *mcbrowser;
    MCSession *mcsession;
    MCPeerID *targetPeer;
}
@property NSArray *paths;
@property NSString *userName;
@property NSString *ip;
@property NSString *rootPath;
@property NSString* sendType;
@property NSString* textToSend;

@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property MCNearbyServiceBrowser* mcbrowser;
@property MCPeerID *targetPeer;
@property MCSession *mcsession;
- (IBAction)cancel:(id)sender;

@end
