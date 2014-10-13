//
//  SettingTableViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-6.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "SettingTableViewController.h"
#import <MessageUI/MessageUI.h>
#import "HashGetter.h"

@interface SettingTableViewController ()

@end

@implementation SettingTableViewController

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
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    [self performSelector:@selector(setCell) withObject:nil afterDelay:0.01];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)setCell{
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].detailTextLabel.text=[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section==0&&indexPath.row==0) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString( @"更改名字",@"") message:NSLocalizedString(@"请输入新的设备名称",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") otherButtonTitles:NSLocalizedString(@"好",@""), nil];
        alert.alertViewStyle=UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text=[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"];
        [alert show];
    }else if (indexPath.section==1&&indexPath.row==0){
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"God"] isEqualToString:[[[HashGetter alloc] init] hasValueForDevice]]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"谢谢", @"")  message:NSLocalizedString(@"您已经移除过了广告，请勿重复购买",@"") delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return;
        }
        NSArray* productIdentifiers = @[@"com.xiongdianpku.File_Drop.removeAD"];
        NSSet* identifierSet = [NSSet setWithArray:productIdentifiers];
        SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers:identifierSet];
        request.delegate=self;
        [request start];
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        hud.labelText=NSLocalizedString(@"正在连接商店",@"");
        [self.navigationController.view addSubview:hud];
        [hud show:YES];
    }else if (indexPath.section==1&&indexPath.row==1){
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"God"] isEqualToString:[[[HashGetter alloc] init] hasValueForDevice]]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"谢谢",@"") message:NSLocalizedString(@"您已经移除过了广告，请勿重复购买。如果还有广告，请重新启动程序",@"") delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil] show];
            return;
        }
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        hud.labelText=NSLocalizedString(@"正在连接商店",@"");
        [self.navigationController.view addSubview:hud];
        [hud show:YES];
    }else if (indexPath.section==2&&indexPath.row==0){
        NSString *filePath=[[NSBundle mainBundle] pathForResource:NSLocalizedString(@"File Drop入门",@"") ofType:@"pdf"];
        dic=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
        [dic setDelegate:self];
        [dic presentPreviewAnimated:YES];
    }else if (indexPath.section==2&&indexPath.row==3){
        mvc=[[MFMailComposeViewController alloc]init];
        [mvc setSubject:NSLocalizedString(@"File Drop反馈",@"")];
        mvc.mailComposeDelegate=self;
        [mvc setToRecipients:[NSArray arrayWithObject:@"xiongdianpku@vip.qq.com"]];
        [self presentViewController:mvc animated:YES completion:nil];
    }else if (indexPath.section==2&&indexPath.row==4){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id815466873"]]];
    }
}
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self.navigationController;
}
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    hud.labelText=NSLocalizedString(@"正在获取商品信息",@"");
    SKProduct *product=[response.products firstObject];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
//    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    SKPayment *payment=[SKPayment paymentWithProduct:product];
    @try {
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    @catch (NSException *exception) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"抱歉",@"") message:NSLocalizedString(@"购买时出现错误，请稍后再试！",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil] show];
    }
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    [mvc dismissViewControllerAnimated:YES completion:nil];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
    NSLog(@"payment finish restore");
    hud.labelText=NSLocalizedString(@"已恢复您的购买",@"");
    hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
    hud.mode=MBProgressHUDModeCustomView;
    [hud show:YES];
    [hud hide:YES afterDelay:2];
    [[NSUserDefaults standardUserDefaults] setObject:[[[HashGetter alloc] init] hasValueForDevice] forKey:@"God"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"adRemoved" object:nil userInfo:nil];

}
-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"失败",@"") message:NSLocalizedString(@"无法完成恢复",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
    [hud hide:NO];
}
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for (SKPaymentTransaction *transaction in transactions) {
        NSLog(@"%ld",(long)transaction.transactionState);
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:{
                NSLog(@"purchased");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                hud.labelText=NSLocalizedString(@"感谢您的购买",@"");
                hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
                hud.mode=MBProgressHUDModeCustomView;
                [hud show:YES];
                [hud hide:YES afterDelay:2];
                [[NSUserDefaults standardUserDefaults] setObject:[[[HashGetter alloc] init] hasValueForDevice] forKey:@"God"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"adRemoved" object:nil userInfo:nil];
            }
                break;
            case SKPaymentTransactionStateFailed:{
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"购买失败",@"") message:transaction.error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
                [hud hide:NO];
            }
                break;
            case SKPaymentTransactionStateRestored:{
                hud.labelText=NSLocalizedString(@"正在获取商品信息",@"");
                break;
            }
            default:
                break;
        }
    }
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    hud.labelText=[error localizedDescription];
    hud.mode=MBProgressHUDModeText;
    [hud hide:YES afterDelay:2];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:NSLocalizedString(@"更改名字",@"")]) {
        if ([alertView textFieldAtIndex:0].text.length==0) {
            return;
        }
        [[NSUserDefaults standardUserDefaults] setObject:[alertView textFieldAtIndex:0].text forKey:@"DeviceName"];
        [self setCell];
    }
}
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
