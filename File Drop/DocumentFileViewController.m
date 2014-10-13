//
//  DocumentFileViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "DocumentFileViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WriterViewController.h"
#import "HashGetter.h"
#import "RecieveFileViewController.h"

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define is4inch ([[UIScreen mainScreen] bounds].size.height==568)
#define is3_5inch ([[UIScreen mainScreen] bounds].size.height==480)
#define isIpadLandscape ([[UIScreen mainScreen] bounds].size.height==1024&&UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface DocumentFileViewController ()

@end

@implementation DocumentFileViewController
@synthesize rootPath;

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
//    NSLog(@"%@",NSHomeDirectory());
//    [self addChildViewController:tipViewController];
//    [self.view addSubview:tipViewController.view];
//    [self performSelector:@selector(showTip) withObject:nil afterDelay:1];
    debugString=[[NSMutableString alloc] init];
    isMain=!rootPath;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationCame:) name:@"FileRefreshed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adRemoved:) name:@"adRemoved" object:nil];
    if (isMain) {
        NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths2 objectAtIndex:0];
        rootPath=documentsDirectory;NSLog(@"%@",rootPath);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileCome:) name:@"FileCome" object:nil];
        defaultItem=nil;
        
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"HelpHasShown"] boolValue]) {
            [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:NSLocalizedString(@"File Drop入门", @"")  ofType:@"pdf"] toPath:[NSString stringWithFormat:@"%@/%@.pdf",documentsDirectory,NSLocalizedString(@"File Drop入门", @"")] error:nil];
