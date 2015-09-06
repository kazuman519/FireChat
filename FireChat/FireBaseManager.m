//
//  FireBaseManager.m
//  FireChat
//
//  Created by 三浦　和真 on 2015/09/06.
//  Copyright (c) 2015年 三浦　和真. All rights reserved.
//

#import "FireBaseManager.h"
#import <Firebase/Firebase.h>

static NSString * const kFbRootUrl = @"https://kumasandeat.firebaseio.com/";
static NSString * const kFbUserListUrl = @"https://kumasandeat.firebaseio.com/user_list/";
static NSString * const kFbRoomListUrl = @"https://kumasandeat.firebaseio.com/room_list/";
static NSString * const kFbMessageListUrl = @"https://kumasandeat.firebaseio.com/message_list/";


@implementation FireBaseManager
{
    __block Firebase *_fbRoot;
    __block Firebase *_fbUserListManager;
    __block Firebase *_fbRoomListManager;
    __block Firebase *_fbMessageListManager;
    
    NSString *_fbUserId;
    NSString *_fbBotId;
}

- (id)initWithId:(NSString *)userId
             bot:(NSString *)botId
        observer:(NSString *)setObserver
        callback:(SEL)callback
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:setObserver selector:callback name:@"kCreateRoom" object:nil];
    
    _fbUserId = userId;
    _fbBotId = botId;
    
    return self;
}

-(void)initFb
{
    _fbRoot = [[Firebase alloc] initWithUrl:kFbRootUrl];
    _fbUserListManager = [[Firebase alloc] initWithUrl:kFbUserListUrl];
    _fbRoomListManager = [[Firebase alloc] initWithUrl:kFbRoomListUrl];
}

-(void)requestEventFromRoot
{
    [_fbRoot observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        // 子要素なし判定
        if( snapshot.childrenCount == 0 ) {
            // 子要素の初期設定
            NSLog(@"%s",__func__);
            
            //room id
            NSString *roomID = [NSUUID UUID].UUIDString;
            
            //room list
            NSDictionary *roomList = @{
                                       roomID :   @{
                                               @"room_name" : @"mugi_room",
                                               @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                               }
                                       };
            
            //user list
            NSDictionary *userList = @{
                                       _fbUserId :   @{
                                               @"room_name" : @"mugicha",
                                               @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                               },
                                       _fbBotId :   @{
                                               @"room_name" : @"bot",
                                               @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                               }
                                       };
            
            // RoomID永続化
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            [userDef setObject:roomID forKey:@"kChatRoomId"];
            [userDef synchronize];
            
            // 初期データ設定
            [[_fbRoot childByAppendingPath:@"room_list"] setValue:roomList];
            [[_fbRoot childByAppendingPath:@"user_list"] setValue:userList];
            
            // message list用URL
            NSString *messageURL = [NSString stringWithFormat:@"%@%@/", kFbRoomListUrl, roomID];
            _fbMessageListManager = [[Firebase alloc] initWithUrl:messageURL];
            
        }
        else {
            // 永続化した情報の読み出し
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            NSString *roomIdFromUserDef = [userDef stringForKey:@"kChatRoomId"];
            
            // message list用URL
            NSString *messageURL = [NSString stringWithFormat:@"%@%@/",kFbMessageListUrl, roomIdFromUserDef];
            _fbMessageListManager = [[Firebase alloc] initWithUrl:messageURL];
        }
        
        // post
        [NSNotification notificationWithName:@"kQueryMessage" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kCreateRoom"
                                                            object:self
                                                          userInfo:nil];
    }];
}

@end
