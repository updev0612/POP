//
//  MusicHomeViewController.m
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "MusicHomeViewController.h"
#import "NKTrackListPlayer.h"
#import "NKSNetworkActivityIndicatorController.h"
#import "NKSLoadingOverlay.h"
#import "NKAPI+Parsing.h"
#import "NKNapster+Extensions.h"
#import "AppDelegate.h"
#import "PlayViewController.h"
#import "YBRectConst.h"
#import "UIView+TYAlertView.h"
#import "TYAlertController+BlurEffects.h"
#import "ShareView.h"
#import "ViewController.h"
#import "PlayList.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Add2PlaylistView.h"
#import "CreatePlaylistView.h"
#import "QueueViewController.h"
#import "PlaylistView.h"
#import "CustomIOSAlertView.h"
#import "PlaylistCell.h"

#define NUMBER_OF_CONTEXT_SONGS     2


@interface MusicHomeViewController () <MBProgressHUDDelegate, Add2PLDelegate, CreatePLDelegate, QueueDelegate, SettingDelegate, UITableViewDelegate, UITableViewDataSource> {
    MBProgressHUD *HUD;
}

@property (weak, nonatomic) IBOutlet UIButton* previousButton;
@property (weak, nonatomic) IBOutlet UIButton* nextButton;
@property (weak, nonatomic) IBOutlet UIButton* playButton;
@property (weak, nonatomic) IBOutlet UISlider* playheadSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UILabel *trackTime;

@property (weak, nonatomic) IBOutlet UIImageView *artistImageView;

@property (weak, nonatomic) IBOutlet UILabel *lblTrackName;

@property (weak, nonatomic) IBOutlet UIScrollView *catScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *imgScrollView;

@property (weak, nonatomic) IBOutlet UILabel *lblArtist;

@property (weak, nonatomic) NSMutableArray *arrayArtistName;
@property (weak, nonatomic) NSMutableArray *arrayTrackName;
@property UIScrollView *innerScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *miniImage;
@property (weak, nonatomic) IBOutlet UIView *subCatView;

@property (nonatomic, strong) IBOutlet iCarousel *carousel;

@property (weak, nonatomic) IBOutlet UIView *imgHomeBanner;

@property NSMutableArray *playLists;

@property (weak, nonatomic    ) NKSLoadingOverlay      *loadingOverlay;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property CGPoint lastContentOffset;

@property (nonatomic, strong  ) NKTrackListPlayer    *trackListPlayer;

@property (nonatomic          ) NSMutableArray        *tracks;
@property (nonatomic          ) NSMutableArray        *qtracks;

@property (nonatomic          ) NSMutableArray        *myPlaylists;

@property (nonatomic          ) NSMutableArray        *subCategory;

@property (weak, nonatomic) IBOutlet UIView *maskView;

@property (nonatomic, readonly) NKTrackPlayer        *player;

@property (nonatomic, strong) NSMutableArray *items;

@property (weak, nonatomic) CAShapeLayer *subCatLayer;

@property (nonatomic) BOOL startFlag;

@property (nonatomic) CAGradientLayer *gradient;

@property (nonatomic) NSInteger subCatIndex;
@property BOOL wasBackground;

@property NSDate *start;
@property NSDate *medium;
@property NSDate *end;
@property BOOL isDoneLoading;
@property NSCache *imgCache;
@property NSCache *miniImgCache;
@property (weak, nonatomic) IBOutlet UIView *playlistView;
@property (weak, nonatomic) IBOutlet UITableView *tblPlaylists;
- (IBAction)btnCloseClick:(id)sender;

@end

@implementation MusicHomeViewController
@synthesize catScrollView, imgScrollView, lastContentOffset , napster, subCatView , carousel, items, imgHomeBanner, activityIndicator, subCode, subCatLayer;

#pragma mark - Initializing


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    self.imgHomeBanner.layer.masksToBounds = NO;
    self.imgHomeBanner.layer.shadowRadius  = 20.0f;
    self.imgHomeBanner.layer.shadowColor   = [UIColor colorWithRed:171.f/255.f green:183.f/255.f blue:193.f/255.f alpha:1.f].CGColor;
    self.imgHomeBanner.layer.shadowOffset  = CGSizeMake(0.0f, -10.0f);
    self.imgHomeBanner.layer.shadowOpacity = 0.1f;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeModal:) name:@"CloseModal" object:nil];

    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -10.0f, 0);
    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(self.imgHomeBanner.bounds, shadowInsets)];
    self.imgHomeBanner.layer.shadowPath    = shadowPath.CGPath;

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                            delegate:self
                                       delegateQueue:nil];

    if (self.trackListPlayer == nil) {

        self.trackListPlayer = [[NKTrackListPlayer alloc] initWithNapster:self.napster
                     containerID:nil
        andSequencingContextSize:NUMBER_OF_CONTEXT_SONGS];
//        [self loadMyMusic];
        self.startFlag = YES;
        self.start = [NSDate date];
        if (self.napster.isSessionOpen) {
            [self.napster refreshSessionWithCompletionHandler:^(NKSession *session, NSError *error) {
                if (!session) {
                    // ... some error happened
                    [self Toast:@"Session Error!"];
                }
                [self loadLibrary];
            }];
        }
        

//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//
//        });
        self.catIndex = 0;
        self.currentItem = 0;
        self.currentPlayItem = 0;
        self.subCatIndex = 0;
        self.wasBackground = NO;

        self.queue = [[NSMutableArray alloc] init];

        [self addNotificationObservers];
    } else {
        self.startFlag = NO;
        [self.maskView setHidden:YES];
//        self.carousel.currentItemIndex = self.currentItem;
//        self.items = NSMutableArray.new;
        for (int i = 0; i < self.tracks.count; i++)
        {
            [self->items addObject:@(i)];
        }
//        while (self.items.count < self.currentItem) {
//            [self insert];
//        }
        NSLog(@"%ld : %ld", (long)self.currentItem, (long)self.carousel.currentItemIndex);
        self->carousel.type = iCarouselTypeRotary;

        [self.carousel reloadData];
        if (!self.isMiniPlayerClicked) {
            [self.carousel scrollToItemAtIndex:self.currentItem animated:NO];
        }


//        [self loadMyMusic];
        NKTrack *track = self.trackListPlayer.currentTrack;
        [[self lblArtist] setText:track.artist.name];
        [[self lblTrackName] setText:track.name];
//
        [[self miniImage] setImage:[self.imageArray objectAtIndex:self.currentItem]];

        [self configureForPlayer];
        [self.activityIndicator setHidden:YES];

    }


    UIImage *thumb = [UIImage imageNamed:@"Ellipse"];
    [self.playheadSlider setThumbImage:thumb forState:UIControlStateNormal];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSliderTap:)];
    [self.playheadSlider addGestureRecognizer:tapGestureRecognizer];

    [self configCatScrollView];

    self.catScrollView.delegate = self;

}

#pragma mark - Adding Notification Observers

- (void) addNotificationObservers{

    [[NSNotificationCenter defaultCenter] addObserver:self

    selector:@selector(appDidEnterBackground:)

    name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self

    selector:@selector(appDidBecomeActive:)

    name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:NKNotificationPlaybackStateChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackDidChange:) name:NKNotificationCurrentTrackChanged object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackDurationDidChange:) name:NKNotificationCurrentTrackDurationChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playheadPositionDidChange:) name:NKNotificationPlayheadPositionChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tracksDidChange:) name:NKTrackListNotificationTracksChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackAmoundDownloadedDidChange:) name:NKNotificationCurrentTrackAmountDownloadedChanged object:nil];
}

#pragma mark - BackgroundPlaySetting

- (void)appDidEnterBackground:(NSNotification *)notification {
    
    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter
    sharedCommandCenter];
    
        [[remoteCommandCenter playCommand] addTarget:self
        action:@selector(playButtonTapped:)];
        [[remoteCommandCenter nextTrackCommand] addTarget:self
        action:@selector(next)];
        [[remoteCommandCenter previousTrackCommand] addTarget:self
        action:@selector(previous)];
        [[remoteCommandCenter togglePlayPauseCommand] addTarget:self
        action:@selector(playButtonTapped:)];
        [[remoteCommandCenter pauseCommand] addTarget:self
        action:@selector(pause)];
        
        remoteCommandCenter.previousTrackCommand.enabled = YES;
        remoteCommandCenter.nextTrackCommand.enabled = YES;
        self.wasBackground = YES;
    
    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary* newInfo = [NSMutableDictionary dictionary];
    
    NKTrack *currentTrack = self.trackListPlayer.currentTrack;
    NSInteger index = [self.tracks indexOfObject:currentTrack];
    
    NSString *albumID = currentTrack.album.ID;
    NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/500x500.jpg", albumID];
    NSURL *url = [NSURL URLWithString:path];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *imgAlbum = [[UIImage alloc] initWithData:data];
    
    NSNumber *headPos = [NSNumber numberWithDouble:self.trackListPlayer.trackPlayer.playheadPosition];
    if (currentTrack) {
        [newInfo setObject:currentTrack.name forKey:MPMediaItemPropertyTitle];
        [newInfo setObject:currentTrack.artist.name forKey:MPMediaItemPropertyArtist];
        [newInfo setObject:currentTrack.duration forKey:MPMediaItemPropertyPlaybackDuration];
        
    }
    
    if (headPos) {
        [newInfo setObject:headPos forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    }
    
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_0) {
        
        [remoteCommandCenter.changePlaybackPositionCommand setEnabled:true];
        [remoteCommandCenter.changePlaybackPositionCommand addTarget:self action:@selector(changedThumbSliderOnLockScreen:)];
    }
    if (imgAlbum) {
        MPMediaItemArtwork *media;
        if (@available(iOS 10.0, *)) {
            media = [[MPMediaItemArtwork alloc] initWithBoundsSize:imgAlbum.size requestHandler:^UIImage * _Nonnull(CGSize size) {
                return imgAlbum;
            }];
        } else {
            media = [[MPMediaItemArtwork alloc] initWithImage:imgAlbum];
        }
        [newInfo setObject:media forKey:MPMediaItemPropertyArtwork];
        
    }
    
    info.nowPlayingInfo = newInfo;
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
}

- (MPRemoteCommandHandlerStatus)changedThumbSliderOnLockScreen:(MPChangePlaybackPositionCommandEvent *)event
{
    // change position
    [self.trackListPlayer.trackPlayer seekTo:event.positionTime];
    
    return MPRemoteCommandHandlerStatusSuccess;
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter
    sharedCommandCenter];
    [[remoteCommandCenter playCommand] removeTarget:self
    action:@selector(playButtonTapped:)];
    [[remoteCommandCenter nextTrackCommand] removeTarget:self
    action:@selector(next)];
    [[remoteCommandCenter previousTrackCommand] removeTarget:self
    action:@selector(previous)];
    [[remoteCommandCenter togglePlayPauseCommand] removeTarget:self
    action:@selector(playButtonTapped:)];
    [[remoteCommandCenter pauseCommand] removeTarget:self
    action:@selector(pause)];
    [remoteCommandCenter.changePlaybackPositionCommand removeTarget:self action:@selector(changedThumbSliderOnLockScreen:)];
    remoteCommandCenter.previousTrackCommand.enabled = NO;
    remoteCommandCenter.nextTrackCommand.enabled = NO;
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
}

