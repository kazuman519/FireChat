//
//  ChatViewController.m
//  FireChat
//
//  Created by 三浦　和真 on 2015/09/06.
//  Copyright (c) 2015年 三浦　和真. All rights reserved.
//

#import "ChatViewController.h"
#import "ChatManager.h"

static NSString * const kMessageViewUserId = @"userId";
static NSString * const kMessageViewBotId = @"botId";

@interface ChatViewController ()

@property (strong, nonatomic) NSMutableArray *messageArray;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubble;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubble;
@property (strong, nonatomic) JSQMessagesAvatarImage *incomingAvatar;
@property (strong, nonatomic) JSQMessagesAvatarImage *outgoingAvatar;
@property (strong, nonatomic) ChatManager *chatManager;
@property (strong, nonatomic) NSString *botId;
@property (strong, nonatomic) NSString *userId;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initUser];
    
    // firebase manager初期化
    self.chatManager = [[ChatManager alloc] initWithId:self.userId bot:self.botId observer:self callback:@selector(reqMessage)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initUser {
    
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // firebaseに登録するユーザ情報とローカルの情報を一致させるため
    // 先にIDの生成と永続化(とその読み出し)を行う
    
    // ID読み出し
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    self.botId = [userDef stringForKey:kMessageViewBotId];
    self.userId = [userDef stringForKey:kMessageViewUserId];
    
    // 未生成判定
    if(( nil == self.botId ) || ( nil == self.userId )){
        
        // ID生成
        self.botId = [NSUUID UUID].UUIDString;
        self.userId = [NSUUID UUID].UUIDString;
        [userDef setObject:self.botId forKey:kMessageViewBotId];
        [userDef setObject:self.userId forKey:kMessageViewUserId];
        [userDef synchronize];
    }
    
    
    // user設定 : senderID(firebase上のuser_hashを利用)
    self.senderId = self.userId;
    // user設定 : 画面上の名前
    self.senderDisplayName = @"user1";
    
    // 吹き出し
    JSQMessagesBubbleImageFactory *bubbleFactory = [JSQMessagesBubbleImageFactory new];
    // 吹き出し設定 : 受信
    _incomingBubble = [bubbleFactory  incomingMessagesBubbleImageWithColor:[UIColor lightGrayColor]];
    // 吹き出し設定 : 送信
    _outgoingBubble = [bubbleFactory  outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    
    // アイコン設定 : 受信
    _incomingAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"ava_bot.png"] diameter:64];
    // アイコン設定 : 送信
    _outgoingAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"ava_mugicha.png"] diameter:64];
    
    self.messageArray = [NSMutableArray array];
}


#pragma mark - JSQMessagesViewController

// ⑤ Sendボタンが押下されたときに呼ばれる
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
//    [self addMessage:text senderId:senderId senderDisplayName:senderDisplayName date:date];
    [self.chatManager sendMessage:text];
}


#pragma mark - JSQMessagesCollectionViewDataSource

// アイテムごとに参照するメッセージデータを返す
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messageArray objectAtIndex:indexPath.item];
}

// アイテムごとの MessageBubble (背景) を返す
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messageArray objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubble;
    }
    return self.incomingBubble;
}

// アイテムごとのアバター画像を返す
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messageArray objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingAvatar;
    }
    return self.incomingAvatar;
}

#pragma mark - UICollectionViewDataSource

// アイテムの総数を返す
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.messageArray.count;
}


#pragma mark - Auto Message

// 返信メッセージを受信する (自動)
- (void)receiveAutoMessage
{
    // 1秒後にメッセージを受信する
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(didFinishMessageTimer:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)didFinishMessageTimer:(NSTimer*)timer
{
    [self addMessage:@"Hello"
            senderId:@"user2"
   senderDisplayName:@"underscore"
                date:nil];
}

-(void)addMessage:(NSString *)text
         senderId:(NSString *)senderId
senderDisplayName:(NSString *)senderDisplayName
             date:(NSDate *)date
{
    // 送信サウンド
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // メッセージオブジェクト生成(id + name + 日付 + テキスト)
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    [self.messageArray addObject:message];
    
    // 送信
    [self finishSendingMessageAnimated:YES];
}

-(void)reqMessage
{
    // メッセージ情報をQuery
    [self.chatManager requestMessageQuery:@selector(resultQuery:) observer:self];
}

-(void)resultQuery:(NSNotification*)userInfo
{
    NSLog(@"kita---------");
    FDataSnapshot *snapshot = (FDataSnapshot*)userInfo.userInfo;
    NSDictionary *dictionary = [snapshot value];
    
    NSLog(@"fa-----------> %@", [dictionary objectForKey:@"message"]);
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:[dictionary valueForKey:@"user_id"]
                                             senderDisplayName:@"hoge"
                                                          date:[NSDate dateWithTimeIntervalSince1970:[[dictionary valueForKey:@"time_stamp"] intValue]]
                                                          text:[dictionary objectForKey:@"message"]];
    [self.messageArray addObject:message];
    
    // 送信
    [self finishSendingMessageAnimated:YES];
}
@end
