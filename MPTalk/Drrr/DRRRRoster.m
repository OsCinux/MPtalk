//
//  XMPPRoster.m
//  Test-XMPP
//
//  Created by 秦 道平 on 14-3-27.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "DRRRRoster.h"
#import "DRRRManager.h"
#import "XMPP+DRRR.h"
#import "DRRRRoster.h"
#import "XMPPJID.h"
@interface DRRRRoster()<XMPPRosterDelegate,UIAlertViewDelegate>
@property(nonatomic,strong) XMPPRoster *rosterToEditRosters;
@property(nonatomic,strong)XMPPJID *requestToBeMyFriendJID;
@end
#pragma mark - DRRRRosterMember

@implementation DRRRRosterMember
-(id)initWithPresence:(XMPPPresence *)presence{
    self=[super init];
    if (self){
        if (![presence isChatRoomPresence]){
            XMPPJID* jidFrom=[presence from];
            self.jid=[jidFrom bare];
            self.name=[jidFrom user];
            self.status=[presence status];
            self.show=[presence show];
            self.availableStr=[presence type];
        }
    }
    return self;
}
-(id)initWithRosterElement:(NSXMLElement *)element{
    self=[super init];
    if (self){
        NSString* jid=element.attributesAsDictionary[@"jid"];
        NSString* name=element.attributesAsDictionary[@"name"];
        NSString* subscription=element.attributesAsDictionary[@"subscription"];
        NSString* group=nil;
        if (element.children.count>0){
            NSXMLElement* element_group=element.children[0];
            if ([element_group.name isEqualToString:@"group"]){
                group=element_group.stringValue;
            }
        }
        self.jid=jid;
        self.name=name;
        self.subscription=subscription;
        self.group=group;
    }
    return self;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"<0x%lx %@  jid=%@, name=%@, available=%d, status=%@, show=%@, group=%@, subscription=%@, want_to_subscribe_me=%d>",(unsigned long)self,[self class],self.jid,self.name,self.available,self.status,self.show,self.group,self.subscription,self.want_to_subscribe_me];
}
-(BOOL)available{
    if ([self.availableStr isEqualToString:@"available"]){
        return YES;
    }
    else{
        return NO;
    }
}
@end
#pragma mark - DRRRRoster
@implementation DRRRRoster
static DRRRRoster* _sharedRoster;
+(DRRRRoster*)sharedRoster{
    if (!_sharedRoster){
        _sharedRoster=[[super allocWithZone:NULL]init];
        [_sharedRoster setupRoster];
    }
    return _sharedRoster;
}
-(void)setupRoster{
    _memberList=[[NSMutableDictionary alloc]init];
    
    XMPPRosterCoreDataStorage  *xmppRosterDataStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    _rosterToEditRosters=[[XMPPRoster alloc]initWithRosterStorage:xmppRosterDataStorage dispatchQueue:dispatch_get_main_queue()];
    
     _rosterToEditRosters.autoAcceptKnownPresenceSubscriptionRequests=YES;
    [_rosterToEditRosters addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_rosterToEditRosters activate:[DRRRManager sharedManager].xmppStream];
}
- (NSMutableDictionary *)groupMemberList{
    if (!_groupMemberList) {
        _groupMemberList = [[NSMutableDictionary alloc] init];
     
    }
    return _groupMemberList;
}
#pragma mark - default methods
+(id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedRoster] ;
}
+(id)copyWithZone:(struct _NSZone *)zone{
    return self;
}

