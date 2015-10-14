//
//  MusicListTableViewCell.h
//  MusicPlayer
//
//  Created by 李志强 on 15/10/5.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicInfoModel.h"

@interface MusicListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *headImageView;
@property (weak, nonatomic) IBOutlet UILabel *songNameLable;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;

@property(nonatomic,strong)MusicInfoModel * model;

@end



