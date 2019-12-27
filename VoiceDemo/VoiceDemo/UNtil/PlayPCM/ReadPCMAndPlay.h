//
//  ReadPCMAndPlay.h
//  MSCSpeaker
//
//  Created by Mr Qian on 16/3/30.
//  Copyright © 2016年 Mr Qian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReadPCMAndPlay : NSObject

//单例
+ (ReadPCMAndPlay*)shareRP;

//播放pcm原生文件
//参数表示pcm的完整路径
- (void)play:(NSString*)pcmPath;

@end
