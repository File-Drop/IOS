//
//  DocumentPickerViewController.h
//  DP
//
//  Created by XiongDian on 14/10/9.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocumentPickerViewController : UIDocumentPickerExtensionViewController<UICollectionViewDataSource,UICollectionViewDelegate>{
    NSArray *files;
    NSString *currentPath;
}
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
