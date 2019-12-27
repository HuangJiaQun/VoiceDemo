//
//  YiDa_SpeechRecognizerVC.h
//  MSCDemo
//
//  Created by 钱老师 on 14-7-12.
//  Copyright (c) 2014年 钱老师. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iflyMSC/IFlySpeechRecognizerDelegate.h"
#import "iflyMSC/IFlySpeechRecognizer.h"

#import "MBProgressHUD.h"

#import <AVFoundation/AVFoundation.h>

@interface YiDa_SpeechRecognizerVC : UIViewController<IFlySpeechRecognizerDelegate>

@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;
@property (nonatomic, strong) UITextView *tView;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) NSMutableString *result;
@property (nonatomic, strong) UIProgressView *progressView;

@end
