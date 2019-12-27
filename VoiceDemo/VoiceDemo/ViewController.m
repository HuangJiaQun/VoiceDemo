//
//  ViewController.m
//  VoiceDemo
//
//  Created by 黄嘉群 on 2019/12/18.
//  Copyright © 2019 黄嘉群. All rights reserved.
//

#import "ViewController.h"
#import "IFlyMSC/IFlyMSC.h"
#import "Definition.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Appid是应用的身份信息，具有唯一性，初始化时必须要传入Appid。
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", @"YourAppid"];
    [IFlySpeechUtility createUtility:initString];
    // Do any additional setup after loading the view.
}


@end
