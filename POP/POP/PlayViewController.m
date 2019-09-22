//
//  PlayViewController.m
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "PlayViewController.h"
#import "NKSAlertView.h"
#import "NKSLoadingOverlay.h"
#import "NKTrackListPlayer.h"
#import "NKSNetworkActivityIndicatorController.h"
#import "NKSAppDelegate.h"
#import "NKAPI+Parsing.h"
#import "NKNapster+Extensions.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import "QueueViewController.h"
#import "PlaylistView.h"
#import "CustomIOSAlertView.h"
#import "PlaylistCell.h"
#import "PlayList.h"
#import "Add2PlaylistView.h"
#import "UIView+TYAlertView.h"
#import "TYAlertController+BlurEffects.h"
#import "ShareView.h"
#import "CreatePlaylistView.h"


// Number of songs that will be calculated using TrackListPlayer
// It is the number of forward and backward songs that the
// sequencers will calculate.
#define NUMBER_OF_CONTEXT_SONGS     2


@interface PlayViewController () <UITableViewDataSource, UITableViewDelegate, Add2PLDelegate, CreatePLDelegate, SettingDelegate>

@property (weak, nonatomic) IBOutlet UIButton* repeatButton;
@property (weak, nonatomic) IBOutlet UIButton* shuffleButton;
@property (weak, nonatomic) IBOutlet UIButton* previousButton;
@property (weak, nonatomic) IBOutlet UIButton* nextButton;
@property (weak, nonatomic) IBOutlet UIButton* playButton;
@property (weak, nonatomic) IBOutlet UIButton* pauseButton;
@property (weak, nonatomic) IBOutlet UISlider* playheadSlider;
@property (weak, nonatomic) IBOutlet UIProgressView* trackProgressView;
@property (nonatomic) NSTimer* levelsMeteringTimer;
@property (weak, nonatomic) IBOutlet UIView* leftAverageMeter;
@property (weak, nonatomic) IBOutlet UIView* leftPeakMeter;
@property (weak, nonatomic) IBOutlet UIImageView* leftMeterImageView;
@property (weak, nonatomic) IBOutlet UIView* rightAverageMeter;
@property (weak, nonatomic) IBOutlet UIView* rightPeakMeter;
@property (weak, nonatomic) IBOutlet UIImageView* rightMeterImageView;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UILabel *trackTime;

@property (weak, nonatomic) IBOutlet UIImageView *artistImageView;
@property (weak, nonatomic) IBOutlet UILabel *lblArtistName;
@property (weak, nonatomic) IBOutlet UILabel *lblTrackName;
@property (weak, nonatomic) IBOutlet UIImageView *imgMicBack;
@property NSCache *imgCache;
@property NSCache *miniImgCache;

@property BOOL isLoaded;
@property NSMutableArray *playLists;

@property (weak, nonatomic) IBOutlet UIButton *imgIsLibrary;

- (IBAction)add2PLClick:(id)sender;

- (IBAction)settingBtnClick:(id)sender;

- (IBAction)add2LibClick:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *maskView;

@property (nonatomic, strong  ) NKTrackListPlayer    *trackListPlayer;


@property (weak, nonatomic    ) NKSLoadingOverlay      *loadingOverlay;

@property (nonatomic, readonly) NKTrackPlayer        *player;
@property (weak, nonatomic) IBOutlet UIButton *micButton;

@property (weak, nonatomic) IBOutlet UIImageView *imgBackGround;

@property BOOL wasBackground;

@end

