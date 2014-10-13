//
//  DetailFileTableViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-5.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "DetailFileTableViewController.h"
#import "DeviceViewController.h"

@interface DetailFileTableViewController ()

@end

@implementation DetailFileTableViewController
@synthesize path;
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
    keys=@[NSLocalizedString(@"文件名",@""),NSLocalizedString(@"文件大小",@""),NSLocalizedString(@"创建日期",@""),NSLocalizedString(@"修改日期",@"")];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    [self getFileInfo];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)getFileInfo{
    NSDictionary *attrs=[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    BOOL isD;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isD];
    values=@[[self fileNameAtPath:path],isD?[NSString stringWithFormat:@"%ld%@",(long)[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil].count,NSLocalizedString(@"个项目",@"")]:[self packSize:[attrs objectForKey:NSFileSize]],[formatter stringFromDate:[attrs objectForKey:NSFileCreationDate]],[formatter stringFromDate:[attrs objectForKey:NSFileModificationDate]]];
    [self.tableView reloadData];
}
-(NSString*)packSize:(NSNumber*)sizeInByte{
    double temp=[sizeInByte doubleValue];
	int gb=floor(temp/1024/1024/1024);
	temp-=gb*1024*1024*1024;
	int mb=floor(temp/1024/1024);
	temp-=mb*1024*1024;
	int kb=floor(temp/1024);
	temp-=kb*1024;
	int b=temp;
	if(gb!=0) return [NSString stringWithFormat:@"%0.2f GB",[sizeInByte doubleValue]/1024/1024/1024];
	if(mb!=0) return [NSString stringWithFormat:@"%0.2f MB",[sizeInByte doubleValue]/1024/1024];
	if(kb!=0) return [NSString stringWithFormat:@"%0.2f KB",[sizeInByte doubleValue]/1024];
	return [NSString stringWithFormat:@"%d Bytes",b];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(NSString*)fileNameAtPath:(NSString*)path2{
    return [path2 substringFromIndex:[path2 rangeOfString:@"/" options:NSBackwardsSearch].location+1];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return keys.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text=[keys objectAtIndex:indexPath.row];
    cell.detailTextLabel.text=[values objectAtIndex:indexPath.row];
    // Configure the cell...
    
    return cell;
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DeviceViewController *dest=segue.destinationViewController;
    [dest setPaths:@[path]];
    [dest setRootPath:[path substringToIndex:[path rangeOfString:@"/" options:NSBackwardsSearch].location]];
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)deleteFile:(id)sender {
    UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"确认删除",@"") delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:NSLocalizedString(@"删除",@"") otherButtonTitles: nil];
    [action showInView:self.view];
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (IBAction)send:(id)sender {
    [self performSegueWithIdentifier:@"device" sender:nil];
}

- (IBAction)rename:(id)sender {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"重命名",@"") message:NSLocalizedString(@"输入文件名",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") otherButtonTitles:NSLocalizedString(@"好",@""), nil];
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text=[self fileNameAtPath:path];
    [alert show];
}

- (IBAction)copyFile:(id)sender {
    NSString *rootPath=[path substringToIndex:[path rangeOfString:@"/" options:NSBackwardsSearch].location];
    NSMutableArray *ps=[[NSMutableArray alloc] initWithObjects:@"File_Drop_Pasteboard_Items",rootPath,[path substringFromIndex:[path rangeOfString:@"/" options:NSBackwardsSearch].location+1], nil];
    [[UIPasteboard generalPasteboard] setStrings:ps];
    hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText=NSLocalizedString(@"文件已复制", @"");
    hud.mode=MBProgressHUDModeCustomView;
    hud.customView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
    [hud show:YES];
    [hud hide:YES afterDelay:1];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    NSString *newPath=[NSString stringWithFormat:@"%@/%@",[path substringToIndex:[path rangeOfString:@"/" options:NSBackwardsSearch].location],[alertView textFieldAtIndex:0].text];
    [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:nil];
    path=newPath;
    [self getFileInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
}
@end
