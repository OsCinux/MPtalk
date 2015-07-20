//
//  AddRosterViewController.h
//  MPTalk
//
//  Created by jackman on 15/5/7.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddRosterViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *TextFiledMpID;
@property (strong, nonatomic) IBOutlet UITextField *TextFiledName;
@property (strong, nonatomic) IBOutlet UILabel *MpIDNotBlank;
@property (strong, nonatomic) IBOutlet UILabel *BeiZhuNotBlank;
@property (strong, nonatomic) IBOutlet UITextField *TextFiledGrup;

@end
