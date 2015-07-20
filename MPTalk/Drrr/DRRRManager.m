//
//  DRRRManager.m
//  TestChat
//
//  Created by 秦 道平 on 14-3-18.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

#import "DRRRManager.h"
#import "DRRRMessage.h"
#import "DRRRRoster.h"
#import "DRRRChatRoomManager.h"
#import "common.h"
#define DRRRManager_Alert_Key_Receive_Subscribe 100 ///接受好友邀请的提醒框
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"


@interface DRRRManager(){
    
}
///正在邀请你关注的好友
@property (nonatomic,copy) NSString* _receiveSubscribeName;
@property(nonatomic,strong) XMPPRoster *rosterToEditRosters;

@end
@implementation DRRRManager
static DRRRManager* _sharedManager;
+(DRRRManager*)sharedManager{
    if (!_sharedManager){
        _sharedManager=[[super allocWithZone:NULL]init];
        [_sharedManager setupXMPP];
    }
    return _sharedManager;
}
-(void)setupXMPP{
    _xmppStream = [[XMPPStream alloc] init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppStream addDelegate:[DRRRMessage sharedMessage] delegateQueue:dispatch_get_main_queue()];
    [_xmppStream addDelegate:[DRRRRoster sharedRoster] delegateQueue:dispatch_get_main_queue()];
    [_xmppStream addDelegate:[DRRRChatRoomManager sharedChatRoomManager] delegateQueue:dispatch_get_main_queue()];
    
    
#if !TARGET_IPHONE_SIMULATOR
    {
        _xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    _xmppReconnect = [[XMPPReconnect alloc] init];
    [_xmppReconnect activate:_xmppStream];
    self.online=NO;
    
    XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    XMPPMessageArchiving *xmppMessageArchivingModule = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:xmppMessageArchivingStorage];
    [xmppMessageArchivingModule setClientSideMessageArchivingOnly:YES];
    [xmppMessageArchivingModule activate:_xmppStream];
    [xmppMessageArchivingModule addDelegate:self delegateQueue:dispatch_get_main_queue()];
  
}
-(XMPPStream*)xmppStream{
    return _xmppStream;
}
#pragma mark - default methods
+(id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedManager] ;
}
+(id)copyWithZone:(struct _NSZone *)zone{
    return self;
}


#pragma mark - action
#pragma connect login and register
-(void)signinWithUsername:(NSString *)username
                 password:(NSString *)password
                     host:(NSString *)host
               isregister:(BOOL)isregister {
    self.username=username;
    self.password=password;
    self.host=host;
    [_xmppStream disconnect];
    /*
     if (![_xmppStream isDisconnected]){
     return;
     }
     */
    _registerAction=isregister;
    //    self.username=@"adow@shintekimacbook-pro.local";
    //    self.password=@"cloudq";
    //    NSString* domain=@"shintekimacbook-pro.local";
    self.jid=[NSString stringWithFormat:@"%@@%@",self.username,self.host];
    [_xmppStream setMyJID:[XMPPJID jidWithString:_jid resource:@"drrr"]];
    [_xmppStream setHostName:host];
    NSError *error = nil;
    BOOL result=[_xmppStream connectWithTimeout:3.0f error:&error];
    NSLog(@"connect:%d,%@",result,error);
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:DRRRManager_StoreKey_Username];
    [[NSUserDefaults standardUserDefaults] setObject:password   forKey:DRRRManager_StoreKey_Password];
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:DRRRManager_StoreKey_Host];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)signout{
    //发送下线状态
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:presence];
    self.online=NO;
    [_xmppStream disconnect];
    [[DRRRRoster sharedRoster].memberList removeAllObjects];
}
-(void)autoSignin{
    NSString* username=[[NSUserDefaults standardUserDefaults] stringForKey:DRRRManager_StoreKey_Username];
    NSString* password=[[NSUserDefaults standardUserDefaults] stringForKey:DRRRManager_StoreKey_Password];
    NSString* host=[[NSUserDefaults standardUserDefaults] stringForKey:DRRRManager_StoreKey_Host];
    [self signinWithUsername:username password:password host:host isregister:NO];
}
-(void)setOnline:(BOOL)online{
    _online=online;
    if (online){
        //发送在线状态
        [[NSNotificationCenter defaultCenter] postNotificationName:DRRRManager_Online_Notification object:[NSNumber numberWithBool:YES]];
        NSLog(@"online");
    }
    else{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DRRRManager_Online_Notification object:[NSNumber numberWithBool:NO]];
    }
}
-(BOOL)online{
    return _online;
}
#pragma mark message
-(void)sendXmlString:(NSString *)xmlString{
    NSXMLElement* element=[[NSXMLElement alloc]initWithXMLString:xmlString error:nil];
    [self.xmppStream sendElement:element];
}
#pragma mark subscribe
#pragma mark - xmpp delegate
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    //验证密码
    NSError* error=nil;
    BOOL result;
    if (!_registerAction){
        result=[_xmppStream authenticateWithPassword:self.password error:&error];
    }
    else{
        result=[_xmppStream registerWithPassword:self.password error:&error];
    }
    ///注册只要一次，之后就改为登录，防止在重复连接的时候又去注册
    _registerAction=NO;
    NSLog(@"authenticated:%d,%@",result,error);
}
-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DRRRMANAGER_AUTHENTICATE object:@[[NSNumber numberWithBool:NO],error.localizedDescription]];}
    }    
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    //发送在线状态
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
    NSLog(@"xmppStreamDidAuthenticate");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRMANAGER_AUTHENTICATE object:@[[NSNumber numberWithBool:YES]]];
    NSLog(@"online");
}
-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRManager_Signin_Notification object:[NSNumber numberWithBool:NO]];
    self.online=NO;
    NSLog(@"---------didNotAuthenticate error %@---------",error.children[0]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRMANAGER_AUTHENTICATE object:@[[NSNumber numberWithBool:NO],[NSString stringWithFormat:@"%@",error.children[0]]]];
}
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    NSLog(@"register");
    NSError* error=nil;
    [_xmppStream authenticateWithPassword:self.password error:&error];
}
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error{
    NSLog(@"not register");
}
-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    ///message 全部由 DRRRMessage处理
}
-(void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{
    //    NSLog(@"presence = %@", presence);
    ///只处理如果是当前用户的状态，其他有DRRRRoster, DRRRChatRoom处理
    XMPPJID* jidFrom=[presence from];
    XMPPJID* jidTo=[presence to];
    NSString *presenceFromUser = [jidFrom user];
    NSString* presenceFromJid=[jidFrom bare];
    //取得好友状态
    NSString *presenceType = [presence type]; //online/offline
    //当前用户是否在线
    NSString *userId = [[sender myJID] user];
    if ([presenceFromUser isEqualToString:userId]){
        if ([presenceType isEqualToString:@"available"]){
            self.online=YES;
        }
        else if ([presenceType isEqualToString:@"unavailable"]){
            self.online=NO;
        }
        
    }/*
    else
    {
        if ([presenceType isEqualToString:@"subscribed"]) {
            XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@",[presence from]]];
            [[DRRRRoster sharedRoster] acceptPresenceSubscriptionRequestFrom:jid];
        }
    }*/
    
}
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    ///由 DRRRRoster处理
    return YES;
}
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    NSLog(@"hehe");
}

@end