#pragma mark - SettingButtonAction

-(void)add2PL:(NKTrack*)track{
    Add2PlaylistView *addView = [Add2PlaylistView createViewFromNib];
    addView.track = track;
           // use UIView Category
    addView.delegate = self;
    [addView showInWindow];
}

-(void)add2Lib:(NKTrack*)track{
    NSMutableArray *tempTracks = [[NSMutableArray alloc] init];
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
    NSURL *url = [NSURL URLWithString: @"https://api.napster.com/v2.2/me/library/tracks?limit=50"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"POP/1.0(1)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"iOS 1.2.1" forHTTPHeaderField:@"NAPI-SDK"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Finishing");
        NSError *err;
        NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err){
            NSLog(@"fail:%@",err);
        }
        NSArray* tracks = [(NSDictionary*)trackJSON objectForKey: @"tracks"];
        
        if (!tracks) {
            NSLog(@"Error: no tracks");
            return;
        }
        for (NSDictionary *trackJson1 in tracks) {
            NSString *ID = trackJson1[@"id"];
            [tempTracks addObject:ID];
        }
        if ([tempTracks containsObject:track.ID]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self Toast:@"You've already added it to Library"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2LibFNotification" object:self];
                
            });
        } else {
            NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
            NSString *urlString = [NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/tracks?id=%@", track.ID];
            NSURL *url = [NSURL URLWithString: urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
            [request setValue:tokenString forHTTPHeaderField:@"Authorization"];
            

            [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self Toast:@"Added to Library"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2LibSNotification" object:self];
                });
            }] resume];
        }
    }] resume];
    
}

-(void)setting:(NKTrack*)track{
    ShareView *shareView = [ShareView createViewFromNib];
    shareView.track = track;
    shareView.delegate = self;
    [shareView showInWindow];
}


- (void)test{
    NSLog(@"Logging");
}

- (void)add2ExistPL:(NKTrack*)track{
    [self getPlaylists:track];
}
- (void)createPL:(NKTrack*)track{
    CreatePlaylistView *createView = [CreatePlaylistView createViewFromNib];
    createView.track = track;
           // use UIView Category
    createView.delegate = self;
    [createView showInWindow];
}

- (void)createPL:(NSString *)name trackID:(NKTrack*)track{
    [self createPlaylist:name trackID:track];
}


- (void) cellButtonClicked:(NKTrack*)track{
    [self settingBtnClick:track];
}

- (void) settingBtnClick:(NKTrack*)track{
    ShareView *shareView = [ShareView createViewFromNib];
    shareView.track = track;
    shareView.delegate = self;
    [shareView showInWindow];
}

-(void)add2Queue:(NKTrack *)track{
    
    
    if ([self.queue containsObject:track]) {
        [self Toast:@"You have already added it to Queue!"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2QFNotification" object:self];
    } else {
        [self.queue addObject:track];

        [self Toast:@"Added to Queue!"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2QSNotification" object:self];
    }
}

-(void) add2Playlist:(NKTrack *)track{
    Add2PlaylistView *addView = [Add2PlaylistView createViewFromNib];
    addView.track = track;
           // use UIView Category
    addView.delegate = self;
    [addView showInWindow];
}


#pragma mark - ReturnFromPlayVC

-(void)closeModal:(NSNotification *)notification{
    UIViewController *controller=(UIViewController *)notification.object;

    [controller dismissViewControllerAnimated:YES completion:^ {
        self.startFlag = NO;
        [self.maskView setHidden:YES];
        self.items = NSMutableArray.new;
        for (int i = 0; i < self.tracks.count; i++)
        {
            [self->items addObject:@(i)];
        }

        NSLog(@"%ld : %ld", (long)self.currentItem, (long)self.carousel.currentItemIndex);
        [self.carousel reloadData];
        if ([self.tracks.firstObject isEqual:self.qtracks.firstObject] && [self.tracks.lastObject isEqual:self.qtracks.lastObject]) {
            [self.carousel scrollToItemAtIndex:self.currentPlayItem animated:YES];
        }
        


        NKTrack *track = self.trackListPlayer.trackPlayer.currentTrack;
        [[self lblArtist] setText:track.artist.name];
        [[self lblTrackName] setText:track.name];
        NSString *albumID = track.album.ID;
        NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/300x300.jpg", albumID];
        NSURL *url = [NSURL URLWithString:path];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *imgAlbum = [[UIImage alloc] initWithData:data];

        [[self miniImage] setImage:imgAlbum];
        [self.activityIndicator setHidden:YES];
        self.wasBackground = NO;
        [self addNotificationObservers];
        [self configureForPlayer];
    }];

}


-(void)getPlaylists:(NKTrack *)track{
    self.playLists = [[NSMutableArray alloc] init];
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
    NSURL *url = [NSURL URLWithString: @"https://api.napster.com/v2.2/me/library/playlists?sort=alpha_asc"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"POP/1.0(1)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"iOS 1.2.1" forHTTPHeaderField:@"NAPI-SDK"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Finishing");
        NSError *err;
        NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err){
            NSLog(@"fail:%@",err);
        }
        NSArray* playlists = [(NSDictionary*)trackJSON objectForKey: @"playlists"];
        
        if (!playlists) {
            NSLog(@"Error: no tracks");
            return;
        }
        for (NSDictionary *listJson in playlists) {
            NSString *ID = listJson[@"id"];
            NSString *name = listJson[@"name"];
            PlayList *plist = PlayList.new;
            plist.ID = ID;
            plist.name = name;
            [self.playLists addObject:plist];
        }
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.tblPlaylists reloadData];
            [self.playlistView setHidden:NO];
            [self.maskView setHidden:NO];
        });
        
        
    }] resume];
}

#pragma mark CreatePlaylist

-(void)createPlaylist:(NSString*)name trackID:(NKTrack *)track{
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
            
    NSString *urlString = [NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/playlists"];
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
//    NKTrack *track = [self.tracks objectAtIndex:self.carousel.currentItemIndex];
    
    NSDictionary *jsonBodyDict = @{
        @"appName": @"POP",
        @"playlists": @{
            @"name": name,
            @"privacy": @"public",
            @"tracks": @[@{
                @"id": track.ID
            }]
            
        }
        
    };
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *str = [[NSString alloc] initWithData:jsonBodyData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",str);
    [request setHTTPBody:jsonBodyData];

    [request setURL:url];
    [request setHTTPMethod:@"POST"];
//    [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *err;
        NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err){
            NSLog(@"fail:%@",err);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self Toast:@"Added to Playlist"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2PLSNotification" object:self];
        });
    }] resume];
    
}

-(void)addTrack2PlayList:(NSString*)playListID trackid:(NKTrack *)track{
    NSLog(@"%@", playListID);
    NSMutableArray *tempTracks = [[NSMutableArray alloc] init];
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
    NSString *urlString = [NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/playlists/%@/tracks?limit=50", playListID];
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"POP/1.0(1)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"iOS 1.2.1" forHTTPHeaderField:@"NAPI-SDK"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Finishing");
        NSError *err;
        NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err){
            NSLog(@"fail:%@",err);
        }
        NSArray* tracks = [(NSDictionary*)trackJSON objectForKey: @"tracks"];
        
        if (!tracks) {
            NSLog(@"Error: no tracks");
            return;
        }
        for (NSDictionary *trackJson1 in tracks) {
            NSString *ID = trackJson1[@"id"];
            [tempTracks addObject:ID];
        }
        if ([tempTracks containsObject:track.ID]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self Toast:@"You've already added it to this playlist"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2PLFNotification" object:self];
            });
        } else {
            NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
        
            NSString *urlString = [NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/playlists/%@/tracks", playListID];
            NSURL *url = [NSURL URLWithString: urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            
//            NSMutableData *body = [NSMutableData data];
            
            // text parameter
//            NSString *dataString = @"{'tracks':{'id':'tra.5156528'}}";
//            [body appendData:[[NSString stringWithString:dataString] dataUsingEncoding:NSUTF8StringEncoding]];
            
            
            NSDictionary *jsonBodyDict = @{@"tracks":@{@"id":track.ID}};
            NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:NSJSONWritingPrettyPrinted error:nil];
            [request setHTTPBody:jsonBodyData];
            // set request body
//            [request setHTTPBody:body];

            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
            [request setValue:tokenString forHTTPHeaderField:@"Authorization"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

            [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//                NSError *err;
//                NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
//                if (err){
//                    NSLog(@"fail:%@",err);
//                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self Toast:@"Added to Playlist"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2PLSNotification" object:self];
                });
            }] resume];
        }
    }] resume];
}

-(void)add2Library:(NKTrack *)track{
    
    NSMutableArray *tempTracks = [[NSMutableArray alloc] init];
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
    NSURL *url = [NSURL URLWithString: @"https://api.napster.com/v2.2/me/library/tracks?limit=50"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"POP/1.0(1)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"iOS 1.2.1" forHTTPHeaderField:@"NAPI-SDK"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];

    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Finishing");
        NSError *err;
        NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err){
            NSLog(@"fail:%@",err);
        }
        NSArray* tracks = [(NSDictionary*)trackJSON objectForKey: @"tracks"];
        
        if (!tracks) {
            NSLog(@"Error: no tracks");
            return;
        }
        for (NSDictionary *trackJson1 in tracks) {
            NSString *ID = trackJson1[@"id"];
            [tempTracks addObject:ID];
        }
        if ([tempTracks containsObject:track.ID]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self Toast:@"You've already added it to Library"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2LibFNotification" object:self];
            });
        } else {
            NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
            NSString *urlString = [NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/tracks?id=%@", track.ID];
            NSURL *url = [NSURL URLWithString: urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
            [request setValue:tokenString forHTTPHeaderField:@"Authorization"];
            

            [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self Toast:@"Added to Library"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2LibSNotification" object:self];
                });
            }] resume];
        }
    }] resume];
    
    
    
}

-(void)Toast:(NSString*)msg{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];

    // Set the text mode to show only text.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(msg, @"HUD message title");
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);

    [hud hideAnimated:YES afterDelay:1.5f];
}

#pragma mark UIOperation

-(void) startLoading{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
    [self.maskView setHidden:NO];
}

-(void) stopLoading{
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
    [self.maskView setHidden:YES];
}

