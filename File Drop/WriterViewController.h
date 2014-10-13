//
//  WriterViewController.h
//  File Drop
//
//  Created by 熊典 on 14-2-6.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WriterViewController : UIViewController<UITextViewDelegate,UIActionSheetDelegate>{
    NSString *rootPath;
}
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property NSString* rootPath;
@end
