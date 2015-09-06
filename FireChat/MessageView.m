//
//  MessageView.m
//  FireChat
//
//  Created by 三浦　和真 on 2015/09/06.
//  Copyright (c) 2015年 三浦　和真. All rights reserved.
//

#import "MessageView.h"
#import <JSQMessagesViewController/JSQMessages.h>
#import "FireBaseManager.h"

@implementation MessageView
{
    NSMutableArray *_messageList;
    
    NSString *_botID;
    NSString *_userID;
    
    JSQMessagesBubbleImage *_incomingBubble;
    JSQMessagesBubbleImage *_outgoingBubble;
    JSQMessagesAvatarImage *_incomingAvatar;
    JSQMessagesAvatarImage *_outgoingAvatar;
    
    FireBaseManager *_fbMng;
}

-(void)initUser {
    
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // firebaseに登録するユーザ情報とローカルの情報を一致させるため
    // 先にIDの生成と永続化(とその読み出し)を行う
    
    // ID読み出し
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    
    _botID = [userDef stringForKey:@"kMessageViewBotID"];
    _userID = [userDef stringForKey:@"kMessageViewUserID"];
    
    // 未生成判定
    if(( nil == _botID ) || ( nil == _userID )){
        
        // ID生成
        _botID = [NSUUID UUID].UUIDString;
        _userID = [NSUUID UUID].UUIDString;
        [userDef setObject:_botID forKey:kMessageViewBotID];
        [userDef setObject:_userID forKey:kMessageViewUserID];
        [userDef synchronize];
    }
    
    // user設定 : senderID(firebase上のuser_hashを利用)
    self.senderId = _userID;
    // user設定 : 画面上の名前
    self.senderDisplayName = @"mugicha";
    
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
    
    _messageList = [NSMutableArray array];
}

@end