-(void)configCatScrollView{
    
    NSArray *category = [NSArray arrayWithObjects:@"My Music",@"Top Charts",@"Trending", @"Top Picks" ,@"Moods" , @"Activities", @"Featured", @"Themes", @"Decades", @"Napster20" , @"POP" , @"Rock", @"Alternative" , @"Hip-Hop", @"R&B", @"Country" , @"Jazz", @"Electronic" , @"Latin", @"World" , @"Reggae", @"Classical", @"Oldies", @"New Age", @"Christian", @"Blues", @"Metal", @"Folk", @"Easy Listening", @"Children", @"Soundtracks", @"Musicals", @"Comedy", @"Spoken Word",nil];
    NSMutableArray *buttons = [NSMutableArray alloc];
    int xCoord=0;
    int yCoord=0;
    int buttonWidth=100;
    int buttonHeight=31;
    int buffer = 10;
    NSInteger i;
    for (i = 0; i < category.count; i++)
    {
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aButton.frame     = CGRectMake(xCoord, yCoord,buttonWidth,buttonHeight );
        [aButton addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
        if (i==self.catIndex) {
            [aButton setBackgroundImage:[UIImage imageNamed:@"CategoryHighlight"] forState:UIControlStateNormal];
            [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [aButton setBackgroundImage:[UIImage imageNamed:@"Category"] forState:UIControlStateNormal];
            [aButton setTitleColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0] forState:UIControlStateNormal];
        }
        
        [aButton setTitle:[category objectAtIndex:i] forState:UIControlStateNormal];
        [aButton setFont:[UIFont systemFontOfSize:12]];
        [aButton setContentMode:UIViewContentModeScaleAspectFit];
        aButton.tag = 100 + i;
        
        [catScrollView addSubview:aButton];

        xCoord += buttonWidth + buffer;
    }
    [catScrollView setContentSize:CGSizeMake(xCoord, 31)];
    [catScrollView setAlwaysBounceVertical:NO];
    [catScrollView setContentMode:UIViewContentModeScaleAspectFit];
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark ButtonSetting


-(IBAction)clicked:(UIButton *) sender {

    long type = (long)sender.tag/100;
    long identifier = (long)sender.tag - type *100;
    if (type == 2) {
        NSLog(@"%ld th IMGbutton clicked",identifier);
        self.currentItem = self.carousel.currentItemIndex;
        self.currentPlayItem = self.carousel.currentItemIndex;
        self.isMiniPlayerClicked = NO;
        
        if (self.isMiniPlayerClicked) {
            if (self.trackListPlayer.currentTrack){

        
            } else {
                NKTrack *track = [self.tracks objectAtIndex:self.currentPlayItem];
                self.qtracks = NSMutableArray.new;
                [self setQtracks:[self.tracks mutableCopy]];
                [self.trackListPlayer playTrack:track];
            }
        } else {
            NKTrack *track = [self.tracks objectAtIndex:self.currentPlayItem];
            self.qtracks = NSMutableArray.new;
            [self setQtracks:[self.tracks mutableCopy]];
            [self.trackListPlayer playTrack:track];
        }
        [self configureForPlayer];
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        PlayViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"PlayVC"];
        
        vc.napster = self.napster;
        
        
        vc.isMiniPlayerClicked = self.isMiniPlayerClicked;
        vc.napster = self.napster;
        vc.catIndex = self.catIndex;
        vc.subCode = self.subCode;
        vc.currentItem = self.currentItem;
        vc.currentPlayItem = self.currentPlayItem;
        vc.queue = NSMutableArray.new;
        vc.queue = [self.queue mutableCopy];
        vc.qtracks = [self.qtracks mutableCopy];
        vc.tracks = [self.tracks mutableCopy];
        vc.HomeVC = self;
        vc.myLibrary = NSMutableArray.new;
        vc.myLibrary = [self.myLibrary mutableCopy];
        NSLog(@"%ld:  : %ld", (long)vc.currentItem,(long)self.currentItem);
        vc.imageArray = [self.imageArray mutableCopy];
        [vc setTrackListPlayer: self.trackListPlayer];
        [self.napster.notificationCenter removeObserver:self];

        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSLog(@"Count_____________%ld", (long)vc.queue.count);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeModal:) name:@"CloseModal" object:nil];
        
        [self presentViewController:vc animated:YES completion:^{
            
            
        }];
        
//        [self performSegueWithIdentifier:@"SegueToPlay" sender:self];
    } else if (type == 3){
        NSLog(@"%ld th Settingbutton clicked",identifier);
        [self settingBtnClick:[self.tracks objectAtIndex:self.currentItem]];
    } else if (type == 4) {
        self.subCatIndex = identifier;
        if (self.catIndex == 0) {
            
           [self loadLibraryTracks:identifier];
            
        } else if (self.catIndex == 1){
            self.subCategory = [[NSArray arrayWithObjects:@"US",@"GB",@"MX", @"DK" ,@"FR" , @"DE" ,nil] mutableCopy];
            [self fetchTracksUsingJSON:30 countryCode:[self.subCategory objectAtIndex:identifier] rangeOfTime:@"week"];
            
            
        } else{
            [self loadTagTracks:[[self.myPlaylists objectAtIndex:identifier] ID] limits:30 rangeOfTime:@"week"];
            
            
        }
        
    }
    else {
        NSLog(@"%ld th Catbutton clicked",identifier);
        self.subCatIndex = -1;
        for (UIButton *button in self.catScrollView.subviews) {
            if (button.tag == sender.tag) {
                [button setBackgroundImage:[UIImage imageNamed:@"CategoryHighlight"] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal ];
                self.catIndex = identifier;
            } else {
                if (button.tag/100 == 1) {
                    [button setBackgroundImage:[UIImage imageNamed:@"Category"] forState:UIControlStateNormal];
                    [button setTitleColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0] forState:UIControlStateNormal ];
                }
            }
        }
        
        if (identifier == 1) {
            
            for (UIButton *button in self.catScrollView.subviews) {
                if (button.tag == sender.tag) {
                    CGRect frame = [self.view convertRect:button.frame fromView:self.catScrollView];
                    self.subCategory = [[NSArray arrayWithObjects:@"US",@"UK",@"MEXICO", @"DENMARK" ,@"FRANCE" , @"GERMANY" ,nil] mutableCopy];
                    [self configSubCatalog:identifier];
                    
                }
            }
            
            
        } else if (identifier == 2){
            
            [self loadTagPlaylist:@"tag.152196420"];
            
            
        } else if (identifier == 0) {
            if (self.napster.isSessionOpen) {
                [self.napster refreshSessionWithCompletionHandler:^(NKSession *session, NSError *error) {
                    if (!session) {
                        // ... some error happened
                        [self Toast:@"Session Error!"];
                    }
                    [self loadLibrary];
                }];
            }
        } else if (identifier == 3) {
            //top picks
            [self loadTagPlaylist:@"tag.198467121"];
        } else if (identifier ==4) {
            //moods
            [self loadTagPlaylist:@"tag.156763216"];
        } else if (identifier ==5) {
            //Activities
            [self loadTagPlaylist:@"tag.156763215"];
        } else if (identifier ==6) {
            //Featured
            [self loadTagPlaylist:@"tag.156763213"];
        } else if (identifier ==7) {
            //Themes
            [self loadTagPlaylist:@"tag.156763217"];
        } else if (identifier ==8) {
            //Decades
            [self loadTagPlaylist:@"tag.156763218"];
        } else if (identifier ==9) {
            //Napster20
            [self loadTagPlaylist:@"tag.382553059"];
        }
        else if (identifier == 10) {
            //POP
            [self loadGenrePriMedia:@"g.115"];
        }
        else if (identifier == 11) {
            //Rock
            [self loadGenrePriMedia:@"g.5"];
        }
        else if (identifier == 12) {
            //Alternative
            [self loadGenrePriMedia:@"g.33"];
        }
        else if (identifier == 13) {
            //Hip-Hop
            [self loadGenrePriMedia:@"g.146"];
        }
        else if (identifier == 14) {
            //R&B
            [self loadGenrePriMedia:@"g.194"];
        }
        else if (identifier == 15) {
            //Country
            [self loadGenrePriMedia:@"g.407"];
        }
        else if (identifier == 16) {
            //Jazz
            [self loadGenrePriMedia:@"g.299"];
        }
        else if (identifier == 17) {
            //Electronic
            [self loadGenrePriMedia:@"g.71"];
        }
        else if (identifier == 18) {
            //Latin
            [self loadGenrePriMedia:@"g.510"];
        }
        else if (identifier == 19) {
            //World
            [self loadGenrePriMedia:@"g.488"];
        }
        else if (identifier == 20) {
            //Reggae
            [self loadGenrePriMedia:@"g.383"];
        }
        else if (identifier == 21) {
            //Classical
            [self loadGenrePriMedia:@"g.21"];
        }
        else if (identifier == 22) {
            //Oldies
            [self loadGenrePriMedia:@"g.4"];
        }
        else if (identifier == 23) {
            //New Age
            [self loadGenrePriMedia:@"g.453"];
        }
        else if (identifier == 24) {
            //Christian
            [self loadGenrePriMedia:@"g.75"];
        }
        else if (identifier == 25) {
            //Blues
            [self loadGenrePriMedia:@"g.453"];
        }
        else if (identifier == 26) {
            //Metal
            [self loadGenrePriMedia:@"g.394"];
        }
        else if (identifier == 27) {
            //Folk
            [self loadGenrePriMedia:@"g.446"];
        }
        else if (identifier == 28) {
            //Vocal/Easy Listening
            [self loadGenrePriMedia:@"g.69"];
        }
        else if (identifier == 29) {
            //Children
            [self loadGenrePriMedia:@"g.470"];
        }
        else if (identifier == 30) {
            //Soundtracks
            [self loadGenrePriMedia:@"g.197"];
        }
        else if (identifier == 31) {
            //Musicals
            [self loadGenrePriMedia:@"g.304"];
        }
        else if (identifier == 32) {
            //Comedy
            [self loadGenrePriMedia:@"g.18"];
        }
        else if (identifier == 33) {
            //Spoken Word
            [self loadGenrePriMedia:@"g.471"];
        }
    }
    
}
#pragma mark prepareForPlayPC

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"SegueToPlay"]){
        PlayViewController *vc = (PlayViewController*)segue.destinationViewController;

        if (self.isMiniPlayerClicked) {
            if (self.trackListPlayer.currentTrack){

        
            } else {
                NKTrack *track = [self.tracks objectAtIndex:self.currentItem];
                self.qtracks = NSMutableArray.new;
                [self setQtracks:[self.tracks mutableCopy]];
                [self.trackListPlayer playTrack:track];
            }
        } else {
            NKTrack *track = [self.tracks objectAtIndex:self.currentItem];
            self.qtracks = NSMutableArray.new;
            [self setQtracks:[self.tracks mutableCopy]];
            [self.trackListPlayer playTrack:track];
        }
        
        vc.isMiniPlayerClicked = self.isMiniPlayerClicked;
        vc.napster = self.napster;
        vc.catIndex = self.catIndex;
        vc.subCode = self.subCode;
        vc.delegate = self;
        vc.currentItem = self.currentItem;
        vc.queue = NSMutableArray.new;
        vc.queue = [self.queue mutableCopy];
        vc.qtracks = [self.qtracks mutableCopy];
        vc.tracks = [self.tracks mutableCopy];
        vc.HomeVC = self;
        NSLog(@"%ld:  : %ld", (long)vc.currentItem,(long)self.currentItem);
        vc.imageArray = [self.imageArray mutableCopy];
        [vc setTrackListPlayer: self.trackListPlayer];
        [self.napster.notificationCenter removeObserver:self];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSLog(@"Count_____________%ld", (long)vc.queue.count);
    }
}

#pragma mark Fetching Data

