//
//  Add2PlaylistView.h
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NKNapster+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Add2PLDelegate <NSObject>

-(void) add2ExistPL:(NKTrack*)track;
-(void) createPL:(NKTrack*)track;

@end

@interface Add2PlaylistView : UIView

@property (nonatomic, weak) id<Add2PLDelegate> delegate;

@property NKTrack *track;

@end

NS_ASSUME_NONNULL_END
