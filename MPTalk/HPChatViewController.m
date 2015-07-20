//
//  HPChatViewController.m
//  MPTalk
//
//  Created by apple on 15/5/4.
//  Copyright (c) 2015年 2012110401. All rights reserved.
//
/*--------------------
 
 XMPPMessageArchiving_Message_CoreDataObject中返回的格式
 data: {
 bareJid = "(...not nil..)";
 bareJidStr = "对方账号";
 body = "这里由服务器自定义";
 composing = 0;
 message = "(...not nil..)";
 messageStr = "<message type=\"chat\" to=\"用户名"><body>[1](\U54c8\U54c8)(\U563b\U563b)(\U5475\U5475)</body></message>";
 outgoing = 1;
 streamBareJidStr = "自己账号";
 thread = nil;
 timestamp = "2014-11-24 07:50:26 +0000";
 })
 
 
 
 
 
 ---------------------*/
#import "HPChatViewController.h"
#import "AppDelegate.h"
#import "JSQMessages.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import <CoreData/CoreData.h>
#import "RecentMessageModal.h"
#define		COLOR_OUTGOING						HEXCOLOR(0x007AFFFF)
#define		COLOR_INCOMING						HEXCOLOR(0xE6E5EAFF)


#import "AGEmojiKeyBoardView.h"
@interface HPChatViewController()<AGEmojiKeyboardViewDataSource,AGEmojiKeyboardViewDelegate>
{
    JSQMessagesBubbleImage *bubbleImageOutgoing;
    JSQMessagesBubbleImage *bubbleImageIncoming;
    NSMutableArray *messages;
    BOOL loadHistoryMessage;
     AGEmojiKeyboardView *emotionView;
}
@end
@implementation HPChatViewController
-(void)viewDidLoad
{
    [super viewDidLoad];
    //  self.automaticallyAdjustsScrollViewInsets=YES;
    self.automaticallyScrollsToMostRecentMessage=YES;
    self.senderId=[DRRRManager sharedManager].jid;
    self.senderDisplayName=[DRRRManager sharedManager].username;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTalkNotification:) name:DRRRRefreshTalksNotification object:nil];
    
    
   // self.inputToolbar.contentView.leftBarButtonItem=nil;
    
    messages=[[NSMutableArray alloc]init];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    bubbleImageOutgoing = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithRed:175.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0]];
    bubbleImageIncoming = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor colorWithRed:255.0f/255.0f green:218.0f/255.0f blue:185.0f/255.0f alpha:1.0]];
    
    
    UIButton *button=[[UIButton alloc]initWithFrame:CGRectMake(235, 6, 32, 32)];
    [button setBackgroundImage:[UIImage imageNamed:@"emtion"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showEmotion) forControlEvents:UIControlEventTouchDown];
    [self.inputToolbar.contentView addSubview:button];
    emotionView=[[AGEmojiKeyboardView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 216)dataSource:self];
    emotionView.delegate=self;
    emotionView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    [[RecentMessageModal sharedManager]clearUnreadMessageNum:self.member.jid];
}
-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    if (self.member){
        [[DRRRMessage sharedMessage] sendMessage:text toJid:self.member.jid toName:self.member.name];
        RecentMessageModal *modal=[RecentMessageModal sharedManager];
        [modal saveMeeage:text WithName:self.member.jid UnreadMessageTime:0 Time:date isOutgoing:YES];

    }
    
    [self finishSendingMessageAnimated:YES];
    //  [self finishSendingMessage];
}
-(void)refreshTalkNotification:(NSNotification*)notification{
    
    [self reloadTable];
}
-(void)reloadTable
{
    if (self.member){
        
        NSArray *messageLIst=[[DRRRMessage sharedMessage] talksWithJid:self.member.jid];
        if (!messageLIst) {
            [self.collectionView reloadData];
            return ;
        }
        if (!messages) {
            for (DRRRMessageContent *content in messageLIst) {
                JSQMessage *message=[[JSQMessage alloc]initWithSenderId:content.fromJid senderDisplayName:content.fromName date:content.time text:content.body];
                [messages addObject:message];
            }
            
        }
        else
        {
            DRRRMessageContent *lastContent=[messageLIst lastObject];
            
            //读取离线消息，不重复添加最后一个
            if (loadHistoryMessage) {
                [self.collectionView reloadData];
                return;
            }
            JSQMessage *message=[[JSQMessage alloc]initWithSenderId:lastContent.fromJid senderDisplayName:lastContent.fromName date:lastContent.time text:lastContent.body];
            [messages addObject:message];
        }
    }
    [self.collectionView reloadData];
}
-(void)viewDidAppear:(BOOL)animated
{
    loadHistoryMessage=YES;
    [super viewDidAppear:YES];
    [[DRRRRoster sharedRoster] _clearUnreadTotalForJid:self.member.jid];
    [self loadHistoryMessage];
    [self reloadTable];
    loadHistoryMessage=NO;
}
-(void)loadHistoryMessage{
    XMPPMessageArchivingCoreDataStorage *storage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSManagedObjectContext *moc = [storage mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject"
                                                         inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    request.predicate = [NSPredicate predicateWithFormat:@"(bareJidStr = %@ AND streamBareJidStr= %@) OR  (bareJidStr = %@ AND streamBareJidStr =%@)", self.senderId,self.member.jid,self.member.jid,self.senderId];
    NSError *error;
    NSArray *messag = [moc executeFetchRequest:request error:&error];
    
    for (XMPPMessageArchiving_Message_CoreDataObject *message in messag) {
        NSString *sId=[message isOutgoing]?self.senderId:message.bareJidStr;
        NSString *sName=[message isOutgoing]?self.senderDisplayName:message.bareJid.user;
        //  JSQMessage *jsmessage=[[JSQMessage alloc]initWithSenderId:message.streamBareJidStr senderDisplayName:streamBareJid.user date:message.timestamp text:message.body];
        JSQMessage *jsmessage=[[JSQMessage alloc]initWithSenderId:sId   senderDisplayName:sName date:message.timestamp text:message.body];
        
        [messages addObject:jsmessage];
    }
    
}


#pragma mark - JSQMessages CollectionView DataSource


-(id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return messages[indexPath.row];
}
-(id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([((JSQMessage*)messages[indexPath.row]).senderId isEqualToString:self.senderId]) {
        return bubbleImageOutgoing;
    }
    else
        return bubbleImageIncoming;
}

-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesAvatarImage *avatarImageBlank;
    avatarImageBlank = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"chat_blank"] diameter:30.0];
    
    return avatarImageBlank;
}
#pragma mark - UICollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    return [messages count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    if ([((JSQMessage*)messages[indexPath.item]).senderId isEqualToString:self.senderId])
    {
        cell.textView.textColor = [UIColor whiteColor];
    }
    else
    {
        cell.textView.textColor = [UIColor blackColor];
    }
    return cell;
}


