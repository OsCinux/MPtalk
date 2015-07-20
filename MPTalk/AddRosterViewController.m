//
//  AddRosterViewController.m
//  MPTalk
//
//  Created by jackman on 15/5/7.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import "AddRosterViewController.h"
#import "drrr.h"

@interface AddRosterViewController ()

@end

@implementation AddRosterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.MpIDNotBlank.hidden=YES;
    self.BeiZhuNotBlank.hidden=YES;
    // Do any additional setup after loading the view.
    
    XMPPRosterCoreDataStorage  *xmppRosterDataStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    
    //    _xmppRoster.autoFetchRoster = YES;
    //    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
   }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)BtnFinishAdd:(UIButton *)sender {
    NSString *jid=self.TextFiledMpID.text;
    NSString *jidString=[NSString stringWithFormat:@"%@@104.236.174.238",jid];
    NSString *name=self.TextFiledName.text;
    NSString *groupname=self.TextFiledGrup.text;
    self.MpIDNotBlank.hidden=YES;
    self.BeiZhuNotBlank.hidden=YES;
    if ([jid isEqualToString:@""]) {
        self.MpIDNotBlank.hidden=NO;
    }
    else if ([name isEqualToString:@""]) {
        self.BeiZhuNotBlank.hidden=NO;
    }
    else{
        
        [[DRRRRoster sharedRoster] subscribeToJid:jid name:name group:groupname];
      
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }

}
- (IBAction)BtnCancle:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