@implementation PlayViewController
@synthesize napster, player, subCode;
- (IBAction)btnBackClick:(id)sender {
    MusicHomeViewController *vc = self.HomeVC;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseModal" object:self];
    vc.napster = self.napster;
    [vc setTrackListPlayer: self.trackListPlayer];

    vc.catIndex = self.catIndex;
    vc.subCode = self.subCode;
    vc.isMiniPlayerClicked = self.isMiniPlayerClicked;
    vc.currentPlayItem = self.currentPlayItem;
    vc.currentItem = self.currentItem;
    NSLog(@"Current Item:%ld", (long)self.currentPlayItem);
    vc.imageArray = [self.imageArray mutableCopy];
    vc.queue = [self.queue mutableCopy];
    vc.myLibrary = NSMutableArray.new;
    vc.myLibrary = [self.myLibrary mutableCopy];
    NSLog(@"%ld:  : %ld", (long)vc.currentPlayItem,(long)self.currentPlayItem);
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setTrackListPlayer:(NKTrackListPlayer *)trackListPlayer {
    _trackListPlayer = trackListPlayer;
}

- (IBAction)repeatButtonTapped:(id)sender
{
    NKRepeatMode repeatMode;
    switch (self.trackListPlayer.repeatMode) {
        case NKRepeatModeNone:
            repeatMode = NKRepeatModeAllTracks;
            break;
        case NKRepeatModeAllTracks:
            repeatMode = NKRepeatModeSingleTrack;
            break;
        case NKRepeatModeSingleTrack:
            repeatMode = NKRepeatModeNone;
            break;
    }
    
    self.trackListPlayer.repeatMode = repeatMode;
}

- (IBAction)shuffleButtonTapped:(id)sender
{
    self.trackListPlayer.shuffling = !self.trackListPlayer.shuffling;
}

- (IBAction)previousButtonTapped:(id)sender
{
    [self previous];
    
}

- (IBAction)stopButtonPressed:(id)sender {
    
    [self.trackListPlayer stopPlayback];
}

- (IBAction)nextButtonTapped:(id)sender
{
    [self next];
}

- (void) previous {
    self.currentPlayItem--;
    if (self.currentPlayItem < 0) {
        self.currentPlayItem = self.qtracks.count - 1;
    }
    NKTrack *track = [self.qtracks objectAtIndex:self.currentPlayItem];
    [self.trackListPlayer playTrack:track];
}

- (void) next{
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
    [self configureForPlayer];
}

- (IBAction)playButtonTapped:(id)sender {
    
    switch (self.trackListPlayer.trackPlayer.playbackState) {
        case NKPlaybackStateStopped:
        case NKPlaybackStateFinished:
        case NKPlaybackStatePaused:
            [self.trackListPlayer.trackPlayer resumePlayback];
            [[self playButton] setImage:[UIImage imageNamed:@"Pause Icon"] forState:UIControlStateNormal];
            break;
        case NKPlaybackStateBuffering:
        case NKPlaybackStatePlaying:
            [self.trackListPlayer.trackPlayer pausePlayback];
            [[self playButton] setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
            break;
    }
    [self configureForPlayer];
}

- (IBAction)pauseButtonTapped:(id)sender
{
    [self pause];
}

- (void) pause{
    [self.trackListPlayer.trackPlayer pausePlayback];
    [self configureForPlayer];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *thumb = [UIImage imageNamed:@"Ellipse"];
    [self.playheadSlider setThumbImage:thumb forState:UIControlStateNormal];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSliderTap:)];
    [self.playheadSlider addGestureRecognizer:tapGestureRecognizer];
    
    [self addingNotifications];
    NSLog(@"Count:   %ld",(long)self.queue.count);
    self.isLoaded = YES;
    self.wasBackground = NO;
    [self configureForPlayer];
}

- (void) addingNotifications{
    

    [self.napster.notificationCenter addObserver:self
                                         selector:@selector(currentTrackDidChange:)
                                             name:NKTrackListNotificationCurrentTrackChanged
                                           object:nil];
    
//    [self.napster.notificationCenter addObserver:self selector:@selector(currentTrackFailed:) name:NKNotificationCurrentTrackFailed object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:NKNotificationPlaybackStateChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackDidChange:) name:NKNotificationCurrentTrackChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackIndexDidChange:) name:NKTrackListNotificationCurrentTrackChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackDurationDidChange:) name:NKNotificationCurrentTrackDurationChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playheadPositionDidChange:) name:NKNotificationPlayheadPositionChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tracksDidChange:) name:NKTrackListNotificationTracksChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shuffleModeDidChange:) name:NKTrackListNotificationShuffleModeChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repeatModeDidChange:) name:NKTrackListNotificationRepeatModeChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackAmoundDownloadedDidChange:) name:NKNotificationCurrentTrackAmountDownloadedChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSettingNotification:)
                                                 name:@"Add2PLSNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSettingNotification:)
                                                 name:@"Add2LibSNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSettingNotification:)
                                                 name:@"Add2QSNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSettingNotification:)
                                                 name:@"Add2PLFNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSettingNotification:)
                                                 name:@"Add2LibFNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveSettingNotification:)
                                                 name:@"Add2QFNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self

    selector:@selector(appDidEnterBackground:)

    name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self

    selector:@selector(appDidBecomeActive:)

    name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

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


- (void) receiveSettingNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"Add2PLSNotification"])
        [self Toast:@"Added to Playlist."];
    if ([[notification name] isEqualToString:@"Add2LibSNotification"]) {
        [self Toast:@"Added to Library."];
        [self.imgIsLibrary setImage:[UIImage imageNamed:@"Heart Icon Active"] forState:UIControlStateNormal];
    }
    if ([[notification name] isEqualToString:@"Add2QSNotification"])
        [self Toast:@"Added to Queue."];
    if ([[notification name] isEqualToString:@"Add2PLFNotification"])
        [self Toast:@"You've already added it to Playlist."];
    if ([[notification name] isEqualToString:@"Add2LibFNotification"])
        [self Toast:@"You've already added it to Library."];
    if ([[notification name] isEqualToString:@"Add2QFNotification"])
        [self Toast:@"You've already added it to Queue."];
}

