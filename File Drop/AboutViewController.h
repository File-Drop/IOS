//
//  AboutViewController.h
//  SmartIPGateWayTouch
//
//  Created by 熊典 on 13-12-19.
//  Copyright (c) 2013年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface AboutViewController : UIViewController<MFMailComposeViewControllerDelegate>{
    MFMailComposeViewController *mvc;
}
- (IBAction)contact:(id)sender;
- (IBAction)okpressed:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *versionText;

@end