-(void)loadLibrary{
    
    self.myPlaylists = [NSMutableArray new];
//    [[self subCategory] removeAllObjects];
    self.subCategory = [NSMutableArray new];
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
    
    NSURL *url = [NSURL URLWithString: @"https://api.napster.com/v2.2/me/library/playlists?limit=10"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"POP/1.0(1)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"iOS 1.2.1" forHTTPHeaderField:@"NAPI-SDK"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];
    __weak typeof (self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSUInteger responseStatusCode = [httpResponse statusCode];

        if (responseStatusCode < 200 || responseStatusCode > 202) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self stopLoading];
//                });
                [weakSelf loadLibrary];
            });
        } else {
            
            NSLog(@"Finishing");
            NSError *err;
            NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            if (err){
                NSLog(@"fail:%@",err);
            }
            NSArray* playlists = [(NSDictionary*)trackJSON objectForKey: @"playlists"];
            
            if (!playlists) {
                NSLog(@"Error: no artists");
                NSLog(@"Response Code:%lu", (unsigned long)responseStatusCode);
                return;
            }
            [self.subCategory addObject:@"All"];
            [self.myPlaylists addObject:NKArtistStub.new];
            for (NSDictionary *playlistJson in playlists) {
                NSString *name = playlistJson[@"name"];
                NSString *ID = playlistJson[@"id"];
                NKArtistStub *artist = [[NKArtistStub alloc] initWithID:ID name:name];
                if (artist != nil) {
                    [self.myPlaylists addObject:artist];
                    [self.subCategory addObject:artist.name];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.startFlag) {
                    [self loadLibraryTracks:0];
                    [self configSubCatalog:0];
                    self.startFlag = NO;
                } else {
                    [self configSubCatalog:self.catIndex];
                }
                
            });
        }
    }] resume];
}


-(void)loadTagPlaylist:(NSString*)tagID{
    
    self.myPlaylists = [NSMutableArray new];
//    [[self subCategory] removeAllObjects];
    self.subCategory = [NSMutableArray new];
    NSString *urlString =[NSString stringWithFormat: @"https://api.napster.com/v2.2/tags/%@/playlists?apikey=OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4",tagID];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSUInteger responseStatusCode = [httpResponse statusCode];

        if (responseStatusCode < 200 || responseStatusCode > 202) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                [weakSelf loadLibrary];
            });
        } else {
            NSLog(@"Finishing");
            NSError *err;
            NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            if (err){
                NSLog(@"fail:%@",err);
            }
            NSArray* playlists = [(NSDictionary*)trackJSON objectForKey: @"playlists"];
            
            if (!playlists) {
                NSLog(@"Error: no playlists");
                return;
            }
            for (NSDictionary *playlistJson in playlists) {
                NSString *name = [playlistJson[@"name"] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                 
                NSString *ID = playlistJson[@"id"];
                PlayList *playlist = PlayList.new;
                playlist.name = name;
                playlist.ID = ID;
                if (playlist != nil) {
                    [self.myPlaylists addObject:playlist];
                    [self.subCategory addObject:playlist.name];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{

                [self configSubCatalog:self.catIndex];
                
            });
        }
    }] resume];
}

-(void)loadGenrePriMedia:(NSString*)genreID{
    
    self.myPlaylists = [NSMutableArray new];
//    [[self subCategory] removeAllObjects];
    self.subCategory = [NSMutableArray new];
    NSString *urlString =[NSString stringWithFormat: @"https://api.napster.com/v2.2/genres/%@/posts?apikey=OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4&limit=100",genreID];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSUInteger responseStatusCode = [httpResponse statusCode];

        if (responseStatusCode < 200 || responseStatusCode > 202) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                [weakSelf loadLibrary];
            });
        } else {
            NSLog(@"Finishing");
            NSError *err;
            NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            if (err){
                NSLog(@"fail:%@",err);
            }
            NSArray* posts = [(NSDictionary*)trackJSON objectForKey: @"posts"];
            
            if (!posts) {
                NSLog(@"Error: no posts");
                return;
            }
            for (NSDictionary *postJson in posts) {
                NSString *name = [postJson[@"name"] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                NSString *ID = postJson[@"primaryMedia"];
//                NSArray *array = [ID componentsSeparatedByString:@"."];
//                NSString *prefix = [array objectAtIndex:0];
                if ([name isEqualToString:@"New Music"]) {
                    continue;
                }
                
                PlayList *playlist = PlayList.new;
                playlist.name = name;
                playlist.ID = ID;
                if (playlist != nil) {
                    [self.myPlaylists addObject:playlist];
                    [self.subCategory addObject:playlist.name];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{

                [self configSubCatalog:self.catIndex];
                
            });
        }
    }] resume];
}


-(void)loadTagTracks:(NSString*)tagID limits:(NSInteger)limitNum rangeOfTime:(NSString *)range{
    [self startLoading];
    self.currentItem = 0;
    NSArray *array = [tagID componentsSeparatedByString:@"."];
    NSString *prefix = [array objectAtIndex:0];
    NSString *urlString;
    if ([prefix isEqualToString:@"pp"]) {
        urlString =[NSString stringWithFormat: @"http://api.napster.com/v2.2/playlists/%@/tracks?apikey=OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4&limit=100",tagID];
    } else {
        urlString =[NSString stringWithFormat: @"http://api.napster.com/v2.2/albums/%@/tracks?apikey=OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4&limit=100",tagID];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) weakSelf = self;
    
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSUInteger responseStatusCode = [httpResponse statusCode];

        if (responseStatusCode < 200 || responseStatusCode > 202) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                [weakSelf loadLibrary];
            });
        } else {
            NSLog(@"Finishing");
            NSError *err;
            NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            if (err){
                NSLog(@"fail:%@",err);
            }

            NSArray* tracks = [(NSDictionary*)trackJSON objectForKey: @"tracks"];
            
            if (!tracks) {
                NSLog(@"Error: no tracks");
                return;
            }
            if (tracks.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopLoading];
                    [self Toast:@"No Tracks!"];
                    return;
                    
                });
            } else {
                self.tracks = [[NSMutableArray alloc] init];
                self.currentItem = 0;
                for (NSDictionary *trackJson1 in tracks) {
                    
                    NSString *name = trackJson1[@"name"];
                    NSString *ID = trackJson1[@"id"];
                    NSURL *sampleURL = trackJson1[@"href"];
                    NSNumber *duration = trackJson1[@"playbackSeconds"];
                    NSString *artistName = trackJson1[@"artistName"];
                    NSString *artistId = trackJson1[@"artistId"];
                    NSString *albumName = trackJson1[@"albumName"];
                    NSString *albumId = trackJson1[@"albumId"];
                    NKArtistStub *artist = [[NKArtistStub alloc] initWithID:artistId name:artistName];
                    NKAlbumStub *album = [[NKAlbumStub alloc] initWithID:albumId name:albumName];
                    NSArray *formats = [trackJson1 objectForKey:@"formats"];
                    if (formats.count == 0) {
                        continue;
                    }
                    NSMutableArray<NKAudioFormat *> *supportedAudioFormats = NSMutableArray.new;
                    for (NSDictionary *formatDict in formats) {
                        NSInteger te = [formatDict[@"bitrate"] integerValue];
                        NSInteger bitrate = te;
                        NKAudioFormat *audioformat= [NKAudioFormat AAC192];
                        if (bitrate == 192) {
                            audioformat = [NKAudioFormat AAC192];
                        } else if (bitrate==320){
                            audioformat = [NKAudioFormat AAC320];
                        } else if (bitrate == 64){
                            audioformat = [NKAudioFormat AACPlus64];
                        }
                        [supportedAudioFormats addObject:audioformat];
                    }
                    NKTrack *track = [[NKTrack alloc] initWithID:ID name:name sampleURL:sampleURL duration:duration artist:artist album:album supportedAudioFormats:supportedAudioFormats];
                    if (track != nil) {
                        [self.tracks addObject:track];
                    }
                }
                
                [self setTracks: [self.tracks mutableCopy]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isDoneLoading = false;
                    self.items = [NSMutableArray array];
                    self.imageArray = [NSMutableArray array];
                    NSDate *tem1 = [NSDate date];
                    NSTimeInterval executionTime = [tem1 timeIntervalSinceDate:self.medium];
                    NSLog(@"tem1 = %f", executionTime);
                    
                    
                    for (int i = 0; i < self.tracks.count; i++)
                    {
                        [self->items addObject:@(i)];
                    }
                    self->carousel.type = iCarouselTypeRotary;
                    
                    [self redrawSubCatalog:self.catIndex];
                    [self stopLoading];
                    [self configurePlayheadSlider];
                    [self->carousel reloadData];
                    if ([self.tracks.firstObject isEqual:self.qtracks.firstObject] && [self.tracks.lastObject isEqual:self.qtracks.lastObject]) {
                        [self.carousel scrollToItemAtIndex:self.currentPlayItem animated:YES];
                    } else {
                        [self.carousel scrollToItemAtIndex:0 animated:YES];
                    }
                    
                    self.isDoneLoading = true;
                    self.subCode = tagID;
                });
            }
        }
    }] resume];
}


-(void) loadLibraryTracks:(NSInteger) index{
    [self startLoading];
    self.tracks = [[NSMutableArray alloc] init];
    NSMutableArray *tempTracks = [[NSMutableArray alloc] init];
    self.currentItem = 0;

    NSString *urlString = [[NSString alloc] init];
    if (index == 0) {
        urlString = @"https://api.napster.com/v2.2/me/library/tracks?limit=100";
    } else {
        NKArtistStub *artist = [self.myPlaylists objectAtIndex:index];
        NSString *ID = artist.ID;
        urlString =[NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/playlists/%@/tracks?limit=100", ID];
    }

    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];


    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"POP/1.0(1)" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"iOS 1.2.1" forHTTPHeaderField:@"NAPI-SDK"];
    [request setValue:tokenString forHTTPHeaderField:@"Authorization"];
    __weak typeof (self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSUInteger responseStatusCode = [httpResponse statusCode];
        if (responseStatusCode < 200 || responseStatusCode > 202) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                [weakSelf loadLibrary];
            });
        } else {
            NSLog(@"Finishing");
            NSError *err;
            NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
            if (err){
                NSLog(@"fail:%@",err);
            }
            
            NSArray* tracks = [(NSDictionary*)trackJSON objectForKey: @"tracks"];

            if (!tracks) {
                NSLog(@"Error: no tracks");
                return;
            }
            if (tracks.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopLoading];
                    [self Toast:@"No Tracks!"];
                    return;
                    
                });
            }
            for (NSDictionary *trackJson1 in tracks) {

                NSString *name = trackJson1[@"name"];
                NSString *ID = trackJson1[@"id"];
                NSURL *sampleURL = trackJson1[@"href"];
                NSNumber *duration = trackJson1[@"playbackSeconds"];
                NSString *artistName = trackJson1[@"artistName"];
                NSString *artistId = trackJson1[@"artistId"];
                NSString *albumName = trackJson1[@"albumName"];
                NSString *albumId = trackJson1[@"albumId"];
                NKArtistStub *artist = [[NKArtistStub alloc] initWithID:artistId name:artistName];
                NKAlbumStub *album = [[NKAlbumStub alloc] initWithID:albumId name:albumName];
                NSArray *formats = [trackJson1 objectForKey:@"formats"];
                if (formats.count == 0) {
                    continue;
                }
                NSMutableArray<NKAudioFormat *> *supportedAudioFormats = NSMutableArray.new;
                for (NSDictionary *formatDict in formats) {
                    
                    NSInteger te = [formatDict[@"bitrate"] integerValue];
                    NSInteger bitrate = te;
                    NKAudioFormat *audioformat= [NKAudioFormat AAC192];
                    if (bitrate == 192) {
                        audioformat = [NKAudioFormat AAC192];
                    } else if (bitrate==320){
                        audioformat = [NKAudioFormat AAC320];
                    } else if (bitrate == 64){
                        audioformat = [NKAudioFormat AACPlus64];
                    }
                    [supportedAudioFormats addObject:audioformat];
                }
                NKTrack *track = [[NKTrack alloc] initWithID:ID name:name sampleURL:sampleURL duration:duration artist:artist album:album supportedAudioFormats:supportedAudioFormats];
                if (track != nil) {
                    [tempTracks addObject:track];
                }
            }
            self.tracks= [tempTracks mutableCopy];
            if (index == 0) {
                self.myLibrary = NSMutableArray.new;
                self.myLibrary = [tempTracks mutableCopy];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.items = [NSMutableArray array];
                for (int i = 0; i < self.tracks.count; i++)
                {
                    [self->items addObject:@(i)];
                }
                
                self->carousel.type = iCarouselTypeRotary;
                [self stopLoading];
                [self->carousel reloadData];
                [self configurePlayheadSlider];
                [self redrawSubCatalog:self.catIndex];
                if ([self.tracks.firstObject isEqual:self.qtracks.firstObject] && [self.tracks.lastObject isEqual:self.qtracks.lastObject]) {
                    [self.carousel scrollToItemAtIndex:self.currentPlayItem animated:YES];
                } else {
                    [self.carousel scrollToItemAtIndex:0 animated:YES];
                }
                
        //        self.subCode = country;
            });
        }
        }] resume];
   
}