-(void)Toast:(NSString*)msg{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // Set the text mode to show only text.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = NSLocalizedString(msg, @"HUD message title");
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);

    [hud hideAnimated:YES afterDelay:1.5f];
}

- (void)onSliderTap:(UITapGestureRecognizer *)recognizer {
    float width = self.playheadSlider.frame.size.width;
    CGPoint point = [recognizer locationInView:recognizer.view];
    CGFloat sliderX = self.playheadSlider.frame.origin.x;
    float newValue = ((point.x - sliderX) * self.playheadSlider.maximumValue) / width;
    [self.playheadSlider setValue:newValue];
    [self.trackListPlayer.trackPlayer seekTo:[[self playheadSlider] value]];
 
}

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

- (void)shuffleModeDidChange:(NSNotification*)notification
{
    [self configureForPlayer];
}

- (void)repeatModeDidChange:(NSNotification*)notification
{
    [self configureForPlayer];
}

#pragma mark - TrackFail

- (void)currentTrackFailed:(NSNotification*)notification
{
    NSError* error = [[notification userInfo] objectForKey:NKNotificationErrorKey];
    
    switch ((NKErrorCode)[error code]) {
        case NKErrorAuthenticationError: {
//            [self.napster closeSession];
//            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Signed Out", nil) message:NSLocalizedString(@"Please sign in again.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:NSLocalizedString(@"Sign In", nil), nil];
////            [alertView setTag:NKSRootViewControllerAlertViewAccessTokenFailure];
//            [alertView show];
            [self Toast:@"Please sign in again."];
            return;
        }
        case NKErrorPlaybackSessionInvalid: {
//
            [self Toast:@"Playback session is invalid. Maybe your account can stream only from one device at a time."];
//            [self signIn];
            return;
        }
        // Handle other kinds of errors.
    
        default:
            break;
    }
    if ([[error domain] isEqualToString: NSURLErrorDomain]) {
        NSString *errorDescription = [error.userInfo objectForKey:NSLocalizedDescriptionKey];
        
        if (!errorDescription) {
            errorDescription = NSLocalizedString(@"The track failed to play.", nil);
        }
        [self Toast:errorDescription];
        [self next];
        return;
    }
    NSString *errorDescription = [error.userInfo objectForKey:NSLocalizedDescriptionKey];
    
    if (!errorDescription) {
        errorDescription = NSLocalizedString(@"The track failed to play.", nil);
    }
    
    // Generic placeholder error alert.
//    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:errorDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
//    [alertView show];
    if ([errorDescription isEqualToString:@"unsupported URL"]) {
        [self next];
    }
    [self Toast:errorDescription];
}

- (void)signIn
{
    NSURL *authorizationUrl = [AppDelegate authorizationURL];
    NSString* address = [NKNapster loginUrlWithConsumerKey:self.napster.consumerKey
                                               redirectUrl:authorizationUrl];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:address]];
}

#pragma mark - Actions


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

- (IBAction)btnQueueClick:(id)sender {
    [self performSegueWithIdentifier:@"SegueToQueue" sender:self];
}




