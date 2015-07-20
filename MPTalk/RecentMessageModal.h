//
//  RecentMessageModal.h
//  MPTalk
//
//  Created by apple on 15/5/9.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecentMessageModal : NSObject
-(NSArray*)recentMessage;
+ (RecentMessageModal *)sharedManager;
-(void)saveMeeage:(NSString*)message WithName:(NSString*)name UnreadMessageTime:(int)num Time:(NSDate*)date isOutgoing:(BOOL)isOutGoing;
-(void)clearUnreadMessageNum:(NSString*)name;
@end