-(void)fetchTracksUsingJSON:(NSInteger)limitNum countryCode:(NSString *)country rangeOfTime:(NSString *)range{
    [self startLoading];
    self.tracks = [[NSMutableArray alloc] init];
    self.currentItem = 0;
    NSString *urlString =[NSString stringWithFormat: @"http://api.napster.com/v2.2/tracks/top?apikey=OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4&range=%@&limit=100&catalog=%@",range,country];
    NSURL *url = [NSURL URLWithString:urlString];
    __weak typeof (self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData* _Nullable data,NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSUInteger responseStatusCode = [httpResponse statusCode];
        if (responseStatusCode < 200 && responseStatusCode > 202) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                [weakSelf loadLibrary];
            });
        } else {
        NSLog(@"Finishing");
        NSError *err;
        NSArray *trackJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        if (err){
            NSLog(@"fail:%@",err);
        }
        NSMutableDictionary *tracksDict;
        NSArray* tracks = [(NSDictionary*)trackJSON objectForKey: @"tracks"];
        
        if (!tracks) {
            NSLog(@"Error: no tracks");
            return;
        }
        if (tracks.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopLoading];
                [self Toast:@"No Tracks!"];
                return;
                
            });
        }
        for (NSDictionary *trackJson1 in tracks) {
            
            NSString *name = trackJson1[@"name"];
            NSString *ID = trackJson1[@"id"];
            NSURL *sampleURL = trackJson1[@"href"];
            NSNumber *duration = trackJson1[@"playbackSeconds"];
            NSString *artistName = trackJson1[@"artistName"];
            NSString *artistId = trackJson1[@"artistId"];
            NSString *albumName = trackJson1[@"albumName"];
            NSString *albumId = trackJson1[@"albumId"];
            NKArtistStub *artist = [[NKArtistStub alloc] initWithID:artistId name:artistName];
            NKAlbumStub *album = [[NKAlbumStub alloc] initWithID:albumId name:albumName];
            NSArray *formats = [trackJson1 objectForKey:@"formats"];
            if (formats.count == 0) {
                continue;
            }
            NSMutableArray<NKAudioFormat *> *supportedAudioFormats = NSMutableArray.new;
            BOOL isAvailable = YES;
            for (NSDictionary *formatDict in formats) {
                NSString *codec = formatDict[@"name"];
                NSInteger te = [formatDict[@"bitrate"] integerValue];
                NSInteger bitrate = te;
                NKAudioFormat *audioformat= [NKAudioFormat AAC192];
                if (bitrate == 192) {
                    audioformat = [NKAudioFormat AAC192];
                } else if (bitrate==320){
                    audioformat = [NKAudioFormat AAC320];
                } else if (bitrate == 64){
                    audioformat = [NKAudioFormat AACPlus64];
                } else {
                    isAvailable = NO;
                    break;
                }
                if (audioformat) {
                    [supportedAudioFormats addObject:audioformat];
                }
                
            }
            if (!isAvailable) {
                continue;
            }
            NKTrack *track = [[NKTrack alloc] initWithID:ID name:name sampleURL:sampleURL duration:duration artist:artist album:album supportedAudioFormats:supportedAudioFormats];
            if (track != nil) {
                [self.tracks addObject:track];
            }
        }
        
        [self setTracks: [self.tracks mutableCopy]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isDoneLoading = false;
            self.items = [NSMutableArray array];
            self->carousel.type = iCarouselTypeRotary;
            
            self.subCategory = [[NSArray arrayWithObjects:@"US",@"UK",@"MEXICO", @"DENMARK" ,@"FRANCE" , @"GERMANY" ,nil] mutableCopy];
            for (int i = 0; i < self.tracks.count; i++)
            {
                [self->items addObject:@(i)];

            }
            [self redrawSubCatalog:self.catIndex];
            self.subCode = country;
            [self stopLoading];
            [self configurePlayheadSlider];
            [self->carousel reloadData];
            [self.carousel setCurrentItemIndex:0];
            self.isDoneLoading = true;
            
        });
        }
    }] resume];
}


- (void)setTrackListPlayer:(NKTrackListPlayer *)trackListPlayer {
    _trackListPlayer = trackListPlayer;
}

#pragma mark - PlayerSetting

-(void)pause{
    [self.trackListPlayer.trackPlayer pausePlayback];
}

-(void)next{

    if (self.trackListPlayer.trackPlayer.playbackState == NKPlaybackStateStopped){
        [self setQtracks:[self.tracks mutableCopy]];
    }
    
//    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
//    if (player.playbackState == NKPlaybackStateFinished){
        if (self.queue.count > 0) {
//            [self.trackListPlayer playTracks:self.queue startingWith:[self.queue firstObject] fromContext:nil];
            [self.trackListPlayer playTrack:[self.queue firstObject]];
            [self.queue removeObjectAtIndex:0];
        } else {
            self.currentPlayItem++;
            if (self.currentPlayItem > self.qtracks.count-1) {
                self.currentPlayItem = 0;
            }
            NKTrack *track = [self.qtracks objectAtIndex:self.currentPlayItem];
//            [self.trackListPlayer playTracks:self.qtracks startingWith:track fromContext:nil];
            [self.trackListPlayer playTrack:track];
        }
//    }
    if ([self.tracks isEqual:self.qtracks]) {
        [self.carousel scrollToItemAtIndex:self.currentPlayItem animated:YES];
        self.currentItem = self.currentPlayItem;
        [self configurePlayheadSlider];
    }
    
}

-(void)previous{
    if (self.trackListPlayer.trackPlayer.playbackState == NKPlaybackStateStopped){
        [self setQtracks:[self.tracks mutableCopy]];
    }
    self.currentPlayItem--;
    if (self.currentPlayItem < 0) {
        self.currentPlayItem = self.qtracks.count - 1;
    }
    NKTrack *track = [self.qtracks objectAtIndex:self.currentPlayItem];
    [self.trackListPlayer playTrack:track];
//    [self.carousel scrollToItemAtIndex:self.currentItem animated:YES];
    if ([self.tracks isEqual:self.qtracks]) {
        [self.carousel scrollToItemAtIndex:self.currentPlayItem animated:YES];
        self.currentItem = self.currentPlayItem;
        [self configurePlayheadSlider];
    }
    [self configurePlayheadSlider];
    NSLog(@"%ld : %ld", (long)self.currentItem, (long)[self.trackListPlayer.tracks indexOfObject:self.trackListPlayer.trackPlayer.currentTrack]);
}


- (IBAction)previousButtonTapped:(id)sender
{
    [self previous];
    
}

- (IBAction)stopButtonPressed:(id)sender {
    [self.trackListPlayer stopPlayback];
}

- (IBAction)btnMiniPlayerClick:(id)sender {
    self.isMiniPlayerClicked = YES;
    
    if (self.isMiniPlayerClicked) {
        if (self.trackListPlayer.currentTrack){

    
        } else {
            NKTrack *track = [self.tracks objectAtIndex:self.currentPlayItem];
            self.qtracks = NSMutableArray.new;
            [self setQtracks:[self.tracks mutableCopy]];
            [self.trackListPlayer playTrack:track];
        }
    } else {
        NKTrack *track = [self.tracks objectAtIndex:self.currentPlayItem];
        self.qtracks = NSMutableArray.new;
        [self setQtracks:[self.tracks mutableCopy]];
        [self.trackListPlayer playTrack:track];
    }
    
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    PlayViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"PlayVC"];
    
    vc.napster = self.napster;
    
    
    vc.isMiniPlayerClicked = self.isMiniPlayerClicked;
    vc.napster = self.napster;
    vc.catIndex = self.catIndex;
    vc.subCode = self.subCode;
    vc.currentItem = self.currentItem;
    vc.currentPlayItem = self.currentPlayItem;
    vc.queue = NSMutableArray.new;
    vc.queue = [self.queue mutableCopy];
    vc.qtracks = [self.qtracks mutableCopy];
    vc.tracks = [self.tracks mutableCopy];
    vc.HomeVC = self;
    vc.myLibrary = NSMutableArray.new;
    vc.myLibrary = [self.myLibrary mutableCopy];
    vc.imageArray = [self.imageArray mutableCopy];
    [vc setTrackListPlayer: self.trackListPlayer];
    [self.napster.notificationCenter removeObserver:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Count_____________%ld", (long)vc.queue.count);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeModal:) name:@"CloseModal" object:nil];
    
    [self presentViewController:vc animated:YES completion:^{
        
        
    }];
    
//    [self performSegueWithIdentifier:@"SegueToPlay" sender:self];
}


- (IBAction)nextButtonTapped:(id)sender
{
    [self next];
    
}

