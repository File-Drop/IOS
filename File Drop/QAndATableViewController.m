//
//  QAndATableViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-8.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "QAndATableViewController.h"

@interface QAndATableViewController ()

@end

@implementation QAndATableViewController

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
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            [self showFileWithName:NSLocalizedString(@"File Drop找不到我的iOS设备", @"")];
        }else if (indexPath.row==1){
            [self showFileWithName:NSLocalizedString(@"File Drop找不到我的Mac", @"")];
        }else if (indexPath.row==2){
            [self showFileWithName:NSLocalizedString(@"File Drop找不到我的PC", @"")];
        }
    }else if (indexPath.section==1){
        if (indexPath.row==0) {
            [self showFileWithName:NSLocalizedString(@"iOS版本File Drop初始化失败", @"")];
        }else if (indexPath.row==1){
            [self showFileWithName:NSLocalizedString(@"Mac PC版File Drop初始化失败", @"")];
        }
    }else if (indexPath.section==2){
        if (indexPath.row==0) {
            [self showFileWithName:NSLocalizedString(@"文件无法传输", @"")];
        }else if (indexPath.row==1){
            [self showFileWithName:NSLocalizedString(@"文件无法预览", @"")];
        }
    }
}
-(void)showFileWithName:(NSString*)name{
    NSString *filePath=[[NSBundle mainBundle] pathForResource:name ofType:@"pages"];
    dic=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
    [dic setDelegate:self];
    [dic presentPreviewAnimated:YES];
}
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self.navigationController;
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
