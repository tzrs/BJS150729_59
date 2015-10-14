//
//  GetDataTools.m
//  MusicPlayer
//
//  Created by 李志强 on 15/10/6.
//  Copyright (c) 2015年 李志强. All rights reserved.
//

#import "GetDataTools.h"

static GetDataTools * gd = nil;

@implementation GetDataTools

// 单例方法,创建单例要熟练掌握
+(instancetype)shareGetData
{
    if (gd == nil) {
        static dispatch_once_t once_token;
        dispatch_once(&once_token, ^{
            gd = [[GetDataTools alloc] init];
        });
    }
    return gd;
}

-(void)getDataWithURL:(NSString *)URL PassValue:(PassValue)passValue
{
    // 这里为什么要用子线程?
    // 因为,这里请求数据时:arrayWithContentsOfURL方法是同步请求(请求不结束,主线程什么也干不了)
    // 所以,为了规避这种现象,我们将请求的动作放到子线程中.
    
    // 创建线程队列(全局)
    dispatch_queue_t globl_t = dispatch_get_global_queue(0, 0);
    
    // 定义子线程的内容.
    dispatch_async(globl_t, ^{
        // 在这对花括号内的所有操作都不会阻塞主线程了哦
        
        // 请求数据
        NSArray * array =[NSArray arrayWithContentsOfURL:[NSURL URLWithString:URL]];
        
        // 解析,将解析好的"歌曲信息模型", 加入我们的属性数组, 以便外界能随时访问.
        for (NSDictionary * dict in array) {
            MusicInfoModel * model = [[MusicInfoModel alloc] init];
            [model setValuesForKeysWithDictionary:dict];
            [self.dataArray addObject:model];
        }
        
        // 重点!!!
        // 这个Block是外界传入的(外界的代码放到这里来执行), 但是我们的self.dataArray可以作为参数,传递给外界的代码块中.这样,外界就能拿到我们的这个数组.
        passValue(self.dataArray);
    });
}

// 属性数组的懒加载(并不是必须用懒加载)
-(NSMutableArray *)dataArray
{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

// 根据传入的index返回一个"歌曲信息模型"
-(MusicInfoModel *)getModelWithIndex:(NSInteger)index
{
    return self.dataArray[index];
}

@end
