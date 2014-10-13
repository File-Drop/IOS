//
//  DetailFileTableViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-5.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface DetailFileTableViewController : UITableViewController<UIActionSheetDelegate,UIAlertViewDelegate>{
    NSString *path;
    NSArray *keys;
    NSArray *values;
    MBProgressHUD *hud;
}
- (IBAction)deleteFile:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)rename:(id)sender;
- (IBAction)copyFile:(id)sender;
@property NSString *path;

@end
