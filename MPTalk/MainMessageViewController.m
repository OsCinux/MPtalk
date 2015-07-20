//
//  MainMessageViewController.m
//  AGEmojiKeyboardSample
//
//  Created by apple on 15/5/9.
//  Copyright (c) 2015年 Ayush. All rights reserved.
//

#import "MainMessageViewController.h"
#import  <CoreData/CoreData.h>
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "DRRRManager.h"
#import "RecentMessageModal.h"
#import "DRRRRoster.h"
#import "HPChatViewController.h"
#import "DRRRManager.h"
@interface MainMessageViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSArray *messageArray;
    DRRRRosterMember *member;
    __weak IBOutlet UITableView *messageTableView;
}
@end

@implementation MainMessageViewController
-(void)viewDidAppear:(BOOL)animated
{
    messageTableView.tableFooterView=[[UIView alloc] init];
    messageArray =[[RecentMessageModal sharedManager]recentMessage];
    
    [messageTableView reloadData];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMainMessageNotification) name:DRRRRefreshMainMessageNotification object:nil];
}
-(void)refreshMainMessageNotification
{
    messageArray =[[RecentMessageModal sharedManager]recentMessage];
    [messageTableView reloadData];
}
-(void)viewDidDisappear:(BOOL)animated
{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:DRRRRefreshMainMessageNotification object:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    messageTableView.delegate=self;
    messageTableView.dataSource=self;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messageArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* contactCellIdentifer=@"contact";
    UITableViewCell *cell=[messageTableView dequeueReusableCellWithIdentifier:contactCellIdentifer];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:contactCellIdentifer];
    }
    NSArray *messageA=[messageArray objectAtIndex:indexPath.row];
   // XMPPJID *jid=[XMPPJID jidWithString:[messageA objectAtIndex:0]];
    DRRRRosterMember *member1=[[DRRRRoster sharedRoster] memberByJid:[messageA objectAtIndex:0]];
    cell.textLabel.text=member1.name;
    cell.detailTextLabel.text=[messageA objectAtIndex:3];
    NSLog(@"%@",[messageA objectAtIndex:1]);
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *memberJid=([(NSArray*)[messageArray objectAtIndex:indexPath.row]objectAtIndex:0]);
    member=[[DRRRRoster sharedRoster]memberByJid:memberJid];
     [self performSegueWithIdentifier:@"mainmessage_chat" sender:self];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"mainmessage_chat"]) {
        
       
        HPChatViewController *vc=segue.destinationViewController;
        vc.member=member;
        
    }
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
