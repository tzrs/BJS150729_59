//
//  MusicPlayView.h
//  MusicPlayer
//
//  Created by 李志强 on 15/10/5.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MusicPlayViewDelegate <NSObject>

-(void)lastSongAction;

@end

@interface MusicPlayView : UIView
@property(nonatomic,strong)UIScrollView  * mainScrollView;
@property(nonatomic,strong)UIImageView * headImageView;
@property(nonatomic,strong)UITableView * lyricTableView;
@property(nonatomic,strong)UILabel * curTimeLabel;
@property(nonatomic,strong)UISlider * progressSlider;
@property(nonatomic,strong)UILabel * totleTiemLabel;

@property(nonatomic,strong)UIButton * lastSongButton;
@property(nonatomic,strong)UIButton * playPauseButton;
@property(nonatomic,strong)UIButton * nextSongButton;

@property(nonatomic,weak)id<MusicPlayViewDelegate>delegate;

@end