//            [self performSelector:@selector(showHelpDocument) withObject:nil afterDelay:0.5];
        }

        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"TipsHasShown"] boolValue]) {
            [self performSelector:@selector(showTips) withObject:nil afterDelay:0.1];
        }else{
            [self showAd];
        }

    }else{
        self.navigationItem.title=[rootPath substringFromIndex:[rootPath rangeOfString:@"/" options:NSBackwardsSearch].location+1];
        defaultItem=self.navigationItem.leftBarButtonItem;
    }
    [self.navigationItem setRightBarButtonItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)]]];
    [self refreshFiles];

    showDelete=YES;
    adCounter=0;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)showTips{
    imageview=[[UIImageView alloc] initWithFrame:self.navigationController.view.bounds];
    [imageview setImage:[UIImage imageNamed:[self tipImageNameForCurrentDevice]]];
    imageview.alpha=0;
    imageview.userInteractionEnabled=YES;
    UITapGestureRecognizer *tabgr=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClicked:)];
    [imageview addGestureRecognizer:tabgr];
    [self.navigationController.view addSubview:imageview];
    [UIView animateWithDuration:1 animations:^{
        imageview.alpha=1;
    }];
}
- (NSString*)tipImageNameForCurrentDevice{
    if ([[[NSLocale currentLocale] displayNameForKey:NSLocaleLanguageCode value:[[NSLocale currentLocale] localeIdentifier]] isEqual:@"English"]) {
        if (isPad) {
            if (isIpadLandscape) {
                return @"tipspadlen";
            }else{
                return @"tipspadpen";
            }
        }else{
            if (is3_5inch) {
                return @"tips3en";
            }else{
                return @"tips4en";
            }
        }
    }else{
        if (isPad) {
            if (isIpadLandscape) {
                return @"tipspadlcn";
            }else{
                return @"tipspadpcn";
            }
        }else{
            if (is3_5inch) {
                return @"tips3cn";
            }else{
                return @"tips4cn";
            }
        }
        
    }
    return @"tips4en";
}
-(void)imageClicked:(id)sender{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"TipsHasShown"];
    [UIView animateWithDuration:1 animations:^{
        imageview.alpha=0;
    } completion:^(BOOL finished) {
        [imageview removeFromSuperview];
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"HelpHasShown"] boolValue]) {
            [self showHelpDocument];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"HelpHasShown"];
        }
        [self showAd];
    }];
}
-(void)showAd{
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"God"] isEqualToString:[[[HashGetter alloc] init] hasValueForDevice]]) {
        NSLog(@"ad");
        //        self.canDisplayBannerAds=YES;
        ad=[[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        ad.delegate=self;
        [self showDebugContent:@"<Apple>iAD Banner View created, and delegate set"];
        gad=[[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        gad.rootViewController=self;
        gad.adUnitID=@"ca-app-pub-5582831528265540/4025528712";
        GADRequest *req=[[GADRequest alloc] init];
        //req.testDevices=@[GAD_SIMULATOR_ID];
        gad.delegate=self;
        [gad loadRequest:req];
        [self showDebugContent:@"<Google>Google AD Banner created, and request started "];
    }

}
-(void)showHelpDocument{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}
-(void)showDebugContent:(NSString*)content{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm:ss"];
    [debugString appendFormat:@" %@ at %@.\n",content,[dateFormatter stringFromDate:[NSDate date]]];
}
- (void)adViewDidReceiveAd:(GADBannerView *)view{
    if (self.tableView.tableHeaderView!=view) {
        [UIView animateWithDuration:0.4 animations:^{
            self.tableView.tableHeaderView=view;
        }];
    }
    adCounter++;
    [self showDebugContent:[NSString stringWithFormat:@"<Google>adViewDidReceiveAd with counter=%ld",adCounter]];
    if (adCounter>5) {
        if (ad) {
            ad.delegate=nil;
            ad=nil;
        }
    }
}
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error{
    [self showDebugContent:[NSString stringWithFormat:@"<Apple>bannerViewdidFailToReceiveAdWithError:%@",error.localizedDescription]];
    if (!gad) {
        gad=[[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        gad.rootViewController=self;
        gad.adUnitID=@"a153132625704d6";
        GADRequest *req=[[GADRequest alloc] init];
        req.testDevices=@[GAD_SIMULATOR_ID];
        gad.delegate=self;
        [gad loadRequest:req];
    }
}
- (void)bannerViewDidLoadAd:(ADBannerView *)banner{
    [self showDebugContent:@"<Apple>bannerViewDidLoadAd"];
    if (self.tableView.tableHeaderView!=ad) {
        [UIView animateWithDuration:0.4 animations:^{
            self.tableView.tableHeaderView=ad;
            if(gad) gad.delegate=nil;
            gad=nil;
        }];
    }
}

-(void)adRemoved:(NSNotification*)noti{
    [self showDebugContent:@"<Both>adRemoved"];
    self.tableView.tableHeaderView=nil;
    ad.delegate=nil;
    gad.delegate=nil;
    ad=nil;
    gad=nil;
}
-(IBAction)cameraSelect:(id)sender{
    UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"选择来源", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"从照片库导入照片",@""),NSLocalizedString(@"从照片库导入视频",@""),[UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]?NSLocalizedString(@"拍照或摄像",@""):nil, nil];
    if (isPad) {
        [action showFromBarButtonItem:sender animated:YES];
    }else{
        [action showInView:self.navigationController.view];
    }

}
-(void)fileCome:(NSNotification*)noti{
    NSLog(@"fileCome");
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self refreshFiles];
    for (NSInteger i=0; i<files.count; i++) {
        if ([[files objectAtIndex:i] isEqualToString:@"Inbox"]) {
            NSLog(@"got");
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
}
-(void)notificationCame:(NSNotification*)noti{
    NSLog(@"notificationCame");
    [self refreshFiles];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return files.count;
}
-(NSString*)packageExt:(NSString*)name{
    if ([name rangeOfString:@"."].location==NSNotFound) {
        return nil;
    }
    NSString *ext=[name substringFromIndex:[name rangeOfString:@"." options:NSBackwardsSearch].location+1];
    NSArray *supportExts=@[@"pages",@"key",@"numbers"];
    if([supportExts indexOfObject:ext]!=NSNotFound){
        return ext;
    }
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSString *name=[files objectAtIndex:indexPath.row];
    cell.textLabel.text=name;
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,name] isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *ext=[self packageExt:[NSString stringWithFormat:@"%@/%@",rootPath,name]];
        if (ext) {
            [cell.imageView setImage:[UIImage imageNamed:ext]];
            cell.detailTextLabel.text=NSLocalizedString(@"文档包",@"");
        }else{
            [cell.imageView setImage:[UIImage imageNamed:@"folder"]];
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%lu%@",(unsigned long)[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,name] error:nil].count,NSLocalizedString(@"个项目",@"")];
        }
    }else{
        cell.detailTextLabel.text=[self packSize:[NSNumber numberWithDouble:[[[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,name] error:nil] fileSize]]];
        NSInteger index=[name rangeOfString:@"." options:NSBackwardsSearch].location;
        if (index==NSNotFound) {
            [cell.imageView setImage:[UIImage imageNamed:@"empty"]];
        }else{
            NSString *ext=[[name substringFromIndex:index+1] lowercaseString];
            if ([ext isEqualToString:@"bmp"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"bmp"]];
            }else if ([ext isEqualToString:@"csv"]){
                [cell.imageView setImage:[UIImage imageNamed:@"csv"]];                
            }else if ([ext isEqualToString:@"gif"]){
                [cell.imageView setImage:[UIImage imageNamed:@"gif"]];
            }else if ([ext isEqualToString:@"html"]||[ext isEqualToString:@"htm"]||[ext isEqualToString:@"xhtml"]){
                [cell.imageView setImage:[UIImage imageNamed:@"html"]];
            }else if ([ext isEqualToString:@"jpg"]||[ext isEqualToString:@"jpeg"]){
                [cell.imageView setImage:[UIImage imageNamed:@"jpg"]];
            }else if ([ext isEqualToString:@"key"]||[ext isEqualToString:@"ppt"]||[ext isEqualToString:@"pptx"]||[ext isEqualToString:@"pps"]){
                [cell.imageView setImage:[UIImage imageNamed:@"key"]];
            }else if ([ext isEqualToString:@"mov"]){
                [cell.imageView setImage:[UIImage imageNamed:@"mov"]];
            }else if ([ext isEqualToString:@"mp3"]||[ext isEqualToString:@"m4a"]){
                [cell.imageView setImage:[UIImage imageNamed:@"mp3"]];
            }else if ([ext isEqualToString:@"mp4"]||[ext isEqualToString:@"mpeg4"]||[ext isEqualToString:@"m4v"]){
                [cell.imageView setImage:[UIImage imageNamed:@"mp4"]];
            }else if ([ext isEqualToString:@"numbers"]||[ext isEqualToString:@"xls"]||[ext isEqualToString:@"xlsx"]){
                [cell.imageView setImage:[UIImage imageNamed:@"numbers"]];
            }else if ([ext isEqualToString:@"pages"]||[ext isEqualToString:@"doc"]||[ext isEqualToString:@"docx"]){
                [cell.imageView setImage:[UIImage imageNamed:@"pages"]];
            }else if ([ext isEqualToString:@"pdf"]){
                [cell.imageView setImage:[UIImage imageNamed:@"pdf"]];
            }else if ([ext isEqualToString:@"png"]){
                [cell.imageView setImage:[UIImage imageNamed:@"png"]];
            }else if ([ext isEqualToString:@"rtf"]){
                [cell.imageView setImage:[UIImage imageNamed:@"rtf"]];
            }else if ([ext isEqualToString:@"tiff"]||[ext isEqualToString:@"tif"]){
                [cell.imageView setImage:[UIImage imageNamed:@"tiff"]];
            }else if ([ext isEqualToString:@"txt"]){
                [cell.imageView setImage:[UIImage imageNamed:@"txt"]];
            }else if ([ext isEqualToString:@"zip"]){
                [cell.imageView setImage:[UIImage imageNamed:@"zip"]];
            }else{
                [cell.imageView setImage:[UIImage imageNamed:@"empty"]];
            }
        }
    }
    [cell.imageView setFrame:CGRectMake(cell.imageView.frame.origin.x, cell.imageView.frame.origin.y, 40, 40)];
    // Configure the cell...
    
    return cell;
}
-(void)refreshFiles{
    files=[NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootPath error:nil]];
    for (NSInteger i=0; i<files.count; i++) {
        if ([[files objectAtIndex:i] isEqualToString:@"Inbox"]&&[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:i]] error:nil].count==0) {
            [files removeObjectAtIndex:i];
            break;
        }
    }
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.isEditing) {
        return;
    }
    NSString *path=[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:indexPath.row]];
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"错误",@"") message:NSLocalizedString(@"文件不存在",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil] show];
        [self refreshFiles];
        return;
    }
    if (isDirectory) {
        if ([self packageExt:path]) {
            tempPath=[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:indexPath.row]];
            dic=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tempPath]];
            dic.delegate=self;
            if (![dic presentPreviewAnimated:YES]) {
                [self performSegueWithIdentifier:@"content" sender:path];                
            }
        }else{
            [self performSegueWithIdentifier:@"content" sender:path];
        }
    }else{
        tempPath=[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:indexPath.row]];
        dic=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tempPath]];
        dic.delegate=self;
        if (![dic presentPreviewAnimated:YES]) {
            paths=[NSArray arrayWithObject:tempPath];
            UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"分享",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"通过File Drop发送",@""),NSLocalizedString(@"用其他应用打开",@""), nil];
            [action showInView:self.navigationController.view];
        }
    }
}
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self.navigationController;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    tempPath=[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:indexPath.row]];
    [self performSegueWithIdentifier:@"detail" sender:nil];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:indexPath.row]] error:&error];
        NSLog(@"%@",error);
        [files removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (showDelete) {
        return UITableViewCellEditingStyleDelete;
    }else{
        return UITableViewCellEditingStyleDelete|UITableViewCellEditingStyleInsert;
    }
}

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

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */
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