#pragma mark - Action
#pragma mark member
-(NSInteger)memberTotal{
    return _memberList.allKeys.count;
}
- (int)numberOfGroups{
    return _groupMemberList.allKeys.count;
}
- (void)memberGroups{
    //清空分组
   
    
    //取到好友列表
    NSArray *allValues = [self.memberList allValues];
    //对好友group属性去重
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (DRRRRosterMember *member in allValues) {
        NSString *string =@"NULL";
        if (!member.group) {
            [array addObject:string];
        }
        else
            [array addObject:member.group];
    }
    NSSet *set = [NSSet setWithArray:array];
    NSArray *arrayFromSet = set.allObjects;
    //创建好友分组
    for (int i = 0; i < set.count ; i ++) {
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        [self.groupMemberList setObject:newArray forKey:arrayFromSet[i]];
    }
//    NSLog(@"===============================");
//    NSLog(@"%@",self.groupMemberList);
    
    //向好友列表中添加好友
    for (DRRRRosterMember *member in allValues) {
        NSString *groupString ;
        if (!member.group) {
            groupString = @"NULL";
        }
        else{
            groupString = member.group;
        }
        NSMutableArray *groupArray = [self.groupMemberList objectForKey:groupString];
        [groupArray addObject:member];
    }
    NSLog(@"===============================");
    NSLog(@"%@",self.groupMemberList);
}
-(DRRRRosterMember*)updateMember:(DRRRRosterMember*)member{
    if (!self.memberList[member.jid]){
        self.memberList[member.jid]=member;
        [[NSNotificationCenter defaultCenter] postNotificationName:DRRRRosterUpdateNotification object:member];
        return member;
    }
    else{
        DRRRRosterMember* updateMember=self.memberList[member.jid];
        if (member.name){
            updateMember.name=member.name;
        }
        if (member.status){
            updateMember.status=member.status;
        }
        if (member.group){
            updateMember.group=member.group;
        }
        if (member.subscription){
            updateMember.subscription=member.subscription;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:DRRRRosterUpdateNotification object:updateMember];
        return updateMember;
    }
}
-(DRRRRosterMember*)memberByJid:(NSString *)jid{
    return self.memberList[jid];
}
-(DRRRRosterMember*)memberAtIndex:(int)index{
    NSString* jid=self.memberList.allKeys[index];
    return [self memberByJid:jid];
    
}
-(DRRRRosterMember*)currentMember{
    return [self memberByJid:[DRRRManager sharedManager].jid];
}
-(void)queryRosterList{
  
    XMPPIQ* iq=[XMPPIQ iqWithType:@"get"];
    [iq addAttributeWithName:@"from" stringValue:self.currentMember.jid];
    [iq addAttributeWithName:@"id" stringValue:@"roster-1"];
    NSXMLElement* element_query=[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    [iq addChild:element_query];
    [[DRRRManager sharedManager].xmppStream sendElement:iq];
}
#pragma mark unread
-(DRRRRosterMember*)_increaseUnreadTotalForJid:(NSString *)jid{
    DRRRRosterMember* member=[self memberByJid:jid];
    member.unread_total++;
    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRRosterUpdateNotification object:member];
    return member;
}
-(DRRRRosterMember*)_clearUnreadTotalForJid:(NSString *)jid{
    DRRRRosterMember* member=[self memberByJid:jid];
    member.unread_total=0;
    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRRosterUpdateNotification object:member];
    return member;
}
#pragma mark status presence
///发送状态
-(void)sendPresenceStatus:(NSString *)status show:(NSString *)show{
    XMPPPresence* presence=[XMPPPresence presence];
    NSXMLElement* element_show=[NSXMLElement elementWithName:@"show" stringValue:show];
    NSXMLElement* element_status=[NSXMLElement elementWithName:@"status" stringValue:status];
    [presence addChild:element_show];
    [presence addChild:element_status];
    [[DRRRManager sharedManager].xmppStream sendElement:presence];
    
}
#pragma mark subscribe
-(void)subscribeToJid:(NSString *)jid name:(NSString *)name group:(NSString *)group{
    if ([jid rangeOfString:@"@"].location==NSNotFound){
        jid=[NSString stringWithFormat:@"%@@%@",jid,[DRRRManager sharedManager].host];
    }
    ///add roster
   /*
    XMPPIQ* iq=[XMPPIQ iqWithType:@"set"];
    [iq addAttributeWithName:@"id" stringValue:@"abc-1"];
    NSXMLElement* elemnt_query=[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    [iq addChild:elemnt_query];
    NSXMLElement* element_item=[NSXMLElement elementWithName:@"item"];
    [element_item addAttributeWithName:@"jid" stringValue:jid];
    [element_item addAttributeWithName:@"name" stringValue:name];
    [elemnt_query addChild:element_item];
    NSXMLElement* element_group=[NSXMLElement elementWithName:@"group" stringValue:group];
    [element_item addChild:element_group];
    [[DRRRManager sharedManager].xmppStream sendElement:iq];
    ///Presence
    XMPPPresence* presence=[[XMPPPresence alloc]initWithType:@"subscribe" to:[XMPPJID jidWithString:jid]];
    [presence addAttributeWithName:@"id" stringValue:@"abc-2"];
    [[DRRRManager sharedManager].xmppStream sendElement:presence];
    */
   // NSArray *groups=@[group];
   //  [_rosterToEditRosters subscribePresenceToUser:[XMPPJID jidWithString:jid]];
      [_rosterToEditRosters addUser:[XMPPJID jidWithString:jid] withNickname:name groups:@[group] subscribeToPresence:YES];
    [self queryRosterList];
    
   
}
-(void)removeRoster:(XMPPJID*)jid
{
    [_rosterToEditRosters removeUser:jid];
}
-(void)unsubscribeJid:(NSString *)jid{
    if ([jid rangeOfString:@"@"].location==NSNotFound){
        jid=[NSString stringWithFormat:@"%@@%@",jid,[DRRRManager sharedManager].host];
    }
   XMPPIQ* iq=[XMPPIQ iqWithType:@"set"];
    [iq addAttributeWithName:@"id" stringValue:@"abc-1"];
    NSXMLElement* elemnt_query=[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    [iq addChild:elemnt_query];
    NSXMLElement* element_item=[NSXMLElement elementWithName:@"item"];
    [element_item addAttributeWithName:@"jid" stringValue:jid];
    [element_item addAttributeWithName:@"subscription" stringValue:@"remove"];
    [elemnt_query addChild:element_item];
    [[DRRRManager sharedManager].xmppStream sendElement:iq];
     [self queryRosterList];
}
-(void)acceptSubscribeFromJid:(NSString *)jid name:(NSString *)name{
    if ([jid rangeOfString:@"@"].location==NSNotFound){
        jid=[NSString stringWithFormat:@"%@@%@",jid,[DRRRManager sharedManager].host];
    }
    DRRRRosterMember* member=[[DRRRRoster sharedRoster] memberByJid:jid];
    member.want_to_subscribe_me=NO;
    ///添加联系人
    XMPPIQ* iq=[XMPPIQ iqWithType:@"set"];
    [iq addAttributeWithName:@"id" stringValue:@"abc-1"];
    NSXMLElement* elemnt_query=[NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    [iq addChild:elemnt_query];
    NSXMLElement* element_item=[NSXMLElement elementWithName:@"item"];
    [element_item addAttributeWithName:@"jid" stringValue:jid];
    [element_item addAttributeWithName:@"name" stringValue:name];
    [elemnt_query addChild:element_item];
    NSXMLElement* element_group=[NSXMLElement elementWithName:@"group" stringValue:@"Friends"];
    [element_item addChild:element_group];
    [[DRRRManager sharedManager].xmppStream sendElement:iq];
    ///发送subscribed
    XMPPPresence* presence=[[XMPPPresence alloc]initWithType:@"subscribed" to:[XMPPJID jidWithString:jid]] ;
    [presence addAttributeWithName:@"from" stringValue:[DRRRManager sharedManager].jid];
    [presence addAttributeWithName:@"id" stringValue:@"abc-2"];
    [[DRRRManager sharedManager].xmppStream sendElement:presence];
    ///发送在线状态
    XMPPPresence* presence2=[[XMPPPresence alloc] init] ;
    [presence2 addAttributeWithName:@"from" stringValue:[DRRRManager sharedManager].jid];
    [presence2 addAttributeWithName:@"to" stringValue:jid];
    [[DRRRManager sharedManager].xmppStream sendElement:presence2];
}

-(void)clearRosterList
{
    [_memberList removeAllObjects];
    [_groupMemberList removeAllObjects];
}

#pragma mark - XMPPStreamDelegate
-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    
}

-(void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{
    ///只处理非chatRoom 状态
    if ([presence isChatRoomPresence]){
        return;
    }
    DRRRRosterMember* member=[[DRRRRosterMember alloc]initWithPresence:presence] ;
    [self updateMember:member];
    
}
-(BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    
    if ([iq isRosterQuery]){
        NSXMLElement* element_query=iq.childElement;
       //
    
        if ([element_query.name isEqualToString:@"query"] && [element_query.xmlns isEqualToString:@"jabber:iq:roster"]){
            for (NSXMLElement* element_item in element_query.children) {
                if([element_item.attributesAsDictionary[@"subscription"]isEqualToString:@"both"]||[element_item.attributesAsDictionary[@"subscription"]isEqualToString:@"to"]||[element_item.attributesAsDictionary[@"subscription"]isEqualToString:@"from"])
                {
                    DRRRRosterMember* member=[[DRRRRosterMember alloc]initWithRosterElement:element_item] ;
                    [self updateMember:member];
                }
               
            }
        }
        [self memberGroups];
   //    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRRosterUpdateNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ALLRosterUpdateNotification object:nil];//用于更新整个联系人列表
    }
    return  YES;
}
//同意请求
-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    _requestToBeMyFriendJID=[presence from];
    NSString *jidStr=_requestToBeMyFriendJID.user;
    NSString *request=[NSString stringWithFormat:@"%@请求成为你的好友",jidStr];
    UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"好友申请" message:request delegate:self cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受", nil];
    [view show];
}
-(void)acceptPresenceSubscriptionRequestFrom:(XMPPJID*)jid
{
    [_rosterToEditRosters acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:NO];
    
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
          [_rosterToEditRosters rejectPresenceSubscriptionRequestFrom:_requestToBeMyFriendJID];
            [_rosterToEditRosters removeUser:_requestToBeMyFriendJID];
    }
    else if (buttonIndex==1){
          [self acceptPresenceSubscriptionRequestFrom:_requestToBeMyFriendJID];
    }
}
@end
