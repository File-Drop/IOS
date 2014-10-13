//
//  SettingTableViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-6.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>

@interface SettingTableViewController : UITableViewController<UIAlertViewDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver,MFMailComposeViewControllerDelegate,UIDocumentInteractionControllerDelegate>{
    MBProgressHUD *hud;
    MFMailComposeViewController *mvc;
    UIDocumentInteractionController *dic;
}

@end
