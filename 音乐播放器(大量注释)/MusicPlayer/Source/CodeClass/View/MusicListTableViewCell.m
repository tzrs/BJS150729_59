//
//  MusicListTableViewCell.m
//  MusicPlayer
//
//  Created by 李志强 on 15/10/5.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import "MusicListTableViewCell.h"

@implementation MusicListTableViewCell

-(void)setModel:(MusicInfoModel *)model
{
//    self.headImageView.image = xxxx
    self.songNameLable.text = model.name;
    self.authorNameLabel.text = model.singer;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
