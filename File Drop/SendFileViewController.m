//
//  SendFileViewController.m
//  File Drop
//
//  Created by 熊典 on 14-2-4.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "SendFileViewController.h"
#import "AMF.h"
#import "AMFArchiver.h"

@interface SendFileViewController ()

@end

@implementation SendFileViewController
@synthesize paths,userName,ip,rootPath,sendType,textToSend,mcbrowser,targetPeer,mcsession;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    shouldStop=NO;
    if (mcbrowser) {
        mcsession.delegate=self;
        [self performSelector:@selector(invite) withObject:nil afterDelay:0.1];
    }else{
        socket=[[AsyncSocket alloc] initWithDelegate:self];
        [socket connectToHost:ip onPort:12345 error:nil];
    }
    if ([sendType isEqualToString:@"text"]) {
        self.progressBar.hidden=YES;
    }else{
        double size=0;
        expandedPaths=[NSMutableArray array];
        for (NSInteger i=0; i<paths.count; i++) {
            double tempSize;
            [expandedPaths addObjectsFromArray:[self getDirectoryContent:[paths objectAtIndex:i] totalSize:&tempSize]];
            size+=tempSize;
        }
        totalSize=size;
        self.tipLabel.text=[NSString stringWithFormat:NSLocalizedString(@"正在连接%@……",@""),userName];
        self.progressBar.progress=0;
    }
    [UIApplication sharedApplication].idleTimerDisabled=YES;

    // Do any additional setup after loading the view.
}
-(void)invite{
    mcbrowser.delegate=self;
    [mcbrowser invitePeer:targetPeer toSession:mcsession withContext:nil timeout:10];
}
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    if (state==MCSessionStateConnected) {
        if ([sendType isEqualToString:@"text"]) {
            self.tipLabel.text=[NSString stringWithFormat:@"%@%@……",NSLocalizedString(@"正在发送文本给",@""),userName];
            [session sendData:[[NSString stringWithFormat:@"%@\n%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"],textToSend] dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
        }else{
            self.tipLabel.text=[NSString stringWithFormat:@"%@%@%@……",NSLocalizedString(@"正在等待",@""),userName,NSLocalizedString(@"接受请求",@"")];
            NSMutableArray *fileList=[NSMutableArray arrayWithObjects:[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"],[NSNumber numberWithDouble:totalSize],nil];
            for (NSString *path in paths) {
                [fileList addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self fileNameAtPath:path],@"name",[NSNumber numberWithBool:[self isDirectory:path]],@"isD",[[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] stringValue],@"size", nil]];
            }
            NSData *data=[AMFArchiver archivedDataWithRootObject:fileList encoding:kAMF3Encoding];
            NSError *err;
            [session sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&err];
            if (err) {
                [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:[NSString stringWithFormat:@"%@%@",userName,NSLocalizedString(@"中断了传输",@"")]];
            }
        }
    }else if (state==MCSessionStateNotConnected){
        NSLog(@"not connected;");
        [self performSelectorOnMainThread:@selector(disconnected) withObject:nil waitUntilDone:YES];
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSString *string=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string isEqualToString:@"text ok"]) {
        self.tipLabel.text=NSLocalizedString(@"发送成功！",@"");
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
    }else if ([string isEqualToString:@"file accept"]){
        fileIndex=0;
        [self sendOneFileViaMC];
    }else if ([string isEqualToString:@"file refuse"]){
        [self performSelectorOnMainThread:@selector(berejected) withObject:nil waitUntilDone:YES];
    }
}
-(void)disconnected{
    [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:[NSString stringWithFormat:@"%@%@",userName,NSLocalizedString(@"中断了传输",@"")]];
}
-(void)berejected{
    [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:[NSString stringWithFormat:@"%@%@",userName,NSLocalizedString(@"拒绝了您的请求",@"")]];
}
-(void)settext:(NSString*)text{
    self.tipLabel.text=text;
}
-(void)sendOneFileViaMC{
    NSString *now=[expandedPaths objectAtIndex:fileIndex];
    NSString *currentName=[self fileNameAtPath:now];
    NSString *path=[now substringFromIndex:rootPath.length+1];
    [self performSelectorOnMainThread:@selector(settext:) withObject:[NSString stringWithFormat:NSLocalizedString(@"正在给%@发送文件：(%@)\n%@",@""),userName,[self packSize:[NSNumber numberWithDouble:totalSize]],currentName] waitUntilDone:YES];
    NSProgress *progress=[mcsession sendResourceAtURL:[NSURL fileURLWithPath:[expandedPaths objectAtIndex:fileIndex]] withName:path toPeer:targetPeer withCompletionHandler:^(NSError *error) {
        fileIndex++;
        if (fileIndex<expandedPaths.count) {
            [self sendOneFileViaMC];
        }else{
            mcsession.delegate=nil;
            mcsession=nil;
            [self performSelectorOnMainThread:@selector(finish) withObject:nil waitUntilDone:YES];
        }
    }];
    [progress setUserInfoObject:[NSNumber numberWithInt:fileIndex] forKey:@"index"];
    [self performSelectorOnMainThread:@selector(refreshProgress:) withObject:progress waitUntilDone:NO];
}
-(void)finish{
    [self dismissWithTitle:NSLocalizedString(@"完成",@"") reason:NSLocalizedString(@"文件传输完成",@"")];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"canRate" object:nil userInfo:nil];
}
-(void)refreshProgress:(NSProgress *)progress{
    if ([progress fractionCompleted]>=1) {
        return;
    }
    [self setProgress:[NSNumber numberWithDouble:((double)fileIndex+progress.fractionCompleted)/expandedPaths.count]];
    [self performSelector:@selector(refreshProgress:) withObject:progress afterDelay:0.2];
}



