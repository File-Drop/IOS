//
//  RecieveFileViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "RecieveFileViewController.h"
#import "IPGetter.h"

@interface RecieveFileViewController ()

@end

@implementation RecieveFileViewController
@synthesize rootPath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.progressView.hidden=YES;
    if ([[IPGetter getIPAddress] isEqualToString:@"error"]&&NO) {
        self.mainLabel.text=NSLocalizedString(@"无网络连接\n请接入无线局域网",@"");
        self.mainLabel.textColor=[UIColor redColor];
        self.tipLabel.hidden=YES;
        self.ipLabel.hidden=YES;
        return;
    }
    serverManager=[[ServerManager alloc] init];
    serverManager.delegate=self;
    [serverManager setRootPath:rootPath];
    if([serverManager startServer]){
        self.mainLabel.text=[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"请在PC、Mac或者其他iOS设备上打开File Drop以向此设备发送文件。您的设备将被显示为",@""),[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"]];
        self.mainLabel.textColor=[UIColor blackColor];
        self.tipLabel.hidden=NO;
        if ([[IPGetter getIPAddress] isEqualToString:@"error"]) {
            self.ipLabel.text=@"";
            self.tipLabel.text=NSLocalizedString(  @"请打开双方的蓝牙，或者接入无线局域网",@"");
        }else{
            self.ipLabel.text=[IPGetter getIPAddress];
        }
        self.ipLabel.hidden=NO;
        [UIApplication sharedApplication].idleTimerDisabled=YES;
    }else{
        self.mainLabel.text=NSLocalizedString(@"初始化文件传输服务失败，请退出其他后台程序再试",@"");
        self.mainLabel.textColor=[UIColor redColor];
        self.tipLabel.hidden=YES;
        self.ipLabel.hidden=YES;
    }
	// Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)adRemoved:(NSNotification*)noti{
    self.canDisplayBannerAds=NO;
}
- (IBAction)done:(id)sender {
    [serverManager close];
    [UIApplication sharedApplication].idleTimerDisabled=NO;
    serverManager=nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)serverManager:(ServerManager *)manager didBeginFileTransportWithUser:(NSString *)userName totalBytes:(NSString *)bytes{
    self.progressView.hidden=NO;
    self.progressBar.progress=0;
    self.progressTipView.text=[NSString stringWithFormat:NSLocalizedString(@"%@ 正在给您发送文件:(%@)",@""),userName,bytes];
    username=userName;
    currentBytes=bytes;
}
- (void)serverManager:(ServerManager *)manager didBeginRecievingFileNamed:(NSString *)fileName{
    self.progressTipView.text=[NSString stringWithFormat:NSLocalizedString(@"%@ 正在给您发送文件:(%@)\n%@",@""),username,currentBytes,fileName];
}
- (void)serverManager:(ServerManager *)manager didReachProgress:(double)progress{
    self.progressBar.progress=progress;
}
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
- (void)serverManager:(ServerManager *)manager didFinishFileTransportWithUser:(NSString *)userName{
    [UIView animateWithDuration:1 animations:^{
        self.progressView.hidden=YES;
    }];
    hud=[[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText=NSLocalizedString(@"完成",@"");
    hud.mode=MBProgressHUDModeCustomView;
    hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
    [hud show:YES];
    [hud hide:YES afterDelay:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"canRate" object:nil userInfo:nil];
}
- (void)serverManager:(ServerManager *)manager didFailFileTransportWithUser:(NSString *)userName{
    [UIView animateWithDuration:1 animations:^{
        self.progressView.hidden=YES;
    }];
}
@end
