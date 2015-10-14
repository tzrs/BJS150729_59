//
//  MusicPlayViewController.m
//  MusicPlayer
//
//  Created by 李志强 on 15/10/5.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import "MusicPlayViewController.h"
#import "MusicPlayView.h"

@interface MusicPlayViewController ()<MusicPlayToolsDelegate,MusicPlayViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong)MusicPlayView * rv;
@property(nonatomic,strong)MusicPlayTools * aa;
@property(nonatomic,strong)NSArray * lyricArray;
@end

static MusicPlayViewController * mp = nil;

@implementation MusicPlayViewController

-(void)loadView
{
    self.rv = [[MusicPlayView alloc]init];
    self.view = _rv;
}

// 单例方法
+(instancetype)shareMusicPlay
{
    if (mp == nil) {
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            mp = [[MusicPlayViewController alloc] init];
        });
    }
    return mp;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // ios7以后,原点是(0,0)点, 而我们希望是ios7之前的(0,64)处,也就是navigationController导航栏的下面作为(0,0)点. 下面的设置就是做这个的.
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // 这里用一个指针指向播放器单例,以后使用这个单例的地方,可以直接使用这个指针,而不用每次都打印那么多.
    self.aa = [MusicPlayTools shareMusicPlay];
    [MusicPlayTools shareMusicPlay].delegate = self;
    
    // 切割UIImageView为圆形.
    self.rv.headImageView.layer.cornerRadius = kScreenWidth / 2 ;
    self.rv.headImageView.layer.masksToBounds = YES;
    
    // 为View设置代理
    self.rv.delegate = self;
    [self.rv.nextSongButton addTarget:self action:@selector(nextSongButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.rv.progressSlider addTarget:self action:@selector(progressSliderAction:) forControlEvents:(UIControlEventValueChanged)];
    [self.rv.playPauseButton addTarget:self action:@selector(playPauseButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    
    // 为播放器添加观察者,观察播放速率"rate".
    // 因为AVPlayer没有一个内部属性来标识当前的播放状态.所以我们可以通过rate变相的得到播放状态.
    // 这里观察播放速率rate,是为了获得播放/暂停的触发事件,作出相应的响应事件(比如更改button的文字).
    [self.aa.player addObserver:self forKeyPath:@"rate" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    
    // 设置歌词的tableView的代理
    self.rv.lyricTableView.delegate = self;
    self.rv.lyricTableView.dataSource = self;
}

// 观察播放速率的相应方法: 速率==0 表示没有暂停.
// 速率不为0 表示播放中.
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"rate"]) {
        if ([[change valueForKey:@"new"] integerValue] == 0) {
            [self.rv.playPauseButton setTitle:@"已经暂停" forState:(UIControlStateNormal)];
        }else
        {
            [self.rv.playPauseButton setTitle:@"正在播放" forState:(UIControlStateNormal)];
        }
    }
}

// 单例中,viewDidLoad只走一遍.切歌之类的操作需要多次进行,所以应该写在viewAppear中.
// 每次出现一次页面都会尝试重新播放.
-(void)viewWillAppear:(BOOL)animated
{
    [self p_play];
}

-(void)p_play
{
    // 判断当前播放器的model 和 点击cell的index对应的model,是不是同一个.
    // 如果是同一个,说明正在播放的和我们点击的是同一个, 这个时候不需要重新播放.直接返回就行了.
    if ([[MusicPlayTools shareMusicPlay].model isEqual:[[GetDataTools shareGetData] getModelWithIndex:self.index]]) {
        return;
    }
    
    // 如果播放中和我们点击的不是同一个,那么替换当前播放器的model.
    // 然后重新准备播放.
    [MusicPlayTools shareMusicPlay].model = [[GetDataTools shareGetData] getModelWithIndex:self.index];
    
    // 注意这里准备播放 不是播放!!!
    [[MusicPlayTools shareMusicPlay] musicPrePlay];
    
    // 设置歌曲封面
    [self.rv.headImageView sd_setImageWithURL:[NSURL URLWithString:[MusicPlayTools shareMusicPlay].model.picUrl]];
    
    // 设置歌词
    self.lyricArray  = [self.aa getMusicLyricArray];
    [self.rv.lyricTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 这个协议方法是播放器单例调起的.
// 作为协议方法,播放器单例将播放进度已参数的形式传出来.
-(void)getCurTiem:(NSString *)curTime Totle:(NSString *)totleTime Progress:(CGFloat)progress
{
    self.rv.curTimeLabel.text = curTime;
    self.rv.totleTiemLabel.text = totleTime;
    self.rv.progressSlider.value = progress;
    
    // 2d仿真变换.
    self.rv.headImageView.transform = CGAffineTransformRotate(self.rv.headImageView.transform, M_PI/360);
    
    // 返回歌词在数组中的位置,然后根据这个位置,将tableView跳到对应的那一行.
    NSInteger index = [self.aa getIndexWithCurTime];
    if (index == -1) {
        return;
    }
    NSIndexPath * tmpIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.rv.lyricTableView  selectRowAtIndexPath:tmpIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

-(void)lastSongAction
{
    if (self.index > 0) {
        self.index --;
    }else{
       self.index = [GetDataTools shareGetData].dataArray.count - 1;
    }
    [self p_play];
}
-(void)nextSongButtonAction:(UIButton *)sender
{
    if (self.index == [GetDataTools shareGetData].dataArray.count -1) {
        self.index = 0;
    }else
    {
        self.index ++;
    }
    [self p_play];
}

-(void)endOfPlayAction
{
    [self nextSongButtonAction:nil];
}
// 滑动slider
-(void)progressSliderAction:(UISlider *)sender
{
    [[MusicPlayTools shareMusicPlay] seekToTimeWithValue:sender.value];
}

// 暂停播放方法
-(void)playPauseButtonAction:(UIButton *)sender
{
    // 根据AVPlayer的rate判断.
    if ([MusicPlayTools shareMusicPlay].player.rate == 0) {
        [[MusicPlayTools shareMusicPlay] musicPlay];
    }else
    {
        [[MusicPlayTools shareMusicPlay] musicPause];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lyricArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault)reuseIdentifier:@"cell"];
    }
    
    // 这里使用kvc取值,只是为了展示用,并不是必须用.
    cell.textLabel.text = [self.lyricArray[indexPath.row] valueForKey:@"lyricStr"];
    
    return cell;
}

@end
