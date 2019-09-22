//
//  ShareView.h
//  TYAlertControllerDemo
//
//  Created by tanyang on 15/10/26.
//  Copyright © 2015年 tanyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NKNapster+Extensions.h"

@protocol SettingDelegate <NSObject>

- (void) add2Queue:(NKTrack*) track;
- (void) add2Library:(NKTrack*) track;
- (void) add2Playlist:(NKTrack*) track;

@end

@interface ShareView : UIView

@property (nonatomic, weak) id<SettingDelegate> delegate;

@property NKTrack *track;

@end
