//
//  DeviceViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "DeviceViewController.h"
#import "IPGetter.h"
#import "SendFileViewController.h"

@interface DeviceViewController ()

@end

@implementation DeviceViewController

@synthesize paths,rootPath,sendType,textToSend;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"refreshDevice" object:nil];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    [self refresh];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)refresh{
    devices=[[NSMutableArray alloc] init];
    [self.tableView reloadData];
    [self refreshDevices];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return devices.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"device";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (indexPath.row<devices.count) {
        NSDictionary *deviceInfo=[devices objectAtIndex:indexPath.row];
        cell.textLabel.text=[deviceInfo objectForKey:@"name"];
        cell.detailTextLabel.text=[deviceInfo objectForKey:@"ip"];
        if ([[deviceInfo objectForKey:@"device"] isEqualToString:@"mac"]) {
            [cell.imageView setImage:[UIImage imageNamed:@"mac"]];
        }else if ([[deviceInfo objectForKey:@"device"] isEqualToString:@"win"]){
            [cell.imageView setImage:[UIImage imageNamed:@"windows"]];
        }else if ([[deviceInfo objectForKey:@"device"] isEqualToString:@"iphone"]){
            [cell.imageView setImage:[UIImage imageNamed:@"iphone"]];
        }else if ([[deviceInfo objectForKey:@"device"] isEqualToString:@"ipad"]){
            [cell.imageView setImage:[UIImage imageNamed:@"ipad"]];
        }else if ([[deviceInfo objectForKey:@"device"] isEqualToString:@"android"]){
            [cell.imageView setImage:[UIImage imageNamed:@"android"]];
        }else{
            [cell.imageView setImage:[UIImage imageNamed:@"unknown"]];
        }
    }else{
        cell.textLabel.text=NSLocalizedString(@"<添加其他设备>", @"");
        cell.detailTextLabel.text=@"";
        [cell.imageView setImage:nil];
    }
    // Configure the cell...
    
    return cell;
}

- (void)viewDidDisappear:(BOOL)animated{
    portSearcher=nil;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SendFileViewController *dest=segue.destinationViewController;
    [dest setPaths:paths];
    [dest setUserName:[[devices objectAtIndex:tempIndexPath.row] objectForKey:@"name"]];
    [dest setRootPath:rootPath];
    [dest setSendType:sendType];
    [dest setTextToSend:textToSend];
    if ([[[devices objectAtIndex:tempIndexPath.row] objectForKey:@"ip"] isEqualToString:@"Nearby"]) {
        [dest setTargetPeer:[[devices objectAtIndex:tempIndexPath.row] objectForKey:@"peer"]];
        [dest setMcbrowser:mcbrowser];
        [dest setMcsession:session];
        [mcbrowser stopBrowsingForPeers];
        mcbrowser.delegate=nil;
        [session setDelegate:nil];
        session=nil;
        mcbrowser=nil;
    }else{
        [dest setIp:[[devices objectAtIndex:tempIndexPath.row] objectForKey:@"ip"]];
    }

    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    tempIndexPath=indexPath;
    if (indexPath.row==devices.count) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"添加设备", @"") message:NSLocalizedString(@"请输入设备的ip地址，它显示在设备的屏幕上", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消" ,@"")otherButtonTitles:NSLocalizedString(@"好",@""), nil];
        alert.alertViewStyle=UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].keyboardType=UIKeyboardTypeDecimalPad;
        [alert show];
    }else{
        if ([[[devices objectAtIndex:indexPath.row] objectForKey:@"device"] isEqualToString:@"unknown"]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"错误",@"") message:NSLocalizedString(@"对方File Drop版本过低，无法发送",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil] show];
            return;
        }
        [self performSegueWithIdentifier:@"recieve" sender:nil];
    }
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    [portSearcher addDeviceManual:[alertView textFieldAtIndex:0].text];
}
-(void)refreshDevices{
    [devices removeAllObjects];
    self.footer.hidden=NO;
    if (![[IPGetter getIPAddress] isEqualToString:@"error"]) {
//        hud=[[MBProgressHUD alloc] initWithView:self.view];
//        [self.view addSubview:hud];
//        hud.labelText=NSLocalizedString(@"无网络连接", @"");
//        hud.mode=MBProgressHUDModeText;
//        [hud show:YES];
//        [hud hide:YES afterDelay:1.5];
//        [self.tableView reloadData];
//        self.footer.hidden=YES;
//        return;
        searching=YES;
        portSearcher=[[PortSearcher alloc] init];
        [portSearcher searchDevices:[IPGetter getIPAddress] port:12345 withResultBlock:^(NSDictionary *result) {
            for (NSDictionary *dict in devices) {
                if ([[dict objectForKey:@"name"] isEqualToString:[result objectForKey:@"name"]]) {
                    if ([[dict objectForKey:@"ip"] isEqualToString:@"Nearby"]) {
                        NSInteger index=[devices indexOfObject:dict];
                        [devices replaceObjectAtIndex:index withObject:result];
                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                        return ;
                    }else{
                        return;
                    }
                }
            }
            [devices addObject:result];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:devices.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        } onFinish:^{
            searching=NO;
            self.footer.hidden=YES;
            NSLog(@"finish");
        }];
    }
    
    MCPeerID *peerID=[[MCPeerID alloc] initWithDisplayName:[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"]];

    mcbrowser=[[MCNearbyServiceBrowser alloc] initWithPeer:peerID serviceType:@"filedrop"];
    mcbrowser.delegate=self;

    session=[[MCSession alloc] initWithPeer:peerID];
    session.delegate=self;
    [mcbrowser startBrowsingForPeers];
}
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    NSString *type=[info objectForKey:@"type"];
    if (!type) {
        type=@"iphone";
    }
    for (NSDictionary *dict in devices) {
        if ([[dict objectForKey:@"name"] isEqualToString:peerID.displayName]) {
            return;
        }
    }
    NSDictionary *result=@{@"name": [peerID displayName],@"device":type,@"ip":@"Nearby",@"peer":peerID};
    [devices addObject:result];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:devices.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];

//    [browser invitePeer:peerID toSession:session withContext:nil timeout:5];
//    NSLog(@"invite");
}
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"change state");
}
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    NSLog(@"lost peer");
}

@end