- (IBAction)edit:(id)sender {
    if (self.tableView.isEditing) {
        showDelete=YES;
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self.tableView setEditing:NO animated:YES];
            [self.navigationItem setRightBarButtonItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)]] animated:YES];
    }else{
        [self.navigationController setToolbarHidden:YES animated:YES];
        showDelete=NO;
        [self.tableView setEditing:YES animated:YES];
        [self.navigationItem setRightBarButtonItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(edit:)],[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]] animated:YES];
    }
}

- (IBAction)newFolder:(id)sender {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"新建文件夹",@"") message:NSLocalizedString(@"请输入文件夹名",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") otherButtonTitles:NSLocalizedString(@"好",@""), nil];
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    NSString *name=NSLocalizedString(@"未命名文件夹",@"");
    NSInteger i=2;
    while ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,name]]) {
        name=[NSString stringWithFormat:@"%@ %ld",NSLocalizedString(@"未命名文件夹",@""),(long)i++];
    }
    [alert textFieldAtIndex:0].text=name;
    [alert show];
}

- (IBAction)report:(id)sender {
    mfc=[[MFMailComposeViewController alloc] init];
    [mfc setMailComposeDelegate:self];
    [mfc setSubject:@"File Drop AD Report"];
    [mfc setMessageBody:debugString isHTML:NO];
    [mfc setToRecipients:@[@"x@xiongdianpku.com"]];
    [self presentViewController:mfc animated:YES completion:nil];
}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [mfc dismissViewControllerAnimated:YES completion:nil];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:NSLocalizedString(@"新建文件夹",@"")]) {
        if ([alertView textFieldAtIndex:0].text.length==0) {
            return;
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,[alertView textFieldAtIndex:0].text] withIntermediateDirectories:YES attributes:nil error:nil];
        [self refreshFiles];
    }
}
-(void)onAction:(id)sender{
    NSInteger count= self.tableView.indexPathsForSelectedRows.count;
    UIActionSheet *action;
    if (count==0) {
        action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"全选",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"全选",@""), nil];
    }else{
        action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"选择操作",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"通过File Drop发送",@""),NSLocalizedString(@"复制所选文件",@""),[NSString stringWithFormat:@"%@%ld%@",NSLocalizedString(@"删除选中的",@""),(long)count,NSLocalizedString(@"个项目",@"")], nil];
        [action setDestructiveButtonIndex:action.numberOfButtons-2];
    }
    if (isPad) {
        [action showFromBarButtonItem:sender animated:YES];
    }else{
        [action showInView:self.navigationController.view];
    }
}
-(IBAction)addSelect:(id)sender{
    NSArray *arr=[[UIPasteboard generalPasteboard] strings];
    if (!arr||arr.count<3||![[arr firstObject] isEqual:@"File_Drop_Pasteboard_Items"]) {
        [self performSegueWithIdentifier:@"recieve" sender:nil];
    }else{
        UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"从哪里添加？", @"")  delegate:self cancelButtonTitle:NSLocalizedString(@"取消", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"从File Drop接收",@""),NSLocalizedString(@"粘贴至此",@""),NSLocalizedString(@"移动至此",@""), nil];
        [action showFromBarButtonItem:sender animated:YES];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==actionSheet.cancelButtonIndex) {
        return;
    }
    if ([actionSheet.title isEqualToString:NSLocalizedString(@"选择来源",@"")]) {
        if(buttonIndex==0){
            QBImagePickerController *imagePicker=[[QBImagePickerController alloc] init];
            imagePicker.delegate=self;
            imagePicker.allowsMultipleSelection=YES;
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:imagePicker] animated:YES completion:nil];
        }else if (buttonIndex==1){
            UIImagePickerController *imagePicker=[[UIImagePickerController alloc] init];
            imagePicker.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.mediaTypes=[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
            imagePicker.delegate=self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }else if (buttonIndex==2){
            UIImagePickerController *imagePicker=[[UIImagePickerController alloc] init];
            imagePicker.sourceType=UIImagePickerControllerSourceTypeCamera;
            imagePicker.mediaTypes=[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
            imagePicker.delegate=self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }else if([actionSheet.title isEqualToString:NSLocalizedString(@"选择操作",@"")]){
        if (buttonIndex==0) {
            NSMutableArray *ps=[[NSMutableArray alloc] init];
            NSArray *arr=[self.tableView indexPathsForSelectedRows];
            for (NSInteger i=0; i<arr.count; i++) {
                [ps addObject:[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:[[arr objectAtIndex:i] row]]]];
            }
            paths=ps;
            [self performSegueWithIdentifier:@"device" sender:nil];
        }else if(buttonIndex==2){
            UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"确认删除",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:NSLocalizedString(@"删除",@"") otherButtonTitles: nil];
            [sheet showInView:self.view];
        }else if (buttonIndex==1){
            NSMutableArray *ps=[[NSMutableArray alloc] initWithObjects:@"File_Drop_Pasteboard_Items",rootPath, nil];
            NSArray *arr=[self.tableView indexPathsForSelectedRows];
            for (NSInteger i=0; i<arr.count; i++) {
                [ps addObject:[files objectAtIndex:[[arr objectAtIndex:i] row]]];
            }
            [[UIPasteboard generalPasteboard] setStrings:ps];
        }
    }else if ([actionSheet.title isEqualToString:NSLocalizedString(@"全选",@"")]){
        for (NSInteger i=0; i<files.count; i++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
        }
    }else if ([actionSheet.title isEqualToString:NSLocalizedString(@"分享",@"")]){
        if (buttonIndex==0) {
            [self performSegueWithIdentifier:@"device" sender:nil];
        }else if (buttonIndex==1){
            dic=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:tempPath]];
            dic.delegate=self;
            [dic presentOptionsMenuFromRect:self.navigationController.view.frame inView:self.navigationController.view animated:YES];
        }
    }else if ([actionSheet.title isEqualToString:NSLocalizedString(@"确认删除",@"")]){
        if (buttonIndex==0) {
            NSArray *arr=[self.tableView indexPathsForSelectedRows];
            NSMutableIndexSet *indexSet=[[NSMutableIndexSet alloc] init];
            NSMutableArray *paths2=[[NSMutableArray alloc] init];
            for (NSInteger i=0; i<arr.count; i++) {
                [indexSet addIndex:[[arr objectAtIndex:i] row]];
                [paths2 addObject:[NSIndexPath indexPathForRow:[[arr objectAtIndex:i] row] inSection:0]];
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:[[arr objectAtIndex:i] row]]] error:nil];
            }
            [files removeObjectsAtIndexes:indexSet];
            [self.tableView deleteRowsAtIndexPaths:paths2 withRowAnimation:UITableViewRowAnimationFade];

        }
    }else if ([actionSheet.title isEqualToString:NSLocalizedString(@"从哪里添加？",@"")]){
        if (buttonIndex==0) {
            [self performSegueWithIdentifier:@"recieve" sender:nil];
        }else if(buttonIndex==1){
            hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
            [self.navigationController.view addSubview:hud];
            hud.labelText=@"正在复制";
            [hud show:YES];
            [self performSelectorInBackground:@selector(copyInBackground) withObject:nil];
        }else if (buttonIndex==2){
            NSArray *arr=[[UIPasteboard generalPasteboard] strings];
            NSString *root=[arr objectAtIndex:1];
            NSInteger errorCount=0;
            if ([rootPath isEqualToString:root]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"错误", @"") message:NSLocalizedString(@"要移动的目的地与原位置相同", @"") delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil]show];
                return;
            }
            for (NSInteger i=2; i<arr.count; i++) {
                NSString *currentPath=[arr objectAtIndex:i];
                NSError *err;
                [[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"%@/%@",root,currentPath] toPath:[NSString stringWithFormat:@"%@/%@",rootPath,currentPath] error:&err];
                if(err) errorCount++;
            }
            [[UIPasteboard generalPasteboard] setStrings:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
        }
    }
}
-(void)copyInBackground{
    NSArray *arr=[[UIPasteboard generalPasteboard] strings];
    NSString *root=[arr objectAtIndex:1];
    NSInteger errorCount=0;
    for (NSInteger i=2; i<arr.count; i++) {
        NSString *currentPath=[arr objectAtIndex:i];
        NSError *err;
        [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@",root,currentPath] toPath:[NSString stringWithFormat:@"%@/%@%@",rootPath,currentPath,[root isEqualToString:rootPath]?@" 副本":@""] error:&err];
        if(err) errorCount++;
    }
    [self performSelectorOnMainThread:@selector(copyFinished) withObject:nil waitUntilDone:YES];
}
-(void)copyFinished{
    [[UIPasteboard generalPasteboard] setStrings:nil];
    [self refreshFiles];
    [hud hide:YES];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"content"]) {
        DocumentFileViewController *dest=segue.destinationViewController;
        [dest setRootPath:[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:self.tableView.indexPathForSelectedRow.row]]];
    }else if ([segue.identifier isEqualToString:@"device"]){
        DeviceViewController *dest=segue.destinationViewController;
        [dest setRootPath:rootPath];
        NSMutableArray *destFiles=[[NSMutableArray alloc] init];
        for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
            [destFiles addObject:[NSString stringWithFormat:@"%@/%@",rootPath,[files objectAtIndex:indexPath.row]]];
        }
        [dest setPaths:[NSArray arrayWithArray:destFiles]];
    }else if ([segue.identifier isEqualToString:@"detail"]){
        DetailFileTableViewController *dest=segue.destinationViewController;
        [dest setPath:tempPath];
    }else if ([segue.identifier isEqualToString:@"write"]){
        UINavigationController *dest=segue.destinationViewController;
        WriterViewController *writer=[dest.viewControllers objectAtIndex:0];
        [writer setRootPath:rootPath];
    }else if ([segue.identifier isEqualToString:@"recieve"]){
        RecieveFileViewController *dest=(RecieveFileViewController*)[[segue.destinationViewController viewControllers] objectAtIndex:0];
        [dest setRootPath:rootPath];
    }
}
- (void)imagePickerController:(UIViewController *)picker didFinishPickingMediaWithInfo:(id)info{
    if ([picker respondsToSelector:@selector(allowsMultipleSelection)]) {
        NSArray *mediaInfoArray = (NSArray *)info;
        hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
        hud.labelText=NSLocalizedString(@"正在保存", @"");
        hud.mode=MBProgressHUDModeDeterminateHorizontalBar;
        [hud show:YES];
        [self performSelectorInBackground:@selector(saveMultiImageInBackground:) withObject:mediaInfoArray];
    }else{
        if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeMovie]) {
            NSString *destinationPath;
            NSInteger i=1;
            BOOL isD;
            while (destinationPath=i==1?[NSString stringWithFormat:@"%@/Movie.mov",rootPath]:[NSString stringWithFormat:@"%@/Movie %ld.mov",rootPath,(long)i],[[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isD]&&!isD){
                i++;
            }
            [[NSFileManager defaultManager] moveItemAtURL:[info objectForKey:UIImagePickerControllerMediaURL] toURL:[NSURL fileURLWithPath:destinationPath] error:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
        }else{
            UIImage* image=[info objectForKey:UIImagePickerControllerOriginalImage];
            hud=[[MBProgressHUD alloc] initWithView:self.navigationController.view];
            hud.labelText=NSLocalizedString(@"正在保存",@"");
            [self.navigationController.view addSubview:hud];
            [hud show:YES];
            [self performSelectorInBackground:@selector(saveImageInBackground:) withObject:image];
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}


-(void)saveMultiImageInBackground:(NSArray*)infos{
    for (NSInteger i=0; i<infos.count; i++) {
        [self performSelectorOnMainThread:@selector(refreshProgress:) withObject:[NSNumber numberWithFloat:(CGFloat)i/infos.count] waitUntilDone:YES];
        UIImage *image=[[infos objectAtIndex:i] objectForKey:UIImagePickerControllerOriginalImage];
        NSString *destinationPath;
        NSInteger i=1;
        BOOL isD;
        while (destinationPath=i==1?[NSString stringWithFormat:@"%@/Photo.jpg",rootPath]:[NSString stringWithFormat:@"%@/Photo %ld.jpg",rootPath,(long)i],[[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isD]&&!isD){
            i++;
        }
        [UIImageJPEGRepresentation(image, 1) writeToFile:destinationPath atomically:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
    }
    [self performSelectorOnMainThread:@selector(clearHUD) withObject:nil waitUntilDone:YES];
}
-(void)refreshProgress:(NSNumber*)progress{
    [hud setProgress:[progress floatValue]];
}
-(void)saveImageInBackground:(UIImage*)image{
    NSString *destinationPath;
    NSInteger i=1;
    BOOL isD;
    while (destinationPath=i==1?[NSString stringWithFormat:@"%@/Photo.jpg",rootPath]:[NSString stringWithFormat:@"%@/Photo %ld.jpg",rootPath,(long)i],[[NSFileManager defaultManager] fileExistsAtPath:destinationPath isDirectory:&isD]&&!isD){
        i++;
    }
    [UIImageJPEGRepresentation(image, 1) writeToFile:destinationPath atomically:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
    [self performSelectorOnMainThread:@selector(clearHUD) withObject:nil waitUntilDone:YES];
}
-(void)clearHUD{
    [hud hide:NO];
}
#pragma mark - QBImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"Cancelled");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString *)descriptionForSelectingAllAssets:(QBImagePickerController *)imagePickerController
{
    return @"全选";
}

- (NSString *)descriptionForDeselectingAllAssets:(QBImagePickerController *)imagePickerController
{
    return @"取消全选";
}

- (NSString *)imagePickerController:(QBImagePickerController *)imagePickerController descriptionForNumberOfPhotos:(NSUInteger)numberOfPhotos
{
    NSLog(@"%d",numberOfPhotos);
    return [NSString stringWithFormat:@"%lu张照片", (long)numberOfPhotos];
}

- (NSString *)imagePickerController:(QBImagePickerController *)imagePickerController descriptionForNumberOfVideos:(NSUInteger)numberOfVideos
{
    return [NSString stringWithFormat:@"%lu个视频", (long)numberOfVideos];
}

- (NSString *)imagePickerController:(QBImagePickerController *)imagePickerController descriptionForNumberOfPhotos:(NSUInteger)numberOfPhotos numberOfVideos:(NSUInteger)numberOfVideos
{
    return [NSString stringWithFormat:@"%lu张照片和%lu个视频", (long)numberOfPhotos, (long)numberOfVideos];
}

@end
