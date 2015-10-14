//
//  MusicPlayTools.m
//  MusicPlayer
//
//  Created by 李志强 on 15/10/6.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import "MusicPlayTools.h"

static MusicPlayTools * mp = nil;

@interface MusicPlayTools ()
@property(nonatomic,strong)NSTimer * timer;
@end

@implementation MusicPlayTools

// 单例方法要熟练掌握.
+(instancetype)shareMusicPlay
{
    if (mp == nil) {
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            mp = [[MusicPlayTools alloc] init];
        });
    }
    return mp;
}

// 这里为什么要重写init方法呢?
// 因为,我们应该得到 "某首歌曲播放结束" 这一事件,之后由外界来决定"播放结束之后采取什么操作".
// AVPlayer并没有通过block或者代理向我们返回这一状态(事件),而是向通知中心注册了一条通知(AVPlayerItemDidPlayToEndTimeNotification),我们也只有这一条途径获取播放结束这一事件.
// 所以,在我们创建好一个播放器时([[AVPlayer alloc] init]),应该立刻为通知中心添加观察者,来观察这一事件的发生.
// 这个动作放到init里,最及时也最合理.
- (instancetype)init
{
    self = [super init];
    if (self) {
        _player = [[AVPlayer alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endOfPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}
// 播放结束后的方法,由代理具体实现行为.
-(void) endOfPlay:(NSNotification *)sender
{
    // 为什么要先暂停一下呢?
    // 看看 musicPlay方法, 第一个if判断,你能明白为什么吗?
    [self musicPause];
    [self.delegate endOfPlayAction];
}

// 准备播放,我们在外部调用播放器播放时,不会调用"直接播放",而是调用这个"准备播放",当它准备好时,会直接播放.
-(void)musicPrePlay
{
    // 通过下面的逻辑,只要AVPlayer有currentItem,那么一定被添加了观察者.
    // 所以上来直接移除之.
    if (self.player.currentItem) {
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    }
    
    // 根据传入的URL(MP3歌曲地址),创建一个item对象
    // initWithURL的初始化方法建立异步链接. 什么时候连接建立完成我们不知道.但是它完成连接之后,会修改自身内部的属性status. 所以,我们要观察这个属性,当它的状态变为AVPlayerItemStatusReadyToPlay时,我们便能得知,播放器已经准备好,可以播放了.
    AVPlayerItem * item = [[ AVPlayerItem alloc] initWithURL:[NSURL URLWithString:self.model.mp3Url]];
    
    // 为item的status添加观察者.
    [item addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    
    // 用新创建的item,替换AVPlayer之前的item.新的item是带着观察者的哦.
    [self.player replaceCurrentItemWithPlayerItem:item];
}

// 观察者的处理方法
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        switch ([[change valueForKey:@"new"] integerValue]) {
            case AVPlayerItemStatusUnknown:
                NSLog(@"不知道什么错误");
                break;
            case AVPlayerItemStatusReadyToPlay:
                // 只有观察到status变为这种状态,才会真正的播放.
                [self musicPlay];
                break;
            case AVPlayerItemStatusFailed:
                // mini设备不插耳机或者某些耳机会导致准备失败.
                NSLog(@"准备失败");
                break;
            default:
                break;
        }
    }
}

// 播放
-(void)musicPlay
{
    // 如果计时器已经存在了,说明已经在播放中,直接返回.
    // 对于已经存在的计时器,只有musicPause方法才会使之停止和注销.
    if (self.timer != nil) {
        return;
    }
    
    // 播放后,我们开启一个计时器.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    
    [self.player play];
}

-(void)timerAction:(NSTimer * )sender
{
    // 重点!!! 计时器的处理方法中,不断的调用代理方法,将播放进度返回出去.
    // 一定要掌握这种形式.
    [self.delegate getCurTiem:[self valueToString:[self getCurTime]] Totle:[self    valueToString:[self getTotleTime]] Progress:[self getProgress]];
}

// 暂停方法 
-(void)musicPause
{
    [self.timer invalidate];
    self.timer = nil;
    [self.player pause];
}

// 跳转方法
-(void)seekToTimeWithValue:(CGFloat)value
{
    // 先暂停
    [self musicPause];
    
    // 跳转
    [self.player seekToTime:CMTimeMake(value * [self getTotleTime], 1) completionHandler:^(BOOL finished) {
        if (finished == YES) {
            [self musicPlay];
        }
    }];
}

// 获取当前的播放时间
-(NSInteger)getCurTime
{
    if (self.player.currentItem) {
        // 用value/scale,就是AVPlayer计算时间的算法. 它就是这么规定的.
        // 下同.
        return self.player.currentTime.value / self.player.currentTime.timescale;
    }
    return 0;
}
// 获取总时长
-(NSInteger)getTotleTime
{
    CMTime totleTime = [self.player.currentItem duration];
    if (totleTime.timescale == 0) {
        return 1;
    }else
    {
        return totleTime.value /totleTime.timescale;
    }
}
// 获取当前播放进度
-(CGFloat)getProgress
{
    return (CGFloat)[self getCurTime]/ (CGFloat)[self getTotleTime];
}

// 将整数秒转换为 00:00 格式的字符串
-(NSString *)valueToString:(NSInteger)value
{
    return [NSString stringWithFormat:@"%.2ld:%.2ld",value/60,value%60];
}

// 返回一个歌词数组(这里有Bug)
-(NSMutableArray *)getMusicLyricArray
{
    NSMutableArray * array = [NSMutableArray array];
    
    for (NSString * str in self.model.timeLyric) {
        if (str.length == 0) {
            continue;
        }
        MusicLyricModel * model = [[MusicLyricModel alloc] init];
        model.lyricTime = [str substringWithRange:NSMakeRange(1, 9)];
        model.lyricStr = [str substringFromIndex:11];
        [array addObject:model];
    }
    return array;
}

-(NSInteger)getIndexWithCurTime
{
    NSInteger index = 0;
    NSString * curTime = [self valueToString:[self getCurTime]];
    for (NSString * str in self.model.timeLyric) {
        if (str.length == 0) {
            continue;
        }
        if ([curTime isEqualToString:[str substringWithRange:NSMakeRange(1, 5)]]) {
            return index;
        }
        index ++;
    }
    return -1;
}

@end
