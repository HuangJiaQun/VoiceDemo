//
//  ReadPCMAndPlay.m
//  MSCSpeaker
//
//  Created by Mr Qian on 16/3/30.
//  Copyright © 2016年 Mr Qian. All rights reserved.
//

#import "ReadPCMAndPlay.h"
#import <AudioToolbox/AudioToolbox.h>

#define QUEUE_BUFFER_SIZE 4 //队列缓冲个数
#define EVERY_READ_LENGTH 1000 //每次从文件读取的长度
#define MIN_SIZE_PER_FRAME 2000 //每侦最小数据长度

static ReadPCMAndPlay *g_rp = nil;

@interface ReadPCMAndPlay ()
{
    AudioStreamBasicDescription audioDescription;///音频参数 这个类提供了对于音频文件的描述
    AudioQueueRef audioQueue;//音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];//音频缓存
    NSLock *synlock ;///同步控制  NSLock *lock = [[NSLock alloc] init];//创建同步锁
    Byte *pcmDataBuffer;//pcm的读文件数据区
    FILE *file;//pcm源文件
}
@end

//=============================================================================================================================
// AudioStreamBasicDescription
/*
 数据样例
 (AudioStreamBasicDescription) _format = {
 mSampleRate = 44100
 mFormatID = kAudioFormatLinearPCM
 mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
 mBytesPerPacket = 1
 mFramesPerPacket = 1152
 mBytesPerFrame = 0
 mChannelsPerFrame = 2
 mBitsPerChannel = 0
 mReserved = 0
 }
 
 如果需求是播放一段音频（File、Buffer或URL），AVAudioPlayer通常都可以满足需求。
 如果对性能有要求，或者是播放流式Buffer，那就得用到Audio Queue Services，Audio Queue播放是以Packet形式。
 Extended Audio File Services有一些API，可用帮你计算每个包的大小；
 Audio File Service或Audio File Stream Services更智能，你只管塞数据给它，它自动把包组好给你。
 在ffmpeg软解播放器中可以使用Auido Queue实现音频播放。
*/
@implementation ReadPCMAndPlay

+ (ReadPCMAndPlay*)shareRP {
    @synchronized(self) {
        if (!g_rp) {
            g_rp = [[ReadPCMAndPlay alloc] init];
        }
    }
    return g_rp;
}

//播放pcm原生文件
//参数表示pcm的完整路径
- (void)play:(NSString*)pcmPath {
    NSLog(@"filepath = %@",pcmPath);
    NSFileManager *manager = [NSFileManager defaultManager];//创建文件管理器
    BOOL exist = [manager fileExistsAtPath:pcmPath];//如何判断文件夹下某个文件是否存在
    if (exist) {//如果存在
        //NSLog(@"file size = %lld",[[manager attributesOfItemAtPath:pcmPath error:nil] fileSize]);
        file  = fopen([pcmPath UTF8String], "r");//pcm源文件,其意义是在当前目录下打开文件[pcmPath UTF8String]，只允许进行“读”操作，并使file指向该文件。
        if(file) {//文件不为空
            /*
             函数名: fseek
             功 能: 重定位流上的文件指针
             用 法: int fseek(FILE *stream, long offset, int fromwhere);
             描 述: 函数设置文件指针stream的位置。如果执行成功，stream将指向以fromwhere为基准，偏移offset个字节的位置。如果执行失败(比如offset超过文件自身大小)，则不改变stream指向的位置。
             int fseek(FILE *stream, long int offset, int whence)
             stream -- 这是指向 FILE 对象的指针，该 FILE 对象标识了流。
             offset -- 这是相对 whence 的偏移量，以字节为单位。
             whence -- 这是表示开始添加偏移 offset 的位置。它一般指定为下列常量之一,SEEK_SET:文件开头, SEEK_CUR:当前位置 SEEK_END:文件结尾
            */
            fseek(file, 0, SEEK_SET);//file=这是指向 FILE 对象的指针，该 FILE 对象标识了流。//SEEK_SET=文件的开头=设置文件偏移量为0,如果成功，则该函数返回零，否则返回非零值。意思是把文件指针指向文件的开头
            
            pcmDataBuffer = malloc(EVERY_READ_LENGTH);//pcm的读文件数据区 //EVERY_READ_LENGTH=1000,每次从文件读取的长度,/malloc()动态分配内存,用malloc分配内存的首地址
        } else{
            NSLog(@"文件打开失败啦!!!!!!");
        }
        
        synlock = [[NSLock alloc] init];//创建锁
        
        [self initAudio];//初始化音频队列
        
        AudioQueueStart(audioQueue, NULL);//初始化音频 queue用来记录或者回放
        for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
        {
            [self readPCMAndPlay:audioQueue buffer:audioQueueBuffers[i]];
        }
        /*
         audioQueue使用的是驱动回调方式，即通过AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);传入一个buff去播放，播放完buffer区后通过回调通知用户,
         用户得到通知后再重新初始化buff去播放，周而复始,当然，可以使用多个buff提高效率(测试发现使用单个buff会小卡)
         */
    }
}

