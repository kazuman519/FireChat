//
//  FireBaseManager.m
//  FireChat
//
//  Created by 三浦　和真 on 2015/09/06.
//  Copyright (c) 2015年 三浦　和真. All rights reserved.
//

#import "FireBaseManager.h"

static NSString * const kRootUrl = @"https://kumasandate.firebaseio.com/";
static NSString * const kUserListUrl = @"https://kumasandate.firebaseio.com/user_list/";
static NSString * const kRoomListUrl = @"https://kumasandate.firebaseio.com/room_list/";
static NSString * const kMessageListUrl = @"https://kumasandate.firebaseio.com/message_list/";

static NSString * const kChatRoomId = @"roomId";
static NSString * const kQueryMessage = @"aueryMessage";
static NSString * const kCreateRoom = @"createRoom";


@implementation FireBaseManager
{
    Firebase *_fbRoot;
    Firebase *_fbUserListManager;
    Firebase *_fbRoomListManager;
    Firebase *_fbMessageListManager;
    
    NSString *_userId;
    NSString *_botId;
}

// 初期化

-(id)initWithId:(NSString *)userID
            bot:(NSString *)botID
       observer:(id)setObsever
       callback:(SEL)callback {
    
    // notification center登録
    // chat room生成完了を通知するための配慮
    NSNotificationCenter *pNotificationCenter = [NSNotificationCenter defaultCenter];
    [pNotificationCenter addObserver:setObsever
                            selector:callback
                                name:kCreateRoom
                              object:nil];
    
    // ID保存
    _botId = botID;
    _userId = userID;
    
    // Firebase初期設定
    [self initFb];
    return self;
}


-(void)initFb {
    _fbRoot = [[Firebase alloc] initWithUrl:kRootUrl];
    _fbUserListManager = [[Firebase alloc] initWithUrl:kUserListUrl];
    _fbRoomListManager = [[Firebase alloc] initWithUrl:kRoomListUrl];
    [self reqEventFromRoot];
}


-(void)reqEventFromRoot
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
                                       _userId :   @{
                                               @"room_name" : @"mugicha",
                                               @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                               },
                                       _botId :   @{
                                               @"room_name" : @"bot",
                                               @"create_at" : [NSString stringWithFormat:@"%ld",(long)[[NSDate date] timeIntervalSince1970]]
                                               }
                                       };
            
            // RoomID永続化
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            [userDef setObject:roomID forKey:kChatRoomId];
            [userDef synchronize];
            
            // 初期データ設定
            [[_fbRoot childByAppendingPath:@"room_list"] setValue:roomList];
            [[_fbRoot childByAppendingPath:@"user_list"] setValue:userList];
            
            // message list用URL
            NSString *messageURL = [NSString stringWithFormat:@"%@%@/",kMessageListUrl,roomID];
            _fbMessageListManager = [[Firebase alloc] initWithUrl:messageURL];
            
        }
        else {
            // 永続化した情報の読み出し
            NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
            NSString *roomIdFromUserDef = [userDef stringForKey:kChatRoomId];
            
            // message list用URL
            NSString *messageURL = [NSString stringWithFormat:@"%@%@/",kMessageListUrl,roomIdFromUserDef];
            _fbMessageListManager = [[Firebase alloc] initWithUrl:messageURL];
        }
        
        // post
        [NSNotification notificationWithName:kQueryMessage object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCreateRoom
                                                            object:self
                                                          userInfo:nil];
    }];
}


-(void)setFbValue:(id)newRecode
         withPath:(NSString *)pPath {
    
    [[_fbMessageListManager childByAppendingPath:pPath] setValue:newRecode];
}

-(void)setFbValue:(id)newRecode {
    
    [[_fbMessageListManager childByAutoId] setValue:newRecode];
}

- (void) reqMessageQuery:(SEL)callback
                observer:(id)setObsever
{
    // notification center登録
    NSNotificationCenter *pNotificationCenter = [NSNotificationCenter defaultCenter];
    [pNotificationCenter addObserver:setObsever
                            selector:callback
                                name:kQueryMessage
                              object:nil];
    
    [[_fbMessageListManager queryOrderedByValue] observeSingleEventOfType:FEventTypeValue
                                                            withBlock:^(FDataSnapshot *snapshot) {
                                                                
                                                                // post
                                                                [NSNotification notificationWithName:kQueryMessage object:self];
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:kQueryMessage
                                                                                                                    object:self
                                                                                                                  userInfo:(NSDictionary*)snapshot];
                                                                
                                                            }
                                                      withCancelBlock:^(NSError *error) {
                                                          NSLog(@"error %@",error);
                                                      }];
}

@end
