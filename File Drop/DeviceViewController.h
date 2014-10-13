//
//  DeviceViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "PortSearcher.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface DeviceViewController : UITableViewController<UIAlertViewDelegate,MCSessionDelegate,MCNearbyServiceBrowserDelegate>{
    NSMutableArray *devices;
    MBProgressHUD *hud;
    PortSearcher *portSearcher;
    BOOL searching;
    NSArray *paths;
    NSString *rootPath;
    NSString *sendType;
    NSIndexPath *tempIndexPath;
    NSString *textToSend;
    
    //Multipeer
    MCSession *session;
    MCNearbyServiceBrowser *mcbrowser;
}
@property NSArray *paths;
@property NSString *rootPath;
@property (weak, nonatomic) IBOutlet UIView *footer;
@property NSString* sendType;
@property NSString* textToSend;
@end
