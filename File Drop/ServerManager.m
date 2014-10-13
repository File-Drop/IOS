//
//  ServerManager.m
//  File Drop
//
//  Created by 熊典 on 14-2-2.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "ServerManager.h"
#import "AMFArchiver.h"
#import "AMFUnarchiver.h"
#import "AMF.h"
#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//-1......to be delete
// 1......waiting for command
// 2......waiting for name list
// 3......waiting for total info
// 4......waiting for file path

@implementation ServerManager
@synthesize delegate,rootPath;
-(BOOL)startServer{
    serverSocket=[[AsyncSocket alloc] initWithDelegate:self];
    sockets=[NSMutableArray array];
    [serverSocket acceptOnPort:12345 error:nil];
    
    myPeerID=[[MCPeerID alloc] initWithDisplayName:[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"]];
    advertiser=[[MCNearbyServiceAdvertiser alloc] initWithPeer:myPeerID discoveryInfo:@{@"type": isPad?@"ipad":@"iphone"} serviceType:@"filedrop"];
    advertiser.delegate=self;
    session=[[MCSession alloc] initWithPeer:myPeerID];
    session.delegate=self;
    [advertiser startAdvertisingPeer];

    return YES;
}
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler{
    if (isSendingFile) {
        invitationHandler(NO,session);
        return;
    }
    invitationHandler(YES,session);
    isSendingFile=YES;
}
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    if (state==MCSessionStateConnected) {
        self->peerID=peerID;
    }else if (state==MCSessionStateNotConnected){
        [self performSelectorOnMainThread:@selector(showAlert) withObject:nil waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(tellDelegateDidFailed) withObject:nil waitUntilDone:YES];
        if (acceptAlert) {
            [acceptAlert dismissWithClickedButtonIndex:3 animated:NO];
        }
        acceptAlert=nil;
        isSendingFile=NO;
    }
}
-(void)tellDelegateDidFailed{
    [delegate serverManager:self didFailFileTransportWithUser:currentUserName];
}
-(void)showAlert{
    [[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"传输中断",@"") message:NSLocalizedString(@"对方中断了文件传输",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSArray *filesInfo=(NSArray*)[AMF3Unarchiver unarchiveObjectWithData:data encoding:kAMF3Encoding];
    if (!filesInfo) {
        NSString *messageUserName;
        message=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([message rangeOfString:@"\n"].location==NSNotFound) {
            messageUserName=NSLocalizedString(@"有人",@"");
        }else{
            messageUserName=[message substringToIndex:[message rangeOfString:@"\n"].location];
            message=[message substringFromIndex:[message rangeOfString:@"\n"].location+1];
        }
        BOOL isURL=NO;
        if (message.length>7&&[[[message substringToIndex:7] lowercaseString] isEqualToString:@"http://"]) {
            isURL=YES;
        }else if (message.length>8&&[[[message substringToIndex:8] lowercaseString] isEqualToString:@"https://"]){
            isURL=YES;
        }else if (message.length>12&&[[[message substringToIndex:12] lowercaseString] isEqualToString:@"itms-apps://"]){
            isURL=YES;
        }else if (message.length>16&&[[[message substringToIndex:16] lowercaseString] isEqualToString:@"itms-services://"]){
            isURL=YES;
        }
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"收到文本",@"") message:[NSString stringWithFormat:@"%@%@\n%@",messageUserName,NSLocalizedString(@"给您发送了文本：",@""),message] delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") otherButtonTitles:NSLocalizedString(@"复制",@""),NSLocalizedString(@"保存",@""),isURL?NSLocalizedString(@"打开链接",@""):nil ,nil] show];
        return;
    }
    NSMutableString *str=[NSMutableString string];
//    NSLog(@"%@",filesInfo);
    totalSize=[[filesInfo objectAtIndex:1] doubleValue];
    for (NSInteger i=2; i<filesInfo.count; i++) {
        NSDictionary *cur=[filesInfo objectAtIndex:i];
        [str appendFormat:@"%@  %@\n",[cur objectForKey:@"name"],[[cur objectForKey:@"isD"] boolValue]?NSLocalizedString(@"文件夹",@""):[self packSize:[NSNumber numberWithDouble:[[cur objectForKey:@"size"] doubleValue]]]];
    }
    currentUserName=[filesInfo objectAtIndex:0];
    NSString *msg=[NSString stringWithFormat:@"%@ %@\n%@",NSLocalizedString(@"给您发送下列文件：",@""),currentUserName,str];
    acceptAlert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"收到文件",@"") message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"拒绝",@"") otherButtonTitles:NSLocalizedString(@"接受",@""), nil];
    isSendingFile=YES;
    progressCount=0;
    [acceptAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    currentSize=[progress totalUnitCount];
    [self.delegate serverManager:self didBeginRecievingFileNamed:resourceName];
    [self performSelectorOnMainThread:@selector(refreshProgress:) withObject:progress waitUntilDone:NO];
}
-(void)refreshProgress:(NSProgress *)progress{
    if ([progress fractionCompleted]>=1) {
        return;
    }
    [self.delegate serverManager:self didReachProgress:(progressCount+progress.fractionCompleted*currentSize)/totalSize];
    [self performSelector:@selector(refreshProgress:) withObject:progress afterDelay:0.2];
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    currentFileName=resourceName;
    currentPath=[NSString stringWithFormat:@"%@/%@",rootPath,currentFileName];
    BOOL isD;
    if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath isDirectory:&isD]) {
        if (!isD) {
            [[NSFileManager defaultManager] removeItemAtPath:currentPath error:nil];
        }
    }
    BOOL isDir;
    NSString *parentDir=[currentPath substringToIndex:[currentPath rangeOfString:@"/" options:NSBackwardsSearch].location];
    if (![[NSFileManager defaultManager] fileExistsAtPath:parentDir isDirectory:&isDir]||!isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parentDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if ([currentPath rangeOfString:@".DS_Store"].location!=NSNotFound) {
        return;
    }

    NSError *err;
    if (!localURL) {
        return;
    }
    [[NSFileManager defaultManager] moveItemAtURL:localURL toURL:[NSURL fileURLWithPath:currentPath] error:&err];
    progressCount+=[[[[NSFileManager defaultManager] attributesOfItemAtPath:currentPath error:nil] objectForKey:NSFileSize] doubleValue];
    if (progressCount>=totalSize) {
        [self performSelectorOnMainThread:@selector(recieveFinished) withObject:nil waitUntilDone:NO];
    }
}
-(void)recieveFinished{
    NSLog(@"finished");
    isSendingFile=NO;
    self->session.delegate=nil;
    self->session=nil;
    self->peerID=nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
    [delegate serverManager:self didFinishFileTransportWithUser:currentUserName];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket{
    newSocket.delegate=self;
    [sockets addObject:newSocket];
    [newSocket readDataWithTimeout:7 tag:1];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock{
    if (sock==currentSocket) {
        [[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"传输中断",@"") message:NSLocalizedString(@"对方中断了文件传输",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
        if (acceptAlert) {
            [acceptAlert dismissWithClickedButtonIndex:3 animated:NO];
        }
        [delegate serverManager:self didFailFileTransportWithUser:currentUserName];
        acceptAlert=nil;
        currentSocket=nil;
        isSendingFile=NO;
    }
    NSLog(@"disconnect");
    [sockets removeObject:sock];
}
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    switch (tag) {
        case 1:{
            NSString *command=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",command);
            if ([command isEqualToString:@"check port"]) {
                [sockets removeObject:sock];
            }else if ([command isEqualToString:@"ask for info"]){
                [sock writeData:[[NSString stringWithFormat:@"%@:%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"DeviceName"],isPad?@"ipad":@"iphone"] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:-1];
                [sock disconnectAfterWriting];
            }else if ([command isEqualToString:@"send file"]){
                if (isSendingFile) {
                    [sock writeData:[@"busy" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:2];
                }else{
                    size=0;
                    respondData=nil;
                    [sock writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:2];
                    [sock readDataWithTimeout:7 tag:2];
                }
            }else if ([command isEqualToString:@"send text"]){
                [sock writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:2];
                [sock readDataWithTimeout:7 tag:6];
            }
        }
            break;
        case 2:{
            if (size==0) {
                NSLog(@"data.length=%d",[data length]);
                Byte *b;
                [data getBytes:&b length:1];
                [data getBytes:&size length:4];
                respondData=[NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(4, data.length-4)]];
            }else{
                [respondData appendData:data];
            }
            if (respondData.length>=size) {
                size=0;
                NSArray *filesInfo=[AMFUnarchiver unarchiveObjectWithData:respondData encoding:kAMF3Encoding];
                NSMutableString *str=[NSMutableString string];
                for (NSInteger i=1; i<filesInfo.count; i++) {
                    NSDictionary *cur=[filesInfo objectAtIndex:i];
                    [str appendFormat:@"%@  %@\n",[cur objectForKey:@"name"],[[cur objectForKey:@"isD"] boolValue]?NSLocalizedString(@"文件夹",@""):[self packSize:[NSNumber numberWithDouble:[[cur objectForKey:@"size"] doubleValue]]]];
                }
                currentSocket=sock;
                currentUserName=[filesInfo objectAtIndex:0];
                NSString *msg=[NSString stringWithFormat:@"%@ %@\n%@",NSLocalizedString(@"给您发送下列文件：",@""),currentUserName,str];
                acceptAlert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"收到文件",@"") message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"拒绝",@"") otherButtonTitles:NSLocalizedString(@"接受",@""), nil];
                [acceptAlert show];
                isSendingFile=YES;
            }else{
                [sock readDataWithTimeout:7 tag:2];
            }
        }
            break;
        case 3:{
            [data getBytes:&totalSize length:8];
            progressCount=0;
            [sock writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:4];
            [sock readDataWithTimeout:7 tag:4];
            [delegate serverManager:self didBeginFileTransportWithUser:currentUserName totalBytes:[self packSize:[NSNumber numberWithDouble:totalSize]]];
        }
            break;
        case 4:{
            if (data.length==2) {
                isSendingFile=NO;
                currentSocket=nil;
                [sock disconnect];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
                [delegate serverManager:self didFinishFileTransportWithUser:currentUserName];
                return;
            }
            if (size==0) {
                [data getBytes:&size length:4];
                respondData=[NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(4, data.length-4)]];
            }else{
                [respondData appendData:data];
            }
            if (respondData.length>=size) {
                size=0;
                NSDictionary *info=[AMFUnarchiver unarchiveObjectWithData:respondData encoding:kAMF3Encoding];
                currentFileName=[info objectForKey:@"path"];
                currentPath=[NSString stringWithFormat:@"%@/%@",rootPath,currentFileName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:currentPath error:nil];
                }
                currentSize=[[info objectForKey:@"size"] doubleValue];
                [delegate serverManager:self didBeginRecievingFileNamed:currentFileName];
                [sock writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:5];
                [sock readDataWithTimeout:7 tag:5];
                if (currentSize==0) {
                    [self performSelector:@selector(sayOkToSocket:) withObject:sock afterDelay:1];
                }
            }else{
                [sock readDataWithTimeout:7 tag:4];
            }
        }
            break;
        case 5:{
            currentSize-=data.length;
            progressCount+=data.length;
            if (![self appendData:data toFilePath:currentPath]) {
                NSLog(@"%@",currentPath);
            }
            [delegate serverManager:self didReachProgress:progressCount/totalSize];
            if (currentSize<=0) {
                [self sayOkToSocket:sock];
                [sock readDataWithTimeout:7 tag:4];
            }else{
                [sock readDataWithTimeout:7 tag:5];
            }
        }
            break;
        case 6:{
            if (size==0) {
                [data getBytes:&size length:4];
                respondData=[NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(4, data.length-4)]];
            }else{
                [respondData appendData:data];
            }
            if (respondData.length>=size) {
                size=0;
                NSString *messageUserName;
                message=[[NSString alloc] initWithData:respondData encoding:NSUTF8StringEncoding];
                if ([message rangeOfString:@"\n"].location==NSNotFound) {
                    messageUserName=NSLocalizedString(@"有人",@"");
                }else{
                    messageUserName=[message substringToIndex:[message rangeOfString:@"\n"].location];
                    message=[message substringFromIndex:[message rangeOfString:@"\n"].location+1];
                }
                respondData=nil;
                [sock writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:7];
                BOOL isURL=NO;
                if (message.length>7&&[[[message substringToIndex:7] lowercaseString] isEqualToString:@"http://"]) {
                    isURL=YES;
                }else if (message.length>8&&[[[message substringToIndex:8] lowercaseString] isEqualToString:@"https://"]){
                    isURL=YES;
                }else if (message.length>12&&[[[message substringToIndex:12] lowercaseString] isEqualToString:@"itms-apps://"]){
                    isURL=YES;
                }else if (message.length>16&&[[[message substringToIndex:16] lowercaseString] isEqualToString:@"itms-services://"]){
                    isURL=YES;
                }
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"收到文本",@"") message:[NSString stringWithFormat:@"%@%@\n%@",messageUserName,NSLocalizedString(@"给您发送了文本：",@""),message] delegate:self cancelButtonTitle:NSLocalizedString(@"取消",@"") otherButtonTitles:NSLocalizedString(@"复制",@""),NSLocalizedString(@"保存",@""),isURL?NSLocalizedString(@"打开链接",@""):nil ,nil] show];
            }else{
                [sock readDataWithTimeout:7 tag:6];
            }

        }
    }
}
-(void)close{
    [serverSocket disconnect];
    serverSocket=nil;
    advertiser.delegate=nil;
    [advertiser stopAdvertisingPeer];
    advertiser=nil;
    session.delegate=nil;
    [session disconnect];
    session=nil;
}
-(void)sayOkToSocket:(AsyncSocket*)socket{
    [socket writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:4];
}
-(BOOL)appendData:(NSData*)data toFilePath:(NSString*)path{
    BOOL isDir;
    NSString *parentDir=[path substringToIndex:[path rangeOfString:@"/" options:NSBackwardsSearch].location];
    if (![[NSFileManager defaultManager] fileExistsAtPath:parentDir isDirectory:&isDir]||!isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:parentDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if ([path rangeOfString:@".DS_Store"].location!=NSNotFound) {
        return YES;
    }
    FILE* f= fopen([path UTF8String], "ab");
    if (f) {
        Byte *temp=malloc(data.length);
        [data getBytes:temp];
        fwrite(temp, 1, data.length, f);
        fclose(f);
        free(temp);
        return YES;
    }
    return NO;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (acceptAlert==alertView) {
        acceptAlert=nil;
        if (currentSocket) {
            if (buttonIndex==1) {
                [currentSocket writeData:[@"ok" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:3];
                [currentSocket readDataWithTimeout:7 tag:3];
            }else{
                [currentSocket writeData:[@"refuse" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:7 tag:3];
                [currentSocket disconnectAfterWriting];
                currentSocket=nil;
                isSendingFile=NO;
            }
        }else{
            if (buttonIndex==1) {
                NSError *err;
                [session sendData:[@"file accept" dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:&err];
                if (err) {
                    [[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"传输中断",@"") message:NSLocalizedString(@"对方中断了文件传输",@"") delegate:nil cancelButtonTitle:NSLocalizedString(@"好",@"") otherButtonTitles: nil]show];
                    return;
                }
                [delegate serverManager:self didBeginFileTransportWithUser:currentUserName totalBytes:[self packSize:[NSNumber numberWithDouble:totalSize]]];
            }else{
                [session sendData:[@"file refuse" dataUsingEncoding:NSUTF8StringEncoding] toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
                session=nil;
                peerID=nil;
            }
        }
    }else{
        if (buttonIndex==alertView.cancelButtonIndex) {
            return;
        }
        if (buttonIndex==1) {
            [[UIPasteboard generalPasteboard] setString:message];
        }else if(buttonIndex==2){
            NSString *name=[NSString stringWithFormat:@"%@.txt",NSLocalizedString(@"收到的文本",@"")];
            NSInteger i=2;
            NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths2 objectAtIndex:0];
            while ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",documentsDirectory,name]]) {
                name=[NSString stringWithFormat:@"%@ %ld.txt",NSLocalizedString(@"收到的文本",@""),(long)i++];
            }
            [message writeToFile:[NSString stringWithFormat:@"%@/%@",documentsDirectory,name] atomically:YES encoding:NSUnicodeStringEncoding error:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FileRefreshed" object:nil];
        }else if (buttonIndex==3){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:message]];
        }
    }
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
@end