- (void)configureForPlayer
{
    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
    
    BOOL isStopped = player.playbackState == NKPlaybackStateStopped;
    
//    [[self playButton] setEnabled:!isStopped];
//    [[self previousButton] setEnabled:!isStopped && self.trackListPlayer.canSkipToPreviousTrack];
//    [[self nextButton] setEnabled:!isStopped && (self.trackListPlayer.canSkipToNextTrack || self.qtracks.count > 0)];
    [[self shuffleButton] setEnabled:!isStopped];
    [[self shuffleButton] setSelected:self.trackListPlayer.shuffling];
    [[self repeatButton] setEnabled:!isStopped];
    
    NSString* repeatButtonImageName = nil;
    switch (self.trackListPlayer.repeatMode) {
        case NKRepeatModeNone:
            repeatButtonImageName = @"RepeatAllIcon";
            break;
        case NKRepeatModeAllTracks:
            repeatButtonImageName = @"RepeatActive";
            break;
        case NKRepeatModeSingleTrack:
            repeatButtonImageName = @"RepeatActive";
            break;
    }
    if (![[self repeatButton] isEnabled]) {
        repeatButtonImageName = @"RepeatAllIcon";
    }
    [[self repeatButton] setImage:[UIImage imageNamed:repeatButtonImageName] forState:UIControlStateNormal];
    if (self.trackListPlayer.shuffling) {
        [[self shuffleButton] setImage:[UIImage imageNamed:@"ShuffleActive"] forState:UIControlStateNormal];
    } else {
        [[self shuffleButton] setImage:[UIImage imageNamed:@"Shuffle Icon"] forState:UIControlStateNormal];
    }
    
    
    
    [self configurePlayheadSlider];
    
    NKTrack *track = self.trackListPlayer.trackPlayer.currentTrack;
    [[self lblArtistName] setText:track.artist.name];
    [[self lblTrackName] setText:track.name];
    NSString *albumID = self.trackListPlayer.currentTrack.album.ID;
    NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/500x500.jpg", albumID];
    NSURL *url = [NSURL URLWithString:path];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *img = [[UIImage alloc] initWithData:data];

    [[self artistImageView] setImage:img];
    
    self.artistImageView.layer.masksToBounds = NO;
    self.artistImageView.layer.shadowRadius  = 30.0f;
    self.artistImageView.layer.shadowColor   = [UIColor colorWithRed:171.f/255.f green:183.f/255.f blue:193.f/255.f alpha:1.f].CGColor;
    self.artistImageView.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
    self.artistImageView.layer.shadowOpacity = 1.0f;

    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -20.0f, 0);
    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(self.artistImageView.bounds, shadowInsets)];
    self.artistImageView.layer.shadowPath    = shadowPath.CGPath;
    self.artistImageView.layer.cornerRadius =self.artistImageView.frame.size.height/15;
    self.artistImageView.layer.masksToBounds = YES;
    UIImage *blurredImage = [self blurredImageWithImage:img];
    [[self imgBackGround] setImage:blurredImage];
    self.imgMicBack.layer.cornerRadius =self.imgMicBack.frame.size.height/2;
    self.imgMicBack.layer.masksToBounds = true;
    [[self imgMicBack] setImage:blurredImage];
    BOOL isContain = [self isContainTrack:track];
    if (isContain) {
        [self.imgIsLibrary setImage:[UIImage imageNamed:@"Heart Icon Active"] forState:UIControlStateNormal];
    } else {
        [self.imgIsLibrary setImage:[UIImage imageNamed:@"Heart Icon"] forState:UIControlStateNormal];
    }
    
    if (player.playbackState == NKPlaybackStateStopped) return;
    path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/500x500.jpg", albumID];
    url = [NSURL URLWithString:path];
    data = [NSData dataWithContentsOfURL:url];
    img = [[UIImage alloc] initWithData:data];
        
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
        
}

- (BOOL) isContainTrack:(NKTrack*)track{
    
    for (NKTrack *obj in self.myLibrary) {
        if ([obj.ID isEqualToString:track.ID]) return YES;
    }
    return  NO;
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
    
   
    [[self currentTime] setText:[self stringFromTimeInterval:player.playheadPosition]];
    [[self trackTime] setText:[self stringFromTimeInterval:duration]];
}

