//
//  WriterViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-6.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "WriterViewController.h"
#import "DeviceViewController.h"
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define isLandscape UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])
@interface WriterViewController ()

@end

@implementation WriterViewController
@synthesize rootPath;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardDidChangeFrameNotification object:nil];
    self.textView.delegate=self;
    NSString *paste=[[UIPasteboard generalPasteboard] string];
    if (paste&&![paste isEqualToString:@"File_Drop_Pasteboard_Items"]) {
        self.textView.text=paste;
    }else{
        [self.textView becomeFirstResponder];
    }
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)cancel:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)dismissKeyboard:(id)sender{
    [self.textView resignFirstResponder];
}
-(void)action:(id)sender{
    UIActionSheet *action=[[UIActionSheet alloc] initWithTitle:NSLocalizedString( @"选择操作",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"通过File Drop发送",@""),NSLocalizedString(@"保存为文本文件",@""), nil];
    if (isPad) {
        [action showFromBarButtonItem:sender animated:YES];
    }else{
        [action showInView:self.view];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==actionSheet.cancelButtonIndex) {
        return;
    }
    if (buttonIndex==0) {
        [self performSegueWithIdentifier:@"device" sender:nil];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"保存文件",@"") message:NSLocalizedString(@"输入文件名",@"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") otherButtonTitles:NSLocalizedString(@"好",@""), nil];
        alert.alertViewStyle=UIAlertViewStylePlainTextInput;
        NSString *name=[NSString stringWithFormat:@"%@.txt",NSLocalizedString(@"未命名文本文件",@"")];
        NSInteger i=2;
        while ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",rootPath,name]]) {
            name=[NSString stringWithFormat:@"%@ %ld.txt",NSLocalizedString(@"未命名文本文件",@""),(long)i++];
        }
        [alert textFieldAtIndex:0].text=name;
        [alert show];

    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==alertView.cancelButtonIndex) {
        return;
    }
    if ([alertView.title isEqualToString:NSLocalizedString(@"保存文件",@"")]) {
        if ([alertView textFieldAtIndex:0].text.length==0) {
            return;
        }
        NSError *error;
        [self.textView.text writeToFile:[NSString stringWithFormat:@"%@/%@",rootPath,[alertView textFieldAtIndex:0].text] atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"保存失败",@"") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:0.8];
    }
}
-(void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)textViewDidBeginEditing:(UITextView *)textView{
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard:)] animated:YES];
}
- (void)textViewDidEndEditing:(UITextView *)textView{
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)] animated:YES];
}
-(void)keyboardHide:(NSNotification*)noti{
    self.textView.frame=self.view.frame;
}
-(void)keyboardShow:(NSNotification*)noti{
    NSDictionary* info = [noti userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGRect newrect=self.textView.frame;
    newrect.size.height=self.view.frame.size.height-(isLandscape?kbSize.width:kbSize.height)-32;
    self.textView.frame=newrect;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"device"]) {
        DeviceViewController *dest=segue.destinationViewController;
        [dest setSendType:@"text"];
        [dest setRootPath:rootPath];
        [dest setTextToSend:self.textView.text];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