- (IBAction)playButtonTapped:(id)sender {
    
    switch (self.trackListPlayer.trackPlayer.playbackState) {
        case NKPlaybackStateStopped:{
            NSLog(@"NKPlaybackStateStopped");
            self.qtracks = NSMutableArray.new;
            [self setQtracks:[self.tracks mutableCopy]];
            NKTrack *track = [self.qtracks objectAtIndex:self.currentItem];
            self.currentPlayItem = self.currentItem;
            [self.trackListPlayer playTrack:track];
            [[self playButton] setImage:[UIImage imageNamed:@"Pause_Icon"] forState:UIControlStateNormal];
            break;
            
        }
        case NKPlaybackStateFinished:
            NSLog(@"NKPlaybackStateFinished");
            break;
        case NKPlaybackStatePaused:
            [self.trackListPlayer.trackPlayer resumePlayback];
            [[self playButton] setImage:[UIImage imageNamed:@"Pause_Icon"] forState:UIControlStateNormal];
            NSLog(@"NKPlaybackStatePaused");
            
            break;
        case NKPlaybackStateBuffering:
            NSLog(@"NKPlaybackStateBuffering");
            break;
        case NKPlaybackStatePlaying:
            [self.trackListPlayer.trackPlayer pausePlayback];
            [[self playButton] setImage:[UIImage imageNamed:@"Play_Icon"] forState:UIControlStateNormal];
            NSLog(@"NKPlaybackStatePlaying");
            break;
           
    }
    [self configureForPlayer];
}

- (void)onSliderTap:(UITapGestureRecognizer *)recognizer {
    float width = self.playheadSlider.frame.size.width;
    CGPoint point = [recognizer locationInView:recognizer.view];
    CGFloat sliderX = self.playheadSlider.frame.origin.x;
    float newValue = ((point.x - sliderX) * self.playheadSlider.maximumValue) / width;
    [self.playheadSlider setValue:newValue];
    [self.trackListPlayer.trackPlayer seekTo:[[self playheadSlider] value]];
    
}

#pragma mark NotificationSetting

- (void)playbackStateDidChange:(NSNotification*)notification
{
    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
    if (player.playbackState == NKPlaybackStateFinished){
        if (self.queue.count > 0) {

            [self.trackListPlayer playTrack:[self.queue firstObject]];
            [self.queue removeObjectAtIndex:0];
        } else {
            self.currentPlayItem++;
            if (self.currentPlayItem > self.qtracks.count-1) {
                self.currentPlayItem = 0;
            }
            NKTrack *track = [self.qtracks objectAtIndex:self.currentPlayItem];

            [self.trackListPlayer playTrack:track];
        }
    }
    [self configureForPlayer];
}

- (void)playerTracksDidChange:(NSNotification*)notification
{
    [self configureForPlayer];
}

- (void)currentTrackDidChange:(NSNotification*)notification
{
    [self configureForPlayer];
}

- (void)currentTrackIndexDidChange:(NSNotification*)notification
{
    [self configureForPlayer];

}

- (void)currentTrackAmoundDownloadedDidChange:(NSNotification*)notification
{
//    [self configureTrackProgressView];
}

- (void)playheadPositionDidChange:(NSNotification*)notification
{
    [self configurePlayheadSlider];
    
}

- (void)currentTrackDurationDidChange:(NSNotification*)notification
{
    [self configurePlayheadSlider];
}

- (void)tracksDidChange:(NSNotification*)notification
{
    [self configureForPlayer];
}

- (IBAction)playheadSliderBeganDrag:(id)sender
{
    [self.trackListPlayer.trackPlayer setScrubbing:YES];
}

- (IBAction)playheadSliderDragged:(id)sender
{
    NSTimeInterval playheadPosition = [self.trackListPlayer.trackPlayer seekTo:[[self playheadSlider] value]];
    [[self playheadSlider] setValue:playheadPosition];
}

- (IBAction)playheadSliderEndedDrag:(id)sender
{
    [self.trackListPlayer.trackPlayer setScrubbing:NO];
}






- (void)configureForPlayer
{
    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;

    if (player.playbackState == NKPlaybackStatePlaying || player.playbackState == NKPlaybackStateBuffering){
        [[self playButton] setImage:[UIImage imageNamed:@"Pause_Icon"] forState:UIControlStateNormal];
        
    } else {
        [[self playButton] setImage:[UIImage imageNamed:@"Play_Icon"] forState:UIControlStateNormal];
        
    }
    
    if (player.playbackState == NKPlaybackStateFinished) {
        [self next];
    }
    if (player.playbackState == NKPlaybackStateStopped) return;
    NKTrack *track = self.trackListPlayer.currentTrack;
    [[self lblArtist] setText:track.artist.name];
    [[self lblTrackName] setText:track.name];
    NSString *albumID = track.album.ID;
    NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/500x500.jpg", albumID];
    NSURL *url = [NSURL URLWithString:path];
    
    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary* newInfo = [NSMutableDictionary dictionary];
    
    NSNumber *headPos = [NSNumber numberWithDouble:self.trackListPlayer.trackPlayer.playheadPosition];
    if (track) {
    [newInfo setObject:track.name forKey:MPMediaItemPropertyTitle];
    [newInfo setObject:track.artist.name forKey:MPMediaItemPropertyArtist];
    [newInfo setObject:track.duration forKey:MPMediaItemPropertyPlaybackDuration];
    [newInfo setObject:headPos forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    }
    if ([self.miniImgCache objectForKey:url]) {
        
        MPMediaItemArtwork *media;
        UIImage *img = [self.imgCache objectForKey:url];
        if (track) {
            if (@available(iOS 10.0, *)) {
                media = [[MPMediaItemArtwork alloc] initWithBoundsSize:img.size requestHandler:^UIImage * _Nonnull(CGSize size) {
                    return img;
                }];
            } else {
                media = [[MPMediaItemArtwork alloc] initWithImage:img];
            }
            
        [newInfo setObject:media forKey:MPMediaItemPropertyArtwork];
        info.nowPlayingInfo = newInfo;
        }
    } else {
        [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error!= nil) {
                NSLog(@"%@", error);
                return;
            }
            
            UIImage *imgAlbum = [[UIImage alloc] initWithData:data];
            if (!imgAlbum) {
                imgAlbum = [UIImage imageNamed:@"Background"];
            }
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIImage *imageToCache = imgAlbum;
                
                [self.miniImgCache setObject:imageToCache forKey:url];
                
                if (track) {
                    MPMediaItemArtwork *media;
                    if (@available(iOS 10.0, *)) {
                        media = [[MPMediaItemArtwork alloc] initWithBoundsSize:imageToCache.size requestHandler:^UIImage * _Nonnull(CGSize size) {
                            return imageToCache;
                        }];
                    } else {
                        media = [[MPMediaItemArtwork alloc] initWithImage:imageToCache];
                    }
                    [newInfo setObject:media forKey:MPMediaItemPropertyArtwork];
                    info.nowPlayingInfo = newInfo;
                }
            });
        }] resume];
    }
        
//    }
    self.miniImage.layer.cornerRadius = self.miniImage.frame.size.height/17;
    self.miniImage.clipsToBounds = YES;
    
    [self configurePlayheadSlider];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)configurePlayheadSlider
{
    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
    NSTimeInterval duration = [player currentTrackDuration];
    [[self playheadSlider] setMaximumValue:duration];
    [[self playheadSlider] setValue:player.playheadPosition];
    [[self playheadSlider] setEnabled:player.playbackState != NKPlaybackStateStopped && duration != 0];
    
//    NSDateComponentsFormatter *dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
   
    [[self currentTime] setText:[self stringFromTimeInterval:player.playheadPosition]];
//    [[self currentTime] setText:[dateComponentsFormatter stringFromTimeInterval:player.playheadPosition]];
    [[self trackTime] setText:[self stringFromTimeInterval:duration]];
//    [[self trackTime] setText:[dateComponentsFormatter stringFromTimeInterval:duration]];
    
//    MPNowPlayingInfoCenter* info = [MPNowPlayingInfoCenter defaultCenter];
//    NSMutableDictionary* newInfo = [NSMutableDictionary dictionary];
//
//    NKTrack *currentTrack = self.trackListPlayer.currentTrack;
//    NSInteger index = [self.tracks indexOfObject:currentTrack];
//    UIImage *image = [self.imageArray objectAtIndex:index];
//    [newInfo setObject:currentTrack.name forKey:MPMediaItemPropertyTitle];
//    [newInfo setObject:currentTrack.artist.name forKey:MPMediaItemPropertyArtist];
//    [newInfo setObject:currentTrack.duration forKey:MPMediaItemPropertyPlaybackDuration];
//    MPMediaItemArtwork *media = [[MPMediaItemArtwork alloc] initWithImage:image];
//    [newInfo setObject:media forKey:MPMediaItemPropertyArtwork];
//    info.nowPlayingInfo = newInfo;
    
}

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
}


#pragma mark iCarousel Configration

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    if (items.count < 1000 && items > 0) {
        return [items count];
    } else {
        return 1;
    }
    
}


- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    NKTrack *track = [self.tracks objectAtIndex:index];
    NSString * text = track.artist.name;
    
//    UILabel *label = nil;
    UIButton *imgArtist = nil;
    UILabel *artistName = nil;
    UILabel *trackName = nil;
    UIButton *sButton = nil;
    UIImageView *imgArtistView = nil;
    //create new view if no view is available for recycling
    if (view == nil)
    {
        int imgWidth=250;
        int imgHeight=315;
        int imgArtistWidth=210;
        int imgArtistHeight=215;
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imgWidth, imgHeight)];
        imgArtist = [[UIButton alloc] initWithFrame:CGRectMake(20,20,imgArtistWidth, imgArtistHeight)];
        imgArtist.tag = 200;
        [imgArtist addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
        imgArtistView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,imgArtistWidth, imgArtistHeight)];
        imgArtistView.tag = 800;
        [imgArtist addSubview:imgArtistView];
        [view addSubview:imgArtist];
        
        artistName = [[UILabel alloc]initWithFrame:CGRectMake(20, 250, 170, 20)];
        artistName.numberOfLines = 0;
        artistName.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
        artistName.adjustsFontSizeToFitWidth = YES;
        artistName.adjustsLetterSpacingToFitWidth = YES;
        artistName.minimumScaleFactor = 10.0f/12.0f;
        artistName.clipsToBounds = YES;
        artistName.backgroundColor = [UIColor clearColor];
        artistName.textColor = [UIColor whiteColor];
        artistName.textAlignment = NSTextAlignmentLeft;
        [artistName setFont:[UIFont fontWithName:@"Lato-Bold" size:15]];
        artistName.tag = 500;
        [view addSubview:artistName];
        [self.arrayArtistName addObject:artistName];
        
        trackName = [[UILabel alloc]initWithFrame:CGRectMake(20, 260, 170, 40)];
        trackName.numberOfLines = 0;
        trackName.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
        trackName.adjustsFontSizeToFitWidth = YES;
        trackName.adjustsLetterSpacingToFitWidth = YES;
        trackName.minimumScaleFactor = 10.0f/12.0f;
        trackName.clipsToBounds = YES;
        trackName.backgroundColor = [UIColor clearColor];
        trackName.textColor = [UIColor whiteColor];
        trackName.textAlignment = NSTextAlignmentLeft;
        trackName.contentMode = UIViewContentModeTop;
        [trackName setFont:[UIFont fontWithName:@"Lato-Regular" size:12]];
        trackName.tag = 600;
        [self.arrayTrackName addObject:trackName];
        [view addSubview:trackName];

        sButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sButton.frame     = CGRectMake(195, 240,44,44 );
        [sButton addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [sButton setContentMode:UIViewContentModeCenter];
        sButton.tag = 300;
        [view addSubview:sButton];
        view.userInteractionEnabled = YES;
        view.exclusiveTouch = YES;    }
    else
    {
        //get a reference to the label in the recycled view
//        label = (UILabel *)[view viewWithTag:1];
        imgArtist = (UIButton*)[view viewWithTag:200];
        imgArtistView = (UIImageView*)[view viewWithTag:800];
        artistName = (UILabel *)[view viewWithTag:500];
        trackName = (UILabel *)[view viewWithTag:600];
        sButton = (UIButton*)[view viewWithTag:300];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
//    label.text = [items[index] stringValue];
       
    view.contentMode = UIViewContentModeScaleToFill;
    view.backgroundColor =[UIColor whiteColor];
    view.layer.cornerRadius = imgArtist.frame.size.height/15;
//    view.clipsToBounds = YES;
    view.layer.shadowRadius  = 30.0f;
    view.layer.shadowColor   = [UIColor colorWithRed:171.f/255.f green:183.f/255.f blue:193.f/255.f alpha:1.f].CGColor;
    view.layer.shadowOffset  = CGSizeMake(0.0f, 20.0f);
    view.layer.shadowOpacity = 1.f;

    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -20.0f, 0);
    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(view.bounds, shadowInsets)];
    view.layer.shadowPath    = shadowPath.CGPath;
    view.layer.masksToBounds = false;
    if (index == carousel.currentItemIndex) {
        ((UIImageView *)view).image = [UIImage imageNamed:@"station_BG"];
    }
    
    
    imgArtist.layer.cornerRadius = imgArtist.frame.size.height/15;
    
    imgArtist.layer.shadowRadius  = 10.0f;