//- (void)configureLevelsMeteringTimer
//{
//    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
//    switch (player.playbackState) {
//        case NKPlaybackStateStopped:
//        case NKPlaybackStateFinished:
//        case NKPlaybackStatePaused:
//        case NKPlaybackStateBuffering:
//            [[self levelsMeteringTimer] invalidate];
//            [self setLevelsMeteringTimer:nil];
//            [self configureLevelsMeter];
//            break;
//        case NKPlaybackStatePlaying:
//            if ([self levelsMeteringTimer]) return;
//            [self setLevelsMeteringTimer:[NSTimer timerWithTimeInterval:0.08 target:self selector:@selector(configureLevelsMeter) userInfo:nil repeats:YES]];
//            [[NSRunLoop currentRunLoop] addTimer:[self levelsMeteringTimer] forMode:NSRunLoopCommonModes];
//            break;
//    }
//}
//
//- (void)configureLevelsMeter
//{
//    float leftAverage;
//    float leftPeak;
//    float rightAverage;
//    float rightPeak;
//
//    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
//
//    [player leftChannelAverageDecibels:&leftAverage leftChannelPeakDecibels:&leftPeak rightChannelAverageDecibels:&rightAverage rightChannelPeakDecibels:&rightPeak];
//
//    float leftAverageAmplitude = [self amplitudeForDecibels:leftAverage];
//    float leftPeakAmplitude = [self amplitudeForDecibels:leftPeak];
//    float rightAverageAmplitude = [self amplitudeForDecibels:rightAverage];
//    float rightPeakAmplitude = [self amplitudeForDecibels:rightPeak];
//
//    static CGFloat leftAverageMaxHeight;
//    static CGFloat leftPeakMaxHeight;
//    static CGFloat rightAverageMaxHeight;
//    static CGFloat rightPeakMaxHeight;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        leftAverageMaxHeight = CGRectGetHeight([[self leftAverageMeter] frame]);
//        leftPeakMaxHeight = CGRectGetHeight([[self leftPeakMeter] frame]);
//        rightAverageMaxHeight = CGRectGetHeight([[self rightAverageMeter] frame]);
//        rightPeakMaxHeight = CGRectGetHeight([[self rightPeakMeter] frame]);
//    });
//
//    CGFloat leftAverageHeight = MAX(1, leftAverageAmplitude * leftAverageMaxHeight);
//    CGRect leftAverageFrame = [[self leftAverageMeter] frame];
//    leftAverageFrame.origin.y -= leftAverageHeight - leftAverageFrame.size.height;
//    leftAverageFrame.size.height = leftAverageHeight;
//    [[self leftAverageMeter] setFrame:leftAverageFrame];
//
//    CGFloat leftPeakHeight = MAX(1, leftPeakAmplitude * leftPeakMaxHeight);
//    CGRect leftPeakFrame = [[self leftPeakMeter] frame];
//    leftPeakFrame.origin.y -= leftPeakHeight - leftPeakFrame.size.height;
//    leftPeakFrame.size.height = leftPeakHeight;
//    [[self leftPeakMeter] setFrame:leftPeakFrame];
//
//    CGFloat rightAverageHeight = MAX(1, rightAverageAmplitude * rightAverageMaxHeight);
//    CGRect rightAverageFrame = [[self rightAverageMeter] frame];
//    rightAverageFrame.origin.y -= rightAverageHeight - rightAverageFrame.size.height;
//    rightAverageFrame.size.height = rightAverageHeight;
//    [[self rightAverageMeter] setFrame:rightAverageFrame];
//
//    CGFloat rightPeakHeight = MAX(1, rightPeakAmplitude * rightPeakMaxHeight);
//    CGRect rightPeakFrame = [[self rightPeakMeter] frame];
//    rightPeakFrame.origin.y -= rightPeakHeight - rightPeakFrame.size.height;
//    rightPeakFrame.size.height = rightPeakHeight;
//    [[self rightPeakMeter] setFrame:rightPeakFrame];
//}
//
//- (float)amplitudeForDecibels:(float)decibels
//{
//    return pow(10.0, 0.05 * decibels);
//}
//
//- (void)configureTrackProgressView
//{
//    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
//
//    [[self trackProgressView] setProgress:player.currentTrackAmountDownloaded];
//}



- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage{

    //  Create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];

    //  Setting up Gaussian Blur
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:7.2f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];

    /*  CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches
     *  up exactly to the bounds of our original image */
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];

    UIImage *retVal = [UIImage imageWithCGImage:cgImage];

    if (cgImage) {
        CGImageRelease(cgImage);
    }

    return retVal;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"SegueToQueue"]){
        QueueViewController *vc = (QueueViewController*)segue.destinationViewController;
//        vc.tracks = [self.trackListPlayer.tracks mutableCopy];
        vc.trackListPlayer = self.trackListPlayer;
//        vc.delegate = self.HomeVC;
        
        vc.currentTrack = self.trackListPlayer.currentTrack;
        vc.queue = [self.queue mutableCopy];
        if ([self.qtracks containsObject:vc.currentTrack]) {
            NSInteger index = [self.qtracks indexOfObject:vc.currentTrack];
            vc.nextTracks = [[self.qtracks subarrayWithRange:NSMakeRange(index + 1, self.qtracks.count - index - 1)] mutableCopy];
        } else {
            vc.nextTracks = [[self.qtracks subarrayWithRange:NSMakeRange(self.currentPlayItem + 1, self.qtracks.count - self.currentPlayItem - 1)] mutableCopy];
        }
        [vc setSavedtracks:self.tracks];
        vc.napster = self.napster;
        vc.playVC = self;
        vc.currentPlayItem = self.currentPlayItem;
        
        [self.napster.notificationCenter removeObserver:self];

        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}


- (IBAction)add2PLClick:(id)sender {
    [self add2Playlist:self.trackListPlayer.currentTrack];
}

- (IBAction)settingBtnClick:(id)sender {
    
    ShareView *shareView = [ShareView createViewFromNib];
    shareView.track = self.trackListPlayer.currentTrack;
    shareView.delegate = self;
    [shareView showInWindow];
}

- (IBAction)add2LibClick:(id)sender {
    [self add2Library:self.trackListPlayer.currentTrack];
}

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
    NKTrack *track = self.trackListPlayer.currentTrack;
    [self addTrack2PlayList:playlist.ID trackid:track];
    [self plistViewHide];
}

-(void) plistViewHide{
    [self.playlistView setHidden:YES];
    [self.maskView setHidden:YES];
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
//            TYAlertView *alertView = [TYAlertView alertViewWithTitle:@"ADD TO AN EXISTING PLAYLIST" message:@"Please select the playlist"];
//
//            for (PlayList *plist in self.playLists) {
//                [alertView addAction:[TYAlertAction actionWithTitle:plist.name style:TYAlertActionStyleDefault handler:^(TYAlertAction *action) {
//                    [self addTrack2PlayList:plist.ID trackid:track];
//                }]];
//            }
//
//            [alertView addAction:[TYAlertAction actionWithTitle:@"Cancel" style:TYAlertActionStyleDefault handler:^(TYAlertAction *action) {
//                [alertView hideInWindow];
//                NSLog(@"dssssssaaaa");
//            }]];
//
//            TYAlertController *alertController = [TYAlertController alertControllerWithAlertView:alertView preferredStyle:TYAlertControllerStyleActionSheet];
//            [alertView showInWindow];
//            [self presentViewController:alertController animated:YES completion:nil];
            
//            addView.track = track;
                   // use UIView Category
            [self.tblPlaylists reloadData];
            [self.playlistView setHidden:NO];
            [self.maskView setHidden:NO];
        });
        
        
    }] resume];
}



-(void)createPlaylist:(NSString*)name trackID:(NKTrack *)track{
    NSString *tokenString = [NSString stringWithFormat:@"Bearer %@", self.napster.session.token.accessToken];
            
    NSString *urlString = [NSString stringWithFormat:@"https://api.napster.com/v2.2/me/library/playlists"];
    NSURL *url = [NSURL URLWithString: urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
//    NKTrack *track = [self.tracks objectAtIndex:self.carousel.currentPlayItemIndex];
    
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
//        self.myLibrary = NSMutableArray.new;
//        self.myLibrary = [tempTracks mutableCopy];
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
                    [self.imgIsLibrary setImage:[UIImage imageNamed:@"Heart Icon Active"] forState:UIControlStateNormal];
                    [self.myLibrary addObject:track];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Add2LibSNotification" object:self];
                });
            }] resume];
        }
    }] resume];
    
    
    
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

#pragma mark destructuring

-(void)dealloc {
    [self.napster.notificationCenter removeObserver:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
