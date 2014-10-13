//
//  DocumentFileViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "DeviceViewController.h"
#import "DetailFileTableViewController.h"
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import "QBImagePickerController.h"
#import <MessageUI/MessageUI.h>



@interface DocumentFileViewController : UITableViewController<UIDocumentInteractionControllerDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ADBannerViewDelegate,UIAlertViewDelegate,GADBannerViewDelegate,MFMailComposeViewControllerDelegate,QBImagePickerControllerDelegate>{
    NSMutableArray *files;
    NSString *rootPath;
    UIBarButtonItem *defaultItem;
    BOOL isMain;
    BOOL showDelete;
    NSArray *paths;
    NSString *tempPath;
    UIDocumentInteractionController *dic;
    MBProgressHUD *hud;
    CGRect defaultAdPosition;
    GADBannerView *gad;
    ADBannerView *ad;
    NSInteger adCounter;
    NSMutableString *debugString;
    MFMailComposeViewController *mfc;
    UIImageView *imageview;
}
- (IBAction)edit:(id)sender;
- (IBAction)newFolder:(id)sender;
- (IBAction)report:(id)sender;

@property NSString* rootPath;
@end
