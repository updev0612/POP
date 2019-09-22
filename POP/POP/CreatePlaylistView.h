//
//  CreatePlaylistView.h
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NKNapster+Extensions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CreatePLDelegate <NSObject>

- (void) createPL:(NSString *)name trackID:(NKTrack*)track;

@end

@interface CreatePlaylistView : UIView

@property (nonatomic, weak) id<CreatePLDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextField *txtPlaylist;

@property NKTrack *track;

@end

NS_ASSUME_NONNULL_END
