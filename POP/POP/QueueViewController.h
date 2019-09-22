//
//  QueueViewController.h
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NKTrackListPlayer.h"
#import "MusicHomeViewController.h"
#import "PlayViewController.h"
#import <NapsterKit/NapsterKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol QueueDelegate <NSObject>

- (void)cellButtonClicked:(NKTrack *)track;
//- (void)add2Library:(NSInteger)index;

@end

@interface QueueViewController : UIViewController
    

@property (nonatomic          ) NSMutableArray        *tracks;
@property (nonatomic          ) NKTrack        *currentTrack;
@property (nonatomic          ) NSMutableArray        *nextTracks;
@property (nonatomic          ) NSMutableArray        *savedtracks;
@property (nonatomic, strong  ) NKTrackListPlayer    *trackListPlayer;
@property (nonatomic, strong) NKNapster *napster;

@property (nonatomic, weak) id<QueueDelegate> delegate;

@property (nonatomic          ) NSMutableArray        *queue;
@property PlayViewController *playVC;
@property NSInteger currentPlayItem;

//@property MusicHomeViewController *homeVC;

@end

NS_ASSUME_NONNULL_END
