//
//  YiDa_TTSViewController.h
//  VoiceDemo
//
//  Created by 黄嘉群 on 2019/12/19.
//  Copyright © 2019 黄嘉群. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iflyMSC/IFlySpeechSynthesizerDelegate.h"
#import "iflyMSC/IFlySpeechSynthesizer.h"
#import "MBProgressHUD.h"
NS_ASSUME_NONNULL_BEGIN

@interface YiDa_TTSViewController : UIViewController<IFlySpeechSynthesizerDelegate>

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;
@property (nonatomic, strong) UITextView *tView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

NS_ASSUME_NONNULL_END
