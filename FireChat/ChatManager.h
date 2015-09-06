//
//  ChatManager.h
//  FireChat
//
//  Created by 三浦　和真 on 2015/09/06.
//  Copyright (c) 2015年 三浦　和真. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface ChatManager : NSObject

-(id)initWithId:(NSString *)userID
            bot:(NSString *)botID
       observer:(id)setObsever
       callback:(SEL)callback;

-(void)setFbValue:(id)newRecode
         withPath:(NSString *)path;

-(void)setFbValue:(id)newRecode;

-(void)requestMessageQuery:(SEL)callback
               observer:(id)setObsever;

@end