- (void)viewDidDisappear:(BOOL)animated{
    [UIApplication sharedApplication].idleTimerDisabled=NO;
}
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    if ([sendType isEqualToString:@"text"]) {
        self.tipLabel.text=[NSString stringWithFormat:@"%@%@……",NSLocalizedString(@"正在发送文本给",@""),userName];
        [sock writeData:[@"send text" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:6];
        [sock readDataWithTimeout:7 tag:6];
    }else{
        self.tipLabel.text=[NSString stringWithFormat:@"%@%@%@……",NSLocalizedString(@"正在等待",@""),userName,NSLocalizedString(@"接受请求",@"")];
        [sock writeData:[@"send file" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:0];
        [sock readDataWithTimeout:7 tag:0];
    }
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:[NSString stringWithFormat:@"%@%@",userName,NSLocalizedString(@"中断了传输",@"")]];
}
- (void)dismissWithTitle:(NSString*)title reason:(NSString*)reason{
    
    if (mcsession) {
        mcsession.delegate=nil;
        mcbrowser=nil;
        [mcsession disconnect];
        mcsession=nil;
    }else{
        @try {
            [socket disconnectAfterWriting];
            socket=nil;
        }
        @catch (NSException *exception) {
        
        }
        @finally {
            
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshDevice" object:nil];
    [[[UIAlertView alloc] initWithTitle:title message:reason delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
}
-(void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshDevice" object:nil];
}
-(NSString*)fileNameAtPath:(NSString*)path{
    return [path substringFromIndex:[path rangeOfString:@"/" options:NSBackwardsSearch].location+1];
}
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    switch (tag) {
        case 0:{
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"ok"]) {
                NSMutableArray *fileList=[NSMutableArray arrayWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"]];
                for (NSString *path in paths) {
                    [fileList addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self fileNameAtPath:path],@"name",[NSNumber numberWithBool:[self isDirectory:path]],@"isD",[[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] stringValue],@"size", nil]];
                }
                NSData *data=[AMFArchiver archivedDataWithRootObject:fileList encoding:kAMF3Encoding];
                Byte *length=malloc(4);
                length[0]=length[1]=length[2]=length[3]=0;
                *length=data.length;
                
                NSMutableData *dataToWrite=[NSMutableData dataWithBytes:length length:4];
                [dataToWrite appendData:data];
                [sock writeData:dataToWrite withTimeout:7 tag:1];
                [sock readDataWithTimeout:-1 tag:1];
            }else{
                [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:[NSString stringWithFormat:@"%@%@",userName,NSLocalizedString(@"正忙",@"")]];
            }
        }
            break;
        case 1:{
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"ok"]) {
                Byte *size=(Byte*)(&totalSize);
                [sock writeData:[NSData dataWithBytes:size length:8] withTimeout:7 tag:2];
                [sock readDataWithTimeout:7 tag:2];
                self.tipLabel.text=[NSString stringWithFormat:@"%@……(%@)",NSLocalizedString(@"准备传输文件",@""),[self packSize:[NSNumber numberWithDouble:totalSize]]];
            }else{
                [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:[NSString stringWithFormat:@"%@%@",userName,NSLocalizedString(@"拒绝了您的请求",@"")]];
            }
        }
            break;
        case 2:{
            fileIndex=0;
            progressCount=0;
        }
        case 3:{
            if (![[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"ok"]) {
                return;
            }
            if (fileIndex>=expandedPaths.count) {
                [sock writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:5];
                sock.delegate=nil;
                [self dismissWithTitle:NSLocalizedString(@"完成",@"") reason:NSLocalizedString(@"文件传输完成",@"")];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"canRate" object:nil userInfo:nil];
                return;
            }
            NSString *now=[expandedPaths objectAtIndex:fileIndex];
            NSData *data=[AMFArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:[[[[NSFileManager defaultManager] attributesOfItemAtPath:now error:nil] objectForKey:NSFileSize] stringValue],@"size",[now substringFromIndex:rootPath.length+1],@"path", nil] encoding:kAMF3Encoding];
            self.tipLabel.text=[NSString stringWithFormat:NSLocalizedString(@"正在给%@发送文件：(%@)\n%@",@""),userName,[self packSize:[NSNumber numberWithDouble:totalSize]],[now substringFromIndex:rootPath.length+1]];
            currentFileSize=[[[[NSFileManager defaultManager] attributesOfItemAtPath:now error:nil] objectForKey:NSFileSize] doubleValue];
            readedFileSize=0;
            Byte *length=malloc(4);
            length[0]=length[1]=length[2]=length[3]=0;
            *length=data.length;
            
            NSMutableData *dataToWrite=[NSMutableData dataWithBytes:length length:4];
            [dataToWrite appendData:data];
            [sock writeData:dataToWrite withTimeout:7 tag:4];
            [sock readDataWithTimeout:-1 tag:4];
        }
            break;
        case 4:{
            if (![[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"ok"]) {
                return;
            }
            fileStream=fopen([[expandedPaths objectAtIndex:fileIndex++] UTF8String], "r");
            [self performSelectorInBackground:@selector(sendFileContent) withObject:nil];
        }
            break;
        case 6:{
            if (![[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"ok"]) {
                return;
            }
            NSLog(@"%@",textToSend);
            NSData *stringData=[[NSString stringWithFormat:@"%@\n%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"],textToSend] dataUsingEncoding:NSUTF8StringEncoding];
            Byte *length=malloc(4);
            length[0]=length[1]=length[2]=length[3]=0;
            *length=stringData.length;
            
            NSMutableData *dataToWrite=[NSMutableData dataWithBytes:length length:4];
            [dataToWrite appendData:stringData];
            [sock writeData:dataToWrite withTimeout:7 tag:7];
            [sock readDataWithTimeout:-1 tag:7];
        }
            break;
        case 7:{
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] isEqualToString:@"ok"]) {
                self.tipLabel.text=NSLocalizedString(@"发送成功！",@"");
                [self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
            }else{
                self.tipLabel.text=NSLocalizedString(@"发送失败",@"");
                [self dismissWithTitle:NSLocalizedString(@"失败",@"") reason:NSLocalizedString(@"对方拒绝接收文本",@"")];
            }
        }
        default:
            break;
    }
}

