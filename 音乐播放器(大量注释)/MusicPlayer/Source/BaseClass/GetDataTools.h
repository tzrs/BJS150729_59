//
//  GetDataTools.h
//  MusicPlayer
//
//  Created by 李志强 on 15/10/6.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PassValue)(NSArray * array);

@interface GetDataTools : NSObject

// 作为单例的属性,这个数组可以在任何位置,任何时间被访问.
@property(nonatomic,strong)NSMutableArray * dataArray;

// 单例方法
+(instancetype)shareGetData;

// 重点!!!!!!!!!
// 根据传入的URL,通过Block返回一个数组.
// 这种"block回传值"的形式,不单单要会用,而且要会写.
// 工作之后,有些单位专门编写SDK(既我们使用的第三方),这些三方现在基本都支持这种形式.
-(void)getDataWithURL:(NSString *)URL PassValue:(PassValue)passValue;

// 根据传入的Index,返回一个"歌曲信息的模型",这个模型来自上面的属性数组.
-(MusicInfoModel *)getModelWithIndex:(NSInteger)index;

@end




