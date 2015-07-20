//
//  SetTableViewController.m
//  MPTalk
//
//  Created by jackman on 15/5/6.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import "SetTableViewController.h"
#import "HPWelcomeViewController.h"
#import "drrr.h"
#define RosterStatusViewController_Cell_Identity @"status-cell"


@interface SetTableViewController ()
@property (nonatomic,strong) NSIndexPath* currentIndexPath;
@property (nonatomic,retain) UITextField* statusText;

@end

@implementation SetTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView=[[UIView alloc] init];
    NSString *show=[DRRRRoster sharedRoster].currentMember.show;//获取当前登陆用户的状态
    if ([show isEqualToString:DRRRRosterMemberPresenceShowChat]){
        self.currentIndexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    }
    else if ([show isEqualToString:DRRRRosterMemberPresenceShowAway]){
        self.currentIndexPath=[NSIndexPath indexPathForRow:1 inSection:0];
    }
    else if ([show isEqualToString:DRRRRosterMemberPresenceShowDnd]){
        self.currentIndexPath=[NSIndexPath indexPathForRow:2 inSection:0];
    }
    //    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:RosterStatusViewController_Cell_Identity];
    //    self.tableView.allowsMultipleSelection=NO;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.frame=CGRectMake(0, 44, self.tableView.frame.size.width, self.tableView.frame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0){
        return 1;
        
    }
    else if (section==1){
        return 1;
    }
    else if (section==2){
        return 3;
    }
    else if (section==3){
        return 1;
    }else{
        return 2;
    }
    
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section==0) {
        return @"  ";
    }
    else if (section==1){
        return @"用户名";
    }
    else if (section==2){
        return @"显示";
        
    }
    else if (section==3){
        return @"状态";
    }
    else{
        return @"操作";
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RosterStatusViewController_Cell_Identity];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RosterStatusViewController_Cell_Identity];
    }
    
    // Configure the cell...
    if (indexPath.section==1){
        cell.textLabel.text=[DRRRManager sharedManager].username;
    }
    if (indexPath.section==2){
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text=@"空闲";
                break;
            case 1:
                cell.textLabel.text=@"隐身";
                break;
            case 2:
                cell.textLabel.text=@"请勿打扰";
                break;
            default:
                break;
        }
        if (indexPath.section==self.currentIndexPath.section && indexPath.row==self.currentIndexPath.row){
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
        }
        else{
            cell.accessoryType=UITableViewCellAccessoryNone;
        }
    }
    else if (indexPath.section==3){
        cell.accessoryType=UITableViewCellAccessoryNone;
        for (UIView* view  in cell.contentView.subviews) {
            if ([view isKindOfClass:[UITextField class]]){
                [view removeFromSuperview];
            }
        }
        if (!_statusText){
            _statusText=[[UITextField alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 40.0f)];
            _statusText.placeholder=@"   在线";
           // NSLog(@"1111%@",[DRRRRoster sharedRoster].currentMember.show);
            if ([DRRRRoster sharedRoster].currentMember.show){
                _statusText.text=[DRRRRoster sharedRoster].currentMember.status;
                NSLog(@"%@",[DRRRRoster sharedRoster].currentMember.status);
            }
            [_statusText addTarget:self action:@selector(onTextEndEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
        }
        [cell.contentView addSubview:_statusText];
    }
    else if (indexPath.section==4){
        if (indexPath.row==1){
            cell.backgroundColor=[UIColor colorWithRed:135.0f/255.0f green:206.0f/255.0f blue:250.0f/255.0f alpha:1];
            cell.textLabel.textColor=[UIColor whiteColor];
            cell.textLabel.text=@"退出登录";
        }
    }
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==2){
        self.currentIndexPath=indexPath;
        [self.tableView reloadData];
        NSString* show=@"";
        switch (indexPath.row) {
            case 0:
                show=DRRRRosterMemberPresenceShowChat;
                _statusText.text=@"    空闲";
                break;
            case 1:
                show=DRRRRosterMemberPresenceShowAway;
                _statusText.text=@"   隐身";
                break;
            case 2:
                show=DRRRRosterMemberPresenceShowDnd;
                _statusText.text=@"   请勿打扰";
                break;
            default:
                break;
        }
        NSString* status=self.statusText.text;
        [[DRRRRoster sharedRoster] sendPresenceStatus:status show:show];
        
    }
    else if (indexPath.section==4){
        if(indexPath.row==1){
            [[DRRRManager sharedManager] signout];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"backtodenglu" object:self];
            //             [self dismissViewControllerAnimated:YES completion:^{
            //
            //             }];
        }
    }
}

-(IBAction)onTextEndEditing:(id)sender{
    NSString* show=@"";
    switch (_currentIndexPath.row) {
        case 0:
            show=DRRRRosterMemberPresenceShowChat;
            break;
        case 1:
            show=DRRRRosterMemberPresenceShowAway;
            break;
        case 2:
            show=DRRRRosterMemberPresenceShowDnd;
            break;
        default:
            break;
    }
    NSString* status=self.statusText.text;
    [[DRRRRoster sharedRoster] sendPresenceStatus:status show:show];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
