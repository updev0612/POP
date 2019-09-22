//
//  PlayViewController.h
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <NapsterKit/NapsterKit.h>
#import "NKTrackListPlayer.h"
#import "MusicHomeViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PlayerSettingDelegate <NSObject>

-(void)add2PL:(NKTrack*)track;
-(void)add2Lib:(NKTrack*)track;
-(void)setting:(NKTrack*)track;

@end

@interface PlayViewController : UIViewController

@property (nonatomic, strong) NKNapster *napster;

@property (nonatomic          ) NSMutableArray        *tracks;
@property (nonatomic          ) NSMutableArray        *qtracks;
@property (nonatomic          ) NSMutableArray        *myLibrary;

@property MusicHomeViewController *HomeVC;

@property NSInteger catIndex;
@property NSString *subCode;
@property NSInteger currentItem;
@property NSInteger currentPlayItem;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic) NSMutableArray *imageArray;
@property BOOL isMiniPlayerClicked;
@property (nonatomic, weak) id<PlayerSettingDelegate> delegate;

@property (nonatomic          ) NSMutableArray        *queue;

@property (weak, nonatomic) IBOutlet UIView *playlistView;
@property (weak, nonatomic) IBOutlet UITableView *tblPlaylists;
- (IBAction)btnCloseClick:(id)sender;

- (void)setTrackListPlayer:(NKTrackListPlayer *)trackListPlayer;
- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval;
- (void) configureForPlayer;
- (void) addingNotifications;
//- (void) configureLevelsMeteringTimer;
@end

NS_ASSUME_NONNULL_END
