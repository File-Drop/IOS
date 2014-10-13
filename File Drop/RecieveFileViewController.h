//
//  RecieveFileViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerManager.h"
#import "MBProgressHUD.h"
#import <iAd/iAd.h>


@interface RecieveFileViewController : UIViewController<ServerManagerDelegate,UIAlertViewDelegate>{
    ServerManager *serverManager;
    NSString *username;
    NSString *currentBytes;
    MBProgressHUD *hud;
    NSString *rootPath;
}
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressTipView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property NSString* rootPath;

@end
