//
//  YiDa_TTSViewController.m
//  VoiceDemo
//
//  Created by 黄嘉群 on 2019/12/19.
//  Copyright © 2019 黄嘉群. All rights reserved.
//

#import "YiDa_TTSViewController.h"
#import "iflyMSC/IFlySpeechUtility.h"
#import "iflyMSC/IFlySpeechConstant.h"
#import <QuartzCore/QuartzCore.h>
#import "Definition.h"
@interface YiDa_TTSViewController ()

@end

@implementation YiDa_TTSViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"语音合成";
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    //adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (IOS7_OR_LATER)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
#endif
    
    
    self.tView = [[UITextView alloc] initWithFrame:CGRectMake(10, 20, self.view.bounds.size.width-20, 300)];
    self.tView.text = @"        12月12日，在第六届全国大众冰雪季启动仪式现场，《我和我的祖国》花样滑冰表演美轮美奂。今年是新中国成立70周年，这支囊括了男子单人滑、女子单人滑、双人滑、冰上舞蹈、队列滑的表演队伍，由刚刚获得2019年花样滑冰总决赛双人滑冠、亚军的隋文静/韩聪、彭程/金杨领滑，他们精心编排、刻苦训练，用优美的舞姿向祖国汇报，抒发了中国冰雪人对祖国的无限热爱，将爱国主义热情持续释放和燃烧。";
    self.tView.backgroundColor = [UIColor lightGrayColor];
    self.tView.textColor = [UIColor blueColor];
    self.tView.font = [UIFont systemFontOfSize:18];
    self.tView.editable = NO;
    self.tView.layer.cornerRadius = 10;
    self.tView.layer.masksToBounds = YES;
    [self.view addSubview:self.tView];
    
    
    self.tView.backgroundColor = [UIColor lightGrayColor];
    self.tView.textColor = [UIColor blueColor];
    self.tView.font = [UIFont systemFontOfSize:18];
    self.tView.editable = NO;
    self.tView.layer.cornerRadius = 10;
    self.tView.layer.masksToBounds = YES;
    [self.view addSubview:self.tView];
    
    //
    UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [startBtn setTitle:@"开始合成会话" forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    startBtn.backgroundColor = [UIColor redColor];
    startBtn.layer.cornerRadius = 5;
    startBtn.layer.masksToBounds = YES;
    startBtn.frame = CGRectMake(10, self.tView.frame.origin.y+self.tView.frame.size.height+40, 150, 40);
    [startBtn addTarget:self action:@selector(beginToSay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    
    //
    UIButton *prBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [prBtn setTitle:@"暂停播放" forState:UIControlStateNormal];
    [prBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    prBtn.backgroundColor = [UIColor greenColor];
    prBtn.layer.cornerRadius = 5;
    prBtn.layer.masksToBounds = YES;
    prBtn.frame = CGRectMake(startBtn.frame.origin.x+startBtn.frame.size.width+10, startBtn.frame.origin.y, 140, 40);
    [prBtn addTarget:self action:@selector(pauseOrResumePlay:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:prBtn];
    
    //
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(10, self.tView.frame.origin.y+self.tView.frame.size.height+10, 300, 10);
    self.progressView.progress = 0.0;
    self.progressView.trackTintColor = [UIColor clearColor];
    self.progressView.progressTintColor = [UIColor greenColor];
    [self.view addSubview:self.progressView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initMSC];
    
    self.progressView.progress = 0.0;
}
/**
 @功能：初始化科大讯飞语音配置，语音识别对象
 @参数：无
 @返回值：无
 */
- (void)initMSC{
    //创建语音配置
    // NSString *appid = [NSString stringWithFormat:@"appid=%@,timeout=%@",APPID_VALUE, TIMEOUT_VALUE];
    //Appid是应用的身份信息，具有唯一性，初始化时必须要传入Appid。
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", @"YourAppid"];
    [IFlySpeechUtility createUtility:initString];
    
    //获取语音合成单例
    _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    //设置协议委托对象
    _iFlySpeechSynthesizer.delegate = self;
    //设置合成参数
    //合成的语速,取值范围 0~100,默认为50
    // [self.iFlySpeechSynthesizer setParameter:@"50" forKey:[IFlySpeechConstant SPEED]];
    [_iFlySpeechSynthesizer setParameter:[IFlySpeechConstant TYPE_CLOUD]
                                  forKey:[IFlySpeechConstant ENGINE_TYPE]];
    //合成的音量,取值范围 0~100,默认为50
    [self.iFlySpeechSynthesizer setParameter:@"100" forKey:[IFlySpeechConstant VOLUME]];
    
    //发音人,默认为”xiaoyan”;可以设置的参数列表可参考个性化发音人列表
    [self.iFlySpeechSynthesizer setParameter:@"xiaoyan" forKey:[IFlySpeechConstant VOICE_NAME]];
    
    //音频采样率,目前支持的采样率有 16000 和 8000;
    [self.iFlySpeechSynthesizer setParameter:@"8000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
    
    //设置保存音频路径，不需要保存时设置nil，默认目录是documents。tts.pcm为保存的文件名
    [self.iFlySpeechSynthesizer setParameter:nil forKey:[IFlySpeechConstant TTS_AUDIO_PATH]];
    //[_iFlySpeechSynthesizer setParameter:@"tts.pcm" forKey:[IFlySpeechConstant TTS_AUDIO_PATH]];
    
    //设置在线工作方式
    [_iFlySpeechSynthesizer setParameter:[IFlySpeechConstant TYPE_CLOUD]
                                  forKey:[IFlySpeechConstant ENGINE_TYPE]];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //销毁语音合成并设置委托为nil
    [self.iFlySpeechSynthesizer stopSpeaking];//停止合成会话
    [self.iFlySpeechSynthesizer setDelegate:nil];
    [IFlySpeechSynthesizer destroy];//销毁合成对象
    
}
/**
 @功能：开始说话，进行语音识别
 @参数：无
 @返回值：无
 */
- (void) beginToSay
{
    if (![self.iFlySpeechSynthesizer isSpeaking])//是否正在播放
    {
        [self.iFlySpeechSynthesizer startSpeaking:self.tView.text];
    }
}

/**
 @功能：暂停或恢复播放
 @参数：暂停或恢复播放按钮
 @返回值：无
 */
- (void)pauseOrResumePlay:(UIButton*)button
{
    if ([[button currentTitle] isEqualToString:@"暂停播放"])
    {
        [button setTitle:@"恢复播放" forState:UIControlStateNormal];
        [self.iFlySpeechSynthesizer pauseSpeaking];//暂停播放之后，合成不会暂停，仍会继续，如果发生错误则会回调错误`onCompleted`
    }
    else
    {
        [button setTitle:@"暂停播放" forState:UIControlStateNormal];
        [self.iFlySpeechSynthesizer resumeSpeaking];//恢复播放
    }
}

- (void)show:(NSString*)info
{
    if (!self.HUD)
    {
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
    }
    
    self.HUD.labelText = info;
    self.HUD.mode = MBProgressHUDModeText;//设置模式为文本
    [self.HUD show:YES];
    [self.HUD hide:YES afterDelay:1.5];
}

#pragma mark - IFlySpeechSynthesizerDelegate
//合成结束
- (void) onCompleted:(IFlySpeechError *) error {
    [self show:@"合成会话结束了"];
}
//合成开始
- (void) onSpeakBegin {
    [self show:@"开始合成会话"];
}
//合成缓冲进度
- (void) onBufferProgress:(int) progress message:(NSString *)msg {
    NSLog(@"%d",progress);
}

//合成播放进度
- (void) onSpeakProgress:(int) progress beginPos:(int)beginPos endPos:(int)endPos {
    [UIView animateWithDuration:0.3 animations:^{
        self.progressView.progress = progress/100.0;
    }];
}

/** 暂停播放回调 */
- (void) onSpeakPaused
{
    [self show:@"暂停播放了"];
}

/** 恢复播放回调 */
- (void) onSpeakResumed
{
    [self show:@"恢复播放了"];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
