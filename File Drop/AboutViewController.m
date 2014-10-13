//
//  AboutViewController.m
//  SmartIPGateWayTouch
//
//  Created by 熊典 on 13-12-19.
//  Copyright (c) 2013年 熊典. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

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
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    self.versionText.text=[NSString stringWithFormat:@"%@%@(%@)",NSLocalizedString(@"版本：", @""),app_Version,app_build];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)contact:(id)sender {
    mvc=[[MFMailComposeViewController alloc]init];
    [mvc setSubject:NSLocalizedString(@"File Drop反馈", @"") ];
    mvc.mailComposeDelegate=self;
    [mvc setToRecipients:[NSArray arrayWithObject:@"xiongdianpku@vip.qq.com"]];
    [self presentViewController:mvc animated:YES completion:nil];
}

- (IBAction)okpressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    [mvc dismissViewControllerAnimated:YES completion:nil];
}
@end
