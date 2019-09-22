//
//  ShareView.m
//  TYAlertControllerDemo
//
//  Created by tanyang on 15/10/26.
//  Copyright © 2015年 tanyang. All rights reserved.
//

#import "ShareView.h"
#import "UIView+TYAlertView.h"

@implementation ShareView


- (IBAction)cancelAction:(id)sender {
    // hide view,or dismiss controller
    [self hideView];
}

- (IBAction)add2Queue:(id)sender {
    // hide view,or dismiss controller
    [self.delegate add2Queue:self.track];
//    NSLog(@"add2Queue");
    [self hideView];
}

- (IBAction)add2Library:(id)sender {
    // hide view,or dismiss controller
    [self.delegate add2Library:self.track];
//    NSLog(@"add2Library");
    [self hideView];
}

- (IBAction)add2Playlist:(id)sender {
    // hide view,or dismiss controller
    [self.delegate add2Playlist:self.track];
//    NSLog(@"add2Playlist");
    [self hideView];
}

- (IBAction)go2Artist:(id)sender {
    // hide view,or dismiss controller
    NSLog(@"go2Artist");
    [self hideView];
}

- (IBAction)share:(id)sender {
    // hide view,or dismiss controller
    NSLog(@"share");
    [self hideView];
}

- (IBAction)karaoke:(id)sender {
    // hide view,or dismiss controller
    NSLog(@"karaoke");
    [self hideView];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