- (UIImage *)emojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView imageForSelectedCategory:(AGEmojiKeyboardViewCategoryImage)category {
    UIImage *img = [self imageFromText:@"a"];
    [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    return img;
}

- (UIImage *)emojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView imageForNonSelectedCategory:(AGEmojiKeyboardViewCategoryImage)category {
    UIImage *img = [self imageFromText:@"表情"];
    [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    return img;
}

- (UIImage *)backSpaceButtonImageForEmojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView {
    UIImage *img =[self imageFromText:@"删除"];
    [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    return img ;
}
-(UIImage *)imageFromText:(NSString *)text
{
    UIFont *font = [UIFont systemFontOfSize:20.0];
    CGSize size = [text sizeWithAttributes:
                   @{NSFontAttributeName:
                         [UIFont systemFontOfSize:20.0f]}];
    
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    
    
    [text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
-(void)emojiKeyBoardView:(AGEmojiKeyboardView *)emojiKeyBoardView didUseEmoji:(NSString *)emoji
{
    self.inputToolbar.contentView.textView.text=[self.inputToolbar.contentView.textView.text stringByAppendingString:emoji];
    [self.inputToolbar toggleSendButtonEnabled];
}

-(void)emojiKeyBoardViewDidPressBackSpace:(AGEmojiKeyboardView *)emojiKeyBoardView
{
    if ([self.inputToolbar.contentView.textView.text length]!=0) {
      //  NSUInteger location=self.inputToolbar.contentView.textView.selectedRange.location ;
    }
}

-(void)showEmotion
{
    if (! self.inputToolbar.contentView.textView.inputView) {
        [self.inputToolbar.contentView.textView resignFirstResponder];
        self.inputToolbar.contentView.textView.inputView=emotionView;
        [self.inputToolbar.contentView.textView becomeFirstResponder];
        
    }
    else{
        self.inputToolbar.contentView.textView.inputView=nil;
        [self.inputToolbar.contentView.textView resignFirstResponder];
    }
}
@end
