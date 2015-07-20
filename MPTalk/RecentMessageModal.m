//
//  RecentMessageModal.m
//  MPTalk
//
//  Created by apple on 15/5/9.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import "RecentMessageModal.h"
#import "drrr.h"

@interface RecentMessageModal(){
    NSMutableDictionary *dic;
}
@end
@implementation RecentMessageModal
/*
 字典：
 键：对方名字
 值：{
        发送时间
        没有读得信息数
        信息内容
 }
 */
-(NSArray*)recentMessage
{
    NSMutableArray *marry=[[NSMutableArray alloc]init];
    NSArray *timeArray=[[dic allKeys]sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        return [[[dic objectForKey:obj2] objectForKey:@"date" ] compare:[[dic   objectForKey:obj1] objectForKey:@"date"]];
        
    }];
    for (NSString*name in timeArray) {
        NSDictionary *d=[dic objectForKey:name];
        NSArray *arra=@[name,[d objectForKey:@"date"],[d objectForKey:@"num"],[d objectForKey:@"message"]];
        [marry addObject:arra];
    }
    return marry;
}
+ (RecentMessageModal *)sharedManager
{
    static RecentMessageModal *sharedRecentMessageModalInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedRecentMessageModalInstance = [[self alloc] init];
        [sharedRecentMessageModalInstance setupModal];
    });
    return sharedRecentMessageModalInstance;
}
-(void)setupModal
{
    if (![[[NSUserDefaults standardUserDefaults]objectForKey:@"created_recent_message_plist"]isEqualToString:@"YES"]) {
        [self createPlistToDevice];
    }
      dic= [[NSMutableDictionary alloc] initWithContentsOfFile:[self getLocalPlistName]];
}
-(void)createPlistToDevice
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"recent_message" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    //输入写入
    [data writeToFile:[self getLocalPlistName] atomically:YES];
    [[NSUserDefaults standardUserDefaults]setObject:@"YES" forKey:@"created_recent_message_plist"];
}
-(void)saveMeeage:(NSString*)message WithName:(NSString*)name UnreadMessageTime:(int)num Time:(NSDate*)date isOutgoing:(BOOL)isOutGoing
{
    NSDateFormatter*dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];
    NSString*strDate =[dateFormatter stringFromDate:date];
    
  
    NSDictionary *baseInfo;
    if (isOutGoing) {
        baseInfo=@{@"date":strDate,@"num":[NSNumber numberWithInt:0],@"message":message};
        [dic setObject:baseInfo forKey:name];
    }
    else
    {
        baseInfo=@{@"date":strDate,@"num":[NSNumber numberWithInt:num],@"message":message};
        [dic setObject:baseInfo forKey:name];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:DRRRRefreshMainMessageNotification object:nil];
      [dic writeToFile:[self getLocalPlistName] atomically:YES];
  
}
-(NSString*)getLocalPlistName
{
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *plistPath1 = [paths objectAtIndex:0];
    
    //得到完整的文件名
    NSString *filename=[plistPath1 stringByAppendingPathComponent:@"recent_message.plist"];
    return filename;
}
-(void)clearUnreadMessageNum:(NSString*)jid
{
  NSDictionary*hadReadMessage=  [dic objectForKey:jid];
    if ([hadReadMessage count]!=0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
       [dateFormatter setDateFormat:@"MM-dd HH:mm:ss"];
        
        
        NSDate *destDate= [dateFormatter dateFromString:[hadReadMessage objectForKey:@"date"]];
        [self saveMeeage:[hadReadMessage objectForKey:@"message"] WithName:jid UnreadMessageTime:0 Time:destDate isOutgoing:NO];
    }
    
}
@end
