//
//  HPPeopleViewController.m
//  MPTalk
//
//  Created by apple on 15/5/3.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import "HPPeopleViewController.h"
#import "DRRRRoster.h"
#import "HPChatViewController.h"
@interface HPPeopleViewController()<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    
    __weak IBOutlet UITableView *ContactListTableView;
    NSInteger memberIndexSection;
    NSInteger memberIndexRow;
}
@end
@implementation HPPeopleViewController
-(void)viewDidLoad
{
    [super viewDidLoad];
    ContactListTableView.delegate=self;
    ContactListTableView.dataSource=self;
    [[DRRRRoster sharedRoster] queryRosterList];
}
-(void)viewDidDisappear:(BOOL)animated
{
    //  [self removeObserver:self forKeyPath:DRRRMANAGER_AUTHENTICATE];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALLRosterUpdateNotification object:nil];
}
-(void)viewDidAppear:(BOOL)animated
{
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRosterNotification:) name:ALLRosterUpdateNotification object:nil];
    
}

        // Custom initialization


#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSInteger numberOfGroup = [DRRRRoster sharedRoster].numberOfGroups;
    return numberOfGroup;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger total = [[[DRRRRoster sharedRoster].groupMemberList objectForKey:[DRRRRoster sharedRoster].groupMemberList.allKeys[section]] count];
    return total;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *string = [DRRRRoster sharedRoster].groupMemberList.allKeys[section];
    if ([string isEqualToString:@"NULL"]) {
        return @"默认分组";
    }else{
        return string;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DRRRRosterMember *roster=[[DRRRRoster sharedRoster].groupMemberList objectForKey:[DRRRRoster sharedRoster].groupMemberList.allKeys[indexPath.section]][indexPath.row];
    static NSString* contactCellIdentifer=@"contact";
    UITableViewCell *cell=[ContactListTableView dequeueReusableCellWithIdentifier:contactCellIdentifer];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:contactCellIdentifer];
    }
    if (roster.name.length==0) {
        cell.textLabel.text=[XMPPJID jidWithString:roster.jid].user;
    }
    else
    cell.textLabel.text=roster.name;
            if ([roster.name isEqualToString:[DRRRManager sharedManager].username]) {
                cell.textLabel.text=@"我自己";
            }
    return cell;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
               DRRRRosterMember *roster=[[DRRRRoster sharedRoster].groupMemberList objectForKey:[DRRRRoster sharedRoster].groupMemberList.allKeys[indexPath.section]][indexPath.row];
        [[DRRRRoster sharedRoster] unsubscribeJid:roster.jid];
          }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    memberIndexSection = indexPath.section;
    memberIndexRow=indexPath.row;
    [self performSegueWithIdentifier:@"chat_segue" sender:self];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"chat_segue"]) {
       
        DRRRRosterMember *member = [[DRRRRoster sharedRoster].groupMemberList objectForKey:[DRRRRoster sharedRoster].groupMemberList.allKeys[memberIndexSection]][memberIndexRow];
        HPChatViewController *vc=segue.destinationViewController;
        vc.member=member;
       
    }

}

-(void)updateRosterNotification:(NSNotification*)notification{
  
    [ContactListTableView reloadData];
}
//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    if (section==0) {
//        return @"好友";
//    }
//    else
//    {
//        return @"群组";
//    }
//}
@end
