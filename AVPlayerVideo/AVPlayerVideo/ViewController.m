//
//  ViewController.m
//  AVPlayerVideo
//
//  Created by 王 on 16/3/7.
//  Copyright © 2016年 WLChopSticks. All rights reserved.
//
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"


@interface ViewController ()

@property (weak, nonatomic) AVPlayerItem *playerItem;
@property (weak, nonatomic) AVPlayer *player;

@property (weak, nonatomic) UILabel *currentTimeLabel;
@property (weak, nonatomic) UILabel *totalTimeLabel;
@property (weak, nonatomic) UISlider *timeSlider;
@property (weak, nonatomic) UIButton *startBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSURL *sourceMovieURL = [NSURL URLWithString:@"http://v.jxvdy.com/sendfile/V7bzjsH5sIZlBzVG7t7qbL1u-y1_k6E0DCtzyZ8iv-pRF3GmewWOj-HQ_grNppGnnx_rRHb-bztNWAvzGQ"];
    
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    self.playerItem = playerItem;
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    self.player = player;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.view.layer.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    //播放视频时使用
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //计算缓冲进度使用
    [playerItem addObserver:self forKeyPath:@"loadTimeRange" options:NSKeyValueObservingOptionNew context:nil];
    
    
    //布局
    [self decorateUI];
    
    
}

#pragma -mark 布局
-(void)decorateUI {
    
    //设置开始按钮
    UIButton *startBtn = [[UIButton alloc]init];
    [startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [startBtn setTitle:@"暂停" forState:UIControlStateSelected];
    [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.startBtn = startBtn;
    [startBtn addTarget:self action:@selector(startBtnClicking) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    
    //设置播放时间的label
    UILabel *currentTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, 100, 20)];
    self.currentTimeLabel = currentTimeLabel;
    currentTimeLabel.text = @"00:00";
    [self.view addSubview:currentTimeLabel];
    
    //设置共有时长的label
    UILabel *totalTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 30, 100, 20)];
    self.totalTimeLabel = totalTimeLabel;
    totalTimeLabel.text = @"00:00";
    [self.view addSubview:totalTimeLabel];
    
    //设置进度条
    UISlider *timeSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 300, 300, 30)];
    self.timeSlider = timeSlider;
    [self.view addSubview:timeSlider];
    
    
    //约束
    //开始按钮的约束
    [startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.bottom.equalTo(self.view.mas_bottom);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
    //播放时间的约束
    [currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(startBtn.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
    //共有时长的约束
    [totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
    //进度条的约束
    [timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(currentTimeLabel.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
        make.right.equalTo(totalTimeLabel.mas_left);
        make.height.mas_equalTo(30);
    }];
    
}

#pragma -mark 开始按钮的点击事件
-(void)startBtnClicking {
    
    self.startBtn.selected = !self.startBtn.selected;
    if (self.startBtn.selected) {
        [self.player play];
    }else {
        [self.player pause];
    }
    
}

#pragma -mark KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            //可以播放
            
            //获取视频总长度
            CMTime duration = self.playerItem.duration;
            //CMTime的value除以timescale得到的是秒数
            CGFloat durationTime = duration.value / duration.timescale;
            NSString *durationTimeString = [self timeToTimeFormatter:durationTime];
            self.totalTimeLabel.text = durationTimeString;
            //设置最大时间
            self.timeSlider.maximumValue = durationTime;
            
            //监控视频播放进度
            [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
                CGFloat currentTime = self.playerItem.currentTime.value / self.playerItem.currentTime.timescale;
                NSString *currentTimeString = [self timeToTimeFormatter:currentTime];
                self.currentTimeLabel.text = currentTimeString;
                [self.timeSlider setValue:currentTime animated:YES];
            }];
        }
    }
    
}

//将时间转换成时间格式
- (NSString *)timeToTimeFormatter: (CGFloat)time {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    if (time >= 3600) {
        formatter.dateFormat = @"HH:mm:ss";
        
    }else {
        formatter.dateFormat = @"mm:ss";
    }
    return [formatter stringFromDate:date];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

