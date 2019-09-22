//
//  POPPlayer.h
//  POP
//
//  Created by Ltiger on 9/3/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NapsterKit/NapsterKit.h>
#import "NKTrackListPlayer.h"


NS_ASSUME_NONNULL_BEGIN

@interface POPPlayer : NSObject

@property (nonatomic, weak) NKTrackListPlayer *trackListPlayer;

@property (nonatomic, weak) NSMutableArray *tracks;

@property (nonatomic, weak) NSMutableArray *queue;

- (void) nextPlay;

- (void) previousPlay;

- (void) play;

- (void) pause;



@end

NS_ASSUME_NONNULL_END