#pragma mark -
#pragma mark player call back
/*
 试了下其实可以不用静态函数，但是c写法的函数内是无法调用[self ***]这种格式的写法，所以还是用静态函数通过void *input来获取原类指针
 这个回调存在的意义是为了重用缓冲buffer区，当通过AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);函数放入queue里面的音频文件播放完以后，通过这个函数通知
 调用者，这样可以重新再使用回调传回的AudioQueueBufferRef
 */
static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    ReadPCMAndPlay *rp = (__bridge ReadPCMAndPlay *)input;//
    [rp readPCMAndPlay:outQ buffer:outQB];
}



-(void)initAudio
{
    /*
     struct AudioStreamBasicDescription
     {
     
     Float64             mSampleRate;//M采样率：流中数据每秒的帧数。
     AudioFormatID       mFormatID;格式：在流中指定通用音频数据格式的标识符。（kAudioFormatLinearPCM等）
     
     AudioFormatFlags    mFormatFlags;//用于指定格式详细信息的特定于格式的标志(kLinearPCMFormatFlagIsSignedInteger,kLinearPCMFormatFlagIsFloat,kLinearPCMFormatFlagIsBigEndian,kLinearPCMFormatFlagIsPacked,kLinearPCMFormatFlagIsNonInterleaved, etc.)
     
     UInt32              mBytesPerPacket;数据包中的字节数
     UInt32              mFramesPerPacket;每个数据包中的样本帧数
     UInt32              mBytesPerFrame;单个数据样本帧中的字节数。
     UInt32              mChannelsPerFrame;每帧数据中的通道数
     UInt32              mBitsPerChannel;数据帧中每个通道的采样数据位数
     UInt32              mReserved;
     };
     */
    ///设置音频参数
    audioDescription.mSampleRate = 16000;//采样率，必须保证与科大讯飞的采样率保证一致！！
    audioDescription.mFormatID = kAudioFormatLinearPCM;//'lpcm',：在流中指定通用音频数据格式的标识符志
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;//数据格式.,通常L/R，整形or浮点）的方式存储。 PCM格式标记已签名集成数据格式；（L/R，整形or浮点）
    audioDescription.mChannelsPerFrame = 1;///单声道,,
    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据,每个Packet的帧数
    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化,每个声道的采样深度
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel/8) * audioDescription.mChannelsPerFrame;//每帧的Byte数
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame;//每个Packet的帧数
    //创建一个新的从audioqueue到硬件层的通道
    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &audioQueue);//使用player的内部线程播
    //添加buffer=缓冲器 区
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++) {
        AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);//创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大,音频缓存
    }
}

//播放音频
-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB
{
    [synlock lock];//加锁。
    int readLength = (int)fread(pcmDataBuffer, 1, EVERY_READ_LENGTH, file);//读取文件
    //NSLog(@"read raw data size = %d",readLength);
    outQB->mAudioDataByteSize = readLength;//用来指示数据区大小
    Byte *audiodata = (Byte *)outQB->mAudioData;//用来保存数据区
    for(int i=0;i<readLength;i++)
    {
        audiodata[i] = pcmDataBuffer[i];
    }
    /*
     将创建的buffer区添加到audioqueue里播放
     AudioQueueBufferRef用来缓存待播放的数据区，AudioQueueBufferRef有两个比较重要的参数，AudioQueueBufferRef->mAudioDataByteSize用来指示数据区大小，AudioQueueBufferRef->mAudioData用来保存数据区
     */
    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);//将创建的buffer区添加到audioqueue里播放
    [synlock unlock];//解锁
}

@end