//    imgArtist.layer.shadowColor   = [UIColor colorWithRed:171.f/255.f green:183.f/255.f blue:193.f/255.f alpha:1.f].CGColor;
    imgArtist.layer.shadowColor   = [UIColor blackColor].CGColor;
    imgArtist.layer.shadowOffset  = CGSizeMake(10.0f, 10.0f);
    imgArtist.layer.shadowOpacity = 0.2f;
    imgArtist.contentMode = UIViewContentModeScaleAspectFit;

    shadowInsets     = UIEdgeInsetsMake(-10.0f, -10.0f, -10.0f, -10.0f);
    shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(imgArtist.bounds, shadowInsets)];
    imgArtist.layer.shadowPath    = shadowPath.CGPath;
    imgArtist.layer.masksToBounds = false;
    
     NSString *albumID = track.album.ID;
     NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/300x300.jpg", albumID];
     NSURL *url = [NSURL URLWithString:path];

    
    if ([self.imgCache objectForKey:url]) {
        [imgArtistView setImage:[self.imgCache objectForKey:url]];
    } else {
        [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error!= nil) {
                NSLog(@"%@", error);
                return;
            }
            
            UIImage *imgAlbum = [[UIImage alloc] initWithData:data];
            if (!imgAlbum) {
                imgAlbum = [UIImage imageNamed:@"Background"];
            }
            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIImage *imageToCache = imgAlbum;
                
                [self.imgCache setObject:imageToCache forKey:url];
                
                [imgArtistView setImage:imageToCache];
            });
        }] resume];
    }
    
//    [imgArtistView setImage:[self.imageArray objectAtIndex:index]];
    imgArtistView.layer.cornerRadius = imgArtistView.frame.size.height/17;
    imgArtistView.clipsToBounds = YES;
    
    artistName.text = text;
    trackName.text = track.name;
    [sButton setImage:[UIImage imageNamed:@"3_Dots_Icon"] forState:UIControlStateNormal];
    
    
//    label.text = (index == 0)? @"[": @"]";
    return view;
}

- (NSInteger)numberOfPlaceholdersInCarousel:(__unused iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 0;
}

- (CATransform3D)carousel:(__unused iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0, 0.0, 1.0, 0.0);
    return CATransform3DTranslate(transform, 0.0, 0.0, offset * self.carousel.itemWidth);
}

- (CGFloat)carousel:(__unused iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            //normally you would hard-code this to YES or NO
//            return self.wrap;
            return YES;
        }
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value*1.3 ;
//            if (carousel.numberOfItems < 12) {
//                if (carousel.numberOfItems == 3) {
//                    return value*(5);
//                } else {
//                    return value*(1.8);
//                }
//
//
//            } else {
//                return value*1.3 ;
//            }
//            return value * 12/carousel.numberOfItems;
        }
        case iCarouselOptionFadeMax:
        {
            if (self.carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0;
            }
            return value;
        }
        case iCarouselOptionShowBackfaces:
        case iCarouselOptionRadius:
        case iCarouselOptionAngle:
        case iCarouselOptionArc:
        case iCarouselOptionTilt:
        case iCarouselOptionCount:
        {
            return value;
        }
        case iCarouselOptionFadeMin:
        case iCarouselOptionFadeMinAlpha:
        case iCarouselOptionFadeRange:
        case iCarouselOptionOffsetMultiplier:
        case iCarouselOptionVisibleItems:
        {
            return value;
        }
    }
    
}

- (void)carousel:(__unused iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    NSNumber *item = (self.items)[(NSUInteger)index];
    NSLog(@"Tapped view number: %@", item);
}

- (void)carouselCurrentItemIndexDidChange:(__unused iCarousel *)carousel
{
    NSLog(@"Index: %@", @(self.carousel.currentItemIndex));
    NSInteger index = self.carousel.currentItemIndex;
    
    UIView *view = [self.carousel itemViewAtIndex:[self.carousel previousItemIndex]];
    //    [view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"station_BG"]]];
    ((UIImageView *)view).image = [UIImage imageNamed:@"Background"];
    [self.gradient removeFromSuperlayer];
    for (UIView *obj in [view subviews])
    {
         //Check if the view is of UILabel class
         if ([obj isKindOfClass:[UILabel class]])
         {
          //Cast the view to a UILabel
          UILabel *label = (UILabel *)obj;
          //Set the color to label
          label.textColor = [UIColor blackColor];
         }
    }
    ((UIImageView *)carousel.currentItemView).image = [UIImage imageNamed:@"station_BG"];
    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -20.0f, 0);
    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(view.bounds, shadowInsets)];
    carousel.currentItemView.layer.shadowPath    = shadowPath.CGPath;
    carousel.currentItemView.layer.masksToBounds = false;
    for (UIView *obj in [carousel.currentItemView subviews])
    {
         //Check if the view is of UILabel class
         if ([obj isKindOfClass:[UILabel class]])
         {
          //Cast the view to a UILabel
          UILabel *label = (UILabel *)obj;
          //Set the color to label
          label.textColor = [UIColor whiteColor];
         }
    }
    if (index < 0) {
        return;
    }
    NKTrack *track = [self.tracks objectAtIndex:index];
    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
    if (player.playbackState == NKPlaybackStateStopped || player.playbackState == NKPlaybackStateFinished) {
        [[self lblArtist] setText:track.artist.name];
        [[self lblTrackName] setText:track.name];
        NSString *albumID = track.album.ID;
        NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/300x300.jpg", albumID];
        NSURL *url = [NSURL URLWithString:path];


        if ([self.miniImgCache objectForKey:url]) {
            [self.miniImage setImage:[self.imgCache objectForKey:url]];
        } else {
            [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                if (error!= nil) {
                    NSLog(@"%@", error);
                    return;
                }
                
                UIImage *imgAlbum = [[UIImage alloc] initWithData:data];
                if (!imgAlbum) {
                    imgAlbum = [UIImage imageNamed:@"Background"];
                }
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIImage *imageToCache = imgAlbum;
                    
                    [self.miniImgCache setObject:imageToCache forKey:url];
                    
                    [self.miniImage setImage:imageToCache];
                });
            }] resume];
        }

        //    [imgArtistView setImage:[self.imageArray objectAtIndex:index]];
        self.miniImage.layer.cornerRadius = self.miniImage.frame.size.height/17;
        self.miniImage.clipsToBounds = YES;
        self.currentItem = index;
    }
    self.currentItem = index;
    
    
}

#pragma mark SubCatScroll Drawing

- (UIBezierPath *)yb_bezierPathWithRect:(CGRect)rect
                             rectCorner:(UIRectCorner)rectCorner
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(UIColor *)borderColor
                        backgroundColor:(UIColor *)backgroundColor
                             arrowWidth:(CGFloat)arrowWidth
                            arrowHeight:(CGFloat)arrowHeight
                          arrowPosition:(CGFloat)arrowPosition
                         arrowDirection:(NSInteger)arrowDirection
{
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    if (borderColor) {
        [borderColor setStroke];
        
    }
    if (backgroundColor) {
        [backgroundColor setFill];
    }
    bezierPath.lineWidth = borderWidth;
    rect = CGRectMake(borderWidth / 2, borderWidth / 2, YBRectWidth(rect) - borderWidth, YBRectHeight(rect) - borderWidth);
    CGFloat topRightRadius = 0,topLeftRadius = 0,bottomRightRadius = 0,bottomLeftRadius = 0;
    CGPoint topRightArcCenter,topLeftArcCenter,bottomRightArcCenter,bottomLeftArcCenter;
    
    if (rectCorner & UIRectCornerTopLeft) {
        topLeftRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerTopRight) {
        topRightRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerBottomLeft) {
        bottomLeftRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerBottomRight) {
        bottomRightRadius = cornerRadius;
    }
    
    if (arrowDirection == 0) {
        topLeftArcCenter = CGPointMake(topLeftRadius + YBRectX(rect), arrowHeight + topLeftRadius + YBRectX(rect));
        topRightArcCenter = CGPointMake(YBRectWidth(rect) - topRightRadius + YBRectX(rect), arrowHeight + topRightRadius + YBRectX(rect));
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + YBRectX(rect), YBRectHeight(rect) - bottomLeftRadius + YBRectX(rect));
        bottomRightArcCenter = CGPointMake(YBRectWidth(rect) - bottomRightRadius + YBRectX(rect), YBRectHeight(rect) - bottomRightRadius + YBRectX(rect));
        if (arrowPosition < topLeftRadius + arrowWidth / 2) {
            arrowPosition = topLeftRadius + arrowWidth / 2;
        }else if (arrowPosition > YBRectWidth(rect) - topRightRadius - arrowWidth / 2) {
            arrowPosition = YBRectWidth(rect) - topRightRadius - arrowWidth / 2;
        }
        [bezierPath moveToPoint:CGPointMake(arrowPosition - arrowWidth / 2, arrowHeight + YBRectX(rect))];

        [bezierPath addLineToPoint:CGPointMake(YBRectWidth(rect) - topRightRadius, arrowHeight + YBRectX(rect))];
        [bezierPath addArcWithCenter:topRightArcCenter radius:topRightRadius startAngle:M_PI * 3 / 2 endAngle:2 * M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(YBRectWidth(rect) + YBRectX(rect), YBRectHeight(rect) - bottomRightRadius - YBRectX(rect))];
        [bezierPath addArcWithCenter:bottomRightArcCenter radius:bottomRightRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(bottomLeftRadius + YBRectX(rect), YBRectHeight(rect) + YBRectX(rect))];
        [bezierPath addArcWithCenter:bottomLeftArcCenter radius:bottomLeftRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
        [bezierPath addLineToPoint:CGPointMake(YBRectX(rect), arrowHeight + topLeftRadius + YBRectX(rect))];
        [bezierPath addArcWithCenter:topLeftArcCenter radius:topLeftRadius startAngle:M_PI endAngle:M_PI * 3 / 2 clockwise:YES];
        
    }
    
    [bezierPath closePath];
    return bezierPath;
}

