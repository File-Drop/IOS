//
//  DocumentPickerViewController.m
//  DP
//
//  Created by XiongDian on 14/10/9.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import "DocumentPickerViewController.h"
#import "DPFileCell.h"

@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController


-(void)prepareForPresentationInMode:(UIDocumentPickerMode)mode {
    NSLog(@"preparing");
    self.collectionView.delegate=self;
    self.collectionView.dataSource=self;
    
    NSString *documentsDirectory = @"/var/mobile/Containers/Data/Application/AF944B31-E8CC-49DC-A5D1-E934F6485EBC/Documents";
    currentPath=documentsDirectory;
    [self refreshFiles];
    [self.collectionView reloadData];
    
    
    // TODO: present a view controller appropriate for picker mode here
}
-(void)refreshFiles{
    files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentPath error:nil];
    NSLog(@"%@,%d",currentPath,files.count);
    NSMutableArray *temp=[NSMutableArray arrayWithArray:files];
    for (NSInteger i=0; i<files.count; i++) {
        if ([[temp objectAtIndex:i] isEqualToString:@"Inbox"]&&[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@",currentPath,[files objectAtIndex:i]] error:nil].count==0) {
            [temp removeObjectAtIndex:i];
            break;
        }
    }
    files=[NSArray arrayWithArray:temp];
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return files.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    DPFileCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"file" forIndexPath:indexPath];
    NSString *name=[files objectAtIndex:indexPath.row];
    cell.fileName.text=name;
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",currentPath,name] isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *ext=[self packageExt:[NSString stringWithFormat:@"%@/%@",currentPath,name]];
        if (ext) {
            [cell.iconImage setImage:[UIImage imageNamed:ext]];
        }else{
            [cell.iconImage setImage:[UIImage imageNamed:@"folder"]];
        }
    }else{
        NSInteger index=[name rangeOfString:@"." options:NSBackwardsSearch].location;
        if (index==NSNotFound) {
            [cell.iconImage setImage:[UIImage imageNamed:@"empty"]];
        }else{
            NSString *ext=[[name substringFromIndex:index+1] lowercaseString];
            if ([ext isEqualToString:@"bmp"]) {
                [cell.iconImage setImage:[UIImage imageNamed:@"bmp"]];
            }else if ([ext isEqualToString:@"csv"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"csv"]];
            }else if ([ext isEqualToString:@"gif"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"gif"]];
            }else if ([ext isEqualToString:@"html"]||[ext isEqualToString:@"htm"]||[ext isEqualToString:@"xhtml"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"html"]];
            }else if ([ext isEqualToString:@"jpg"]||[ext isEqualToString:@"jpeg"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"jpg"]];
            }else if ([ext isEqualToString:@"key"]||[ext isEqualToString:@"ppt"]||[ext isEqualToString:@"pptx"]||[ext isEqualToString:@"pps"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"key"]];
            }else if ([ext isEqualToString:@"mov"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"mov"]];
            }else if ([ext isEqualToString:@"mp3"]||[ext isEqualToString:@"m4a"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"mp3"]];
            }else if ([ext isEqualToString:@"mp4"]||[ext isEqualToString:@"mpeg4"]||[ext isEqualToString:@"m4v"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"mp4"]];
            }else if ([ext isEqualToString:@"numbers"]||[ext isEqualToString:@"xls"]||[ext isEqualToString:@"xlsx"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"numbers"]];
            }else if ([ext isEqualToString:@"pages"]||[ext isEqualToString:@"doc"]||[ext isEqualToString:@"docx"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"pages"]];
            }else if ([ext isEqualToString:@"pdf"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"pdf"]];
            }else if ([ext isEqualToString:@"png"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"png"]];
            }else if ([ext isEqualToString:@"rtf"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"rtf"]];
            }else if ([ext isEqualToString:@"tiff"]||[ext isEqualToString:@"tif"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"tiff"]];
            }else if ([ext isEqualToString:@"txt"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"txt"]];
            }else if ([ext isEqualToString:@"zip"]){
                [cell.iconImage setImage:[UIImage imageNamed:@"zip"]];
            }else{
                [cell.iconImage setImage:[UIImage imageNamed:@"empty"]];
            }
        }
    }
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *name=[files objectAtIndex:indexPath.row];
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",currentPath,name] isDirectory:&isDirectory];
    if (isDirectory) {
        currentPath=[currentPath stringByAppendingFormat:@"/%@",name];
        [self refreshFiles];
        [self.collectionView reloadData];
    }else{
        
        // TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
        [self dismissGrantingAccessToURL:[NSURL fileURLWithPath:[currentPath stringByAppendingFormat:@"/%@",name]]];
    }
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

@end