-(void)setProgress:(NSNumber*)pro{
    self.progressBar.progress=[pro doubleValue];
}
-(void)sendFileContent{
    BOOL hasPerformed=NO;
    while (true) {
        if (shouldStop) {
            return;
        }
        CFIndex bytesDone,total;
        float percent=[socket progressOfWriteReturningTag:nil bytesDone:&bytesDone total:&total];
        [self performSelectorOnMainThread:@selector(setProgress:) withObject:[NSNumber numberWithDouble:(progressCount-(isnan(percent)?0:(total-bytesDone)))/totalSize] waitUntilDone:YES];
        if (isnan(percent)||total-bytesDone<5*1024) {
            if (!hasPerformed) {
                if (readedFileSize>=currentFileSize) {
                    fclose(fileStream);
                    [self performSelectorOnMainThread:@selector(readDataOnTag3) withObject:nil waitUntilDone:YES];
                    hasPerformed=YES;
                    continue;
                }
                int currentBufferLength=MIN(currentFileSize-readedFileSize,5*1024*1024);
                Byte *buffer=malloc(currentBufferLength);
                fread(buffer, currentBufferLength, 1, fileStream);
                progressCount+=currentBufferLength;
                readedFileSize+=currentBufferLength;
                
                self.progressBar.progress=(progressCount-(total-bytesDone))/totalSize;
                
                [self performSelectorOnMainThread:@selector(writeDataOnTag5:) withObject:[NSData dataWithBytes:buffer length:currentBufferLength] waitUntilDone:YES];
                free(buffer);
                if (readedFileSize>=currentFileSize) {
                    fclose(fileStream);
                    [self performSelectorOnMainThread:@selector(readDataOnTag3) withObject:nil waitUntilDone:YES];
                    hasPerformed=YES;
                    continue;
                }
            }else if (total-bytesDone<100*1024){
                NSLog(@"returned");
                return;
            }
        }
        usleep(50000);
    }
}
-(void)writeDataOnTag5:(NSData*)data{
    [socket writeData:data withTimeout:-1 tag:5];
}
-(void)readDataOnTag3{
    [socket readDataWithTimeout:-1 tag:3];
}
-(NSArray*)getDirectoryContent:(NSString*)path totalSize:(double*)size{
    if ([self isDirectory:path]) {
        double totalSize2=0;
        NSArray *temp=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        NSMutableArray *result=[NSMutableArray array];
        for (NSString *current in temp) {
            double tempSize;
            [result addObjectsFromArray:[self getDirectoryContent:[NSString stringWithFormat:@"%@/%@",path,current] totalSize:&tempSize]];
            totalSize2+=tempSize;
        }
        *size=totalSize2;
        return [NSArray arrayWithArray:result];
    }else{
        *size=[[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] doubleValue];
        return @[path];
    }
}
-(BOOL)isDirectory:(NSString*)path{
    BOOL result;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&result];
    return result;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancel:(id)sender {
    shouldStop=YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshDevice" object:nil];
    if (mcsession) {
        mcsession.delegate=nil;
        mcbrowser=nil;
        [mcsession disconnect];
        mcsession=nil;
    }else{
        socket=nil;
        [socket disconnectAfterWriting];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
