//
//  AppDelegate.m
//  File Drop
//
//  Created by 熊典 on 13-12-28.
//  Copyright (c) 2013年 熊典. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

+(void)initialize{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[UIDevice currentDevice].name,@"DeviceName",[NSNumber numberWithBool:YES],@"showRate", nil]];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(canRate:) name:@"canRate" object:nil];
//    [self canRate:nil];
    UIColor *tintColor=[UIColor colorWithRed:45.0/255 green:144.0/255 blue:220.0/255 alpha:1];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
    [[UINavigationBar appearance] setBarTintColor:tintColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UISegmentedControl appearance] setTintColor:[UIColor whiteColor]];
    [[UISwitch appearance] setOnTintColor:tintColor];
    [[UITabBar appearance] setTintColor:tintColor];
    [[UIButton appearance] setTintColor:tintColor];
    [[UIToolbar appearance] setTintColor:tintColor];
    [[UITableView appearance] setTintColor:tintColor];

    return YES;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"showRate"];
            break;
        case 1:{
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"showRate"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id815466873"]]];
        }
        default:
            break;
    }
}
-(void)canRate:(NSNotification*)noti{
    NSDate *date=[[NSUserDefaults standardUserDefaults] objectForKey:@"lastShowTime"];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"showRate"] boolValue]&&(!date||[date timeIntervalSinceNow]<-24*3600)) {
        [[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"给我们点个赞吧~",@"") message:NSLocalizedString(@"File Drop如此方便有木有！快告诉大家，让更多的人用上File Drop！",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"不了……",@"") otherButtonTitles:NSLocalizedString(@"现在去评分=￣ω￣=",@""),NSLocalizedString(@"下次吧⊙▽⊙",@""), nil] show];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastShowTime"];
    }
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FileCome" object:url];
    return YES;
}
@end