- (UIBezierPath *)yb1_bezierPathWithRect:(CGRect)rect
                             rectCorner:(UIRectCorner)rectCorner
                           cornerRadius:(CGFloat)cornerRadius
                            borderWidth:(CGFloat)borderWidth
                            borderColor:(UIColor *)borderColor
                        backgroundColor:(UIColor *)backgroundColor
                             arrowWidth:(CGFloat)arrowWidth
                            arrowHeight:(CGFloat)arrowHeight
                          arrowPosition:(CGFloat)arrowPosition
                         arrowDirection:(NSInteger)arrowDirection
{
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    if (borderColor) {
        [borderColor setStroke];
        
    }
    if (backgroundColor) {
        [backgroundColor setFill];
    }
    bezierPath.lineWidth = borderWidth;
    rect = CGRectMake(borderWidth / 2, borderWidth / 2, YBRectWidth(rect) - borderWidth, YBRectHeight(rect) - borderWidth);
    CGFloat topRightRadius = 0,topLeftRadius = 0,bottomRightRadius = 0,bottomLeftRadius = 0;
    CGPoint topRightArcCenter,topLeftArcCenter,bottomRightArcCenter,bottomLeftArcCenter;
    
    if (rectCorner & UIRectCornerTopLeft) {
        topLeftRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerTopRight) {
        topRightRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerBottomLeft) {
        bottomLeftRadius = cornerRadius;
    }
    if (rectCorner & UIRectCornerBottomRight) {
        bottomRightRadius = cornerRadius;
    }
    
    if (arrowDirection == 0) {
        topLeftArcCenter = CGPointMake(topLeftRadius + YBRectX(rect), arrowHeight + topLeftRadius + YBRectX(rect));
        topRightArcCenter = CGPointMake(YBRectWidth(rect) - topRightRadius + YBRectX(rect), arrowHeight + topRightRadius + YBRectX(rect));
        bottomLeftArcCenter = CGPointMake(bottomLeftRadius + YBRectX(rect), YBRectHeight(rect) - bottomLeftRadius + YBRectX(rect));
        bottomRightArcCenter = CGPointMake(YBRectWidth(rect) - bottomRightRadius + YBRectX(rect), YBRectHeight(rect) - bottomRightRadius + YBRectX(rect));
        if (arrowPosition < topLeftRadius + arrowWidth / 2) {
            arrowPosition = topLeftRadius + arrowWidth / 2;
        }else if (arrowPosition > YBRectWidth(rect) - topRightRadius - arrowWidth / 2) {
            arrowPosition = YBRectWidth(rect) - topRightRadius - arrowWidth / 2;
        }
        [bezierPath moveToPoint:CGPointMake(arrowPosition - arrowWidth / 2, arrowHeight + YBRectX(rect))];

        
        
        [bezierPath moveToPoint:CGPointMake(arrowPosition - arrowWidth / 2, arrowHeight + YBRectX(rect))];
        [bezierPath addLineToPoint:CGPointMake(arrowPosition, YBRectTop(rect) + YBRectX(rect))];
        [bezierPath addLineToPoint:CGPointMake(arrowPosition + arrowWidth / 2, arrowHeight + YBRectX(rect))];
        
    }
    
    [bezierPath closePath];
    return bezierPath;
}

- (CAShapeLayer *)yb_maskLayerWithRect:(CGRect)rect
                            rectCorner:(UIRectCorner)rectCorner
                          cornerRadius:(CGFloat)cornerRadius
                            arrowWidth:(CGFloat)arrowWidth
                           arrowHeight:(CGFloat)arrowHeight
                         arrowPosition:(CGFloat)arrowPosition
                        arrowDirection:(NSInteger)arrowDirection
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [self yb_bezierPathWithRect:rect rectCorner:rectCorner cornerRadius:cornerRadius borderWidth:0 borderColor:nil backgroundColor:nil arrowWidth:arrowWidth arrowHeight:arrowHeight arrowPosition:arrowPosition arrowDirection:arrowDirection].CGPath;
    CAShapeLayer *shapeLayer1 = [CAShapeLayer layer];
    shapeLayer1.path = [self yb1_bezierPathWithRect:rect rectCorner:rectCorner cornerRadius:cornerRadius borderWidth:0 borderColor:nil backgroundColor:nil arrowWidth:arrowWidth arrowHeight:arrowHeight arrowPosition:arrowPosition arrowDirection:arrowDirection].CGPath;
    shapeLayer1.fillColor = [[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0] CGColor];
    [shapeLayer addSublayer:shapeLayer1];
    return shapeLayer;
}

#pragma mark SubCatalog Configuration

-(void) configSubCatalog:(NSInteger) index{
    
    CGRect frame = CGRectNull;
    for (UIButton *button in self.catScrollView.subviews) {
        if (button.tag == 100 +index) {
            frame = [self.view convertRect:button.frame fromView:self.catScrollView];
        }
    }
    
    [self.subCatView setFrame:CGRectMake(20, frame.origin.y + frame.size.height + 6, 335, 36)];
    [self.subCatLayer removeFromSuperlayer];
    
    self.subCatLayer = [self yb_maskLayerWithRect:CGRectMake(0, 0, 335, 36)
                                        rectCorner:UIRectCornerAllCorners
                                          cornerRadius:15
                                            arrowWidth:12
                                           arrowHeight:6
                                         arrowPosition: (frame.origin.x + frame.size.width/4)
                                        arrowDirection:0];

    self.subCatLayer.backgroundColor =[[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor];
    self.subCatLayer.fillColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor];
    self.subCatLayer.strokeColor = [[UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1] CGColor];
    self.subCatLayer.borderWidth = 2;
    
    
    CGRect scrollframe = self.subCatView.bounds;
    scrollframe.origin.y = self.subCatView.bounds.size.height/8;
    
    self.innerScrollView = [[UIScrollView alloc] initWithFrame:scrollframe];
    
    int xCoord=13;
    int yCoord=0;
    int buttonWidth=100;
    int buttonHeight=31;
    int buffer = 25;
    NSInteger i;
    for (i = 0; i < self.subCategory.count; i++)
    {
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aButton.frame     = CGRectMake(xCoord, yCoord,buttonWidth,buttonHeight );
        if (i == self.subCatIndex) {
            [aButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        } else {
            [aButton setTitleColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0] forState:UIControlStateNormal];
        }
        
        
        [aButton setTitle:[self.subCategory objectAtIndex:i] forState:UIControlStateNormal];
        [aButton setFont:[UIFont systemFontOfSize:12]];
        
        [aButton setContentMode:UIViewContentModeScaleAspectFit];
        [aButton addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
        aButton.tag = 400 + i;
        
        CGSize stringSize = [aButton.titleLabel.text sizeWithFont:aButton.titleLabel.font];
        CGRect frame = aButton.frame;
        frame.size.width = stringSize.width;
        [aButton setFrame:frame];
        
        [self.innerScrollView addSubview:aButton];

        xCoord += frame.size.width + buffer;
    }
    [self.innerScrollView setContentSize:CGSizeMake(xCoord, 31)];
    [self.innerScrollView setAlwaysBounceVertical:NO];
    [self.innerScrollView setContentMode:UIViewContentModeScaleAspectFit];
    [self.innerScrollView setShowsHorizontalScrollIndicator:NO];
    [self.innerScrollView setShowsVerticalScrollIndicator:NO];
    [self.subCatView addSubview:self.innerScrollView];
    [self.subCatView.layer insertSublayer:self.subCatLayer below:self.innerScrollView.layer];
//    [self.view addSubview:self.subCatView];
    [self.view layoutIfNeeded];
}

-(void) redrawSubCatalog:(NSInteger) index{
    
    CGRect frame = CGRectNull;
    for (UIButton *button in self.catScrollView.subviews) {
        if (button.tag == 100 +index) {
            frame = [self.view convertRect:button.frame fromView:self.catScrollView];
        }
    }
    
    for (UIButton *button in self.innerScrollView.subviews) {
        if (button.tag == 400 + self.subCatIndex) {
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        } else {
            [button setTitleColor:[UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0] forState:UIControlStateNormal];
        }
    }
    
    [self.subCatView setFrame:CGRectMake(20, frame.origin.y + frame.size.height + 6, 335, 36)];
    [self.subCatLayer removeFromSuperlayer];
    
    self.subCatLayer = [self yb_maskLayerWithRect:CGRectMake(0, 0, 335, 36)
                                        rectCorner:UIRectCornerAllCorners
                                          cornerRadius:15
                                            arrowWidth:12
                                           arrowHeight:6
                                         arrowPosition: (frame.origin.x + frame.size.width/4)
                                        arrowDirection:0];

    self.subCatLayer.backgroundColor =[[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor];
    self.subCatLayer.fillColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor];
    self.subCatLayer.strokeColor = [[UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1] CGColor];
    self.subCatLayer.borderWidth = 2;
    [self.subCatView.layer insertSublayer:self.subCatLayer below:self.innerScrollView.layer];
    [self.view layoutIfNeeded];
}

#pragma mark CatScrollView Operation

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (scrollView == self.catScrollView) {
        
        [self redrawSubCatalog:self.catIndex];
    }
}

#pragma mark TableSetting

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tblPlaylist
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.playLists.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"QueueCell";
    PlaylistCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PlayList *playlist = [self.playLists objectAtIndex:indexPath.row];
    [cell.button setTitle:playlist.name forState:UIControlStateNormal];
    [cell.button addTarget:self action:@selector(playlistButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (IBAction)btnCloseClick:(id)sender {
    [self plistViewHide];
}

- (void) playlistButtonClicked: (id) sender {
    UIButton *btn = (UIButton *) sender;
    PlaylistCell *cell = (PlaylistCell *) [[btn superview] superview];
    NSIndexPath *indexPath = [self.tblPlaylists indexPathForCell:cell];
    NSLog(@"Btn's tag:  %ld", (long)indexPath.row);
    PlayList *playlist = [self.playLists objectAtIndex:indexPath.row];
    NKTrack *track = [self.tracks objectAtIndex:self.carousel.currentItemIndex];
    [self addTrack2PlayList:playlist.ID trackid:track];
    [self plistViewHide];
}

-(void) plistViewHide{
    [self.playlistView setHidden:YES];
    [self.maskView setHidden:YES];
}

#pragma mark destructuring

-(void)dealloc {
    
    [self.napster.notificationCenter removeObserver:self];
  
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

- (void)animateLabelShowText:(NSString*)newText characterDelay:(NSTimeInterval)delay
{
    [self.lblTrackName setText:@""];

    for (int i=0; i<newText.length; i++)
    {
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [self.lblTrackName setText:[NSString stringWithFormat:@"%@%C", self.lblTrackName.text, [newText characterAtIndex:i]]];
        });

        [NSThread sleepForTimeInterval:delay];
    }
}

@end
