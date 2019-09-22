//
//  QueueViewController.m
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "QueueViewController.h"
#import "QueueCell.h"
#import "NKNapster+Extensions.h"
#import "ShareView.h"
#import "UIView+TYAlertView.h"
#import "PlaylistView.h"
#import "CustomIOSAlertView.h"
#import "PlaylistCell.h"
#import "PlayList.h"
#import "Add2PlaylistView.h"
#import "UIView+TYAlertView.h"
#import "TYAlertController+BlurEffects.h"
#import "CreatePlaylistView.h"


@interface QueueViewController () <UITableViewDelegate, UITableViewDataSource, Add2PLDelegate, CreatePLDelegate, QueueDelegate, SettingDelegate>

@property NSCache *imgCache;

@property (weak, nonatomic) IBOutlet UITableView *tblQueue;

@property NSInteger currentIndex;

@property (weak, nonatomic) IBOutlet UIView *playlistView;
@property (weak, nonatomic) IBOutlet UITableView *tblPlaylists;
- (IBAction)btnCloseClick:(id)sender;

//- (IBAction)toggleEdit:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *maskView;
@property NKTrack *tempTrack;
@property NSMutableArray *playLists;
@property NSInteger offset;
@end

@implementation QueueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   
    [self.tblQueue reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTrackIndexDidChange:) name:NKTrackListNotificationCurrentTrackChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:NKNotificationPlaybackStateChanged object:nil];
    
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
    self.offset = self.currentPlayItem;
    self.currentPlayItem = 0;
}


- (void)currentTrackIndexDidChange:(NSNotification*)notification {
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    NSInteger count;
    if (tableView == self.tblQueue) {
        if (self.queue.count > 0) {
            count = 3;
        } else {
            count = 2;
        }
    } else{
        count = 1;
    }
    return count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count;
    if (tableView == self.tblQueue) {
        if (section == 0) {
            count = 1;
        } else if (section == 1) {
            if (self.queue.count > 0) {
                count = self.queue.count;
            } else {
                count = self.nextTracks.count;
            }
        } else{
            if (self.queue.count > 0) {
                count = self.nextTracks.count;
            } else {
                count = 0;
            }
        }
    } else{
        count = self.playLists.count;
    }
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *header = NSString.new;
    if (tableView == self.tblQueue) {
        if (section == 0) {
            header = @"Now Playing";
        } else if (section == 1) {
            
            if (self.queue.count > 0) {
                header = @"Next from Queue";
            } else {
                header = @"Next from Playlist";
            }
        } else {
            header = @"Next from Playlist";
        }
    } else {
        header = nil;
    }
    return header;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == self.tblQueue) {
    
        QueueCell* cell = [tableView dequeueReusableCellWithIdentifier:@"QueueCell"];
        NKTrack *track;
        if (indexPath.section == 0) {
            track = self.currentTrack;
        } else if (indexPath.section == 1){
            if (self.queue.count > 0) {
                track = [self.queue objectAtIndex:indexPath.row];
            } else {
                track = [self.nextTracks objectAtIndex:indexPath.row];
            }
            
        } else {
            track = [self.nextTracks objectAtIndex:indexPath.row];
        }
        
        
        NSString *albumID = track.album.ID;
        NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/70x70.jpg", albumID];
        NSURL *url = [NSURL URLWithString:path];
        cell.artistImage.image = nil;
        
        if ([self.imgCache objectForKey:url]) {
            cell.artistImage.image = [self.imgCache objectForKey:url];
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
                    
                    cell.artistImage.image = imageToCache;
                });
            }] resume];
        }
        cell.settingBtn.tag = indexPath.row;
        [cell.settingBtn addTarget:self action:@selector(cellButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        cell.lblArtistName.text = track.artist.name;
        cell.lblTrackName.text = track.name;
        cell.artistImage.layer.cornerRadius = 7.5f;
        cell.artistImage.clipsToBounds = YES;
        cell.userInteractionEnabled = YES;
        cell.exclusiveTouch = YES;
    //    [self configureCell:cell atIndexPath:indexPath];
        return cell;
    } else{
        PlaylistCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistCell"];
        PlayList *playlist = [self.playLists objectAtIndex:indexPath.row];
        [cell.button setTitle:playlist.name forState:UIControlStateNormal];
        cell.button.tag = 100 + indexPath.row;
        [cell.button addTarget:self action:@selector(playlistButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (void) cellButtonClicked: (id) sender {
    UIButton *btn = (UIButton *) sender;
    QueueCell *cell = (QueueCell *) [[btn superview] superview];
    NSIndexPath *indexPath = [self.tblQueue indexPathForCell:cell];
    NSLog(@"Btn's tag:  %ld", (long)indexPath.row);
    NKTrack *track = [self.tracks objectAtIndex:indexPath.row];
    if (indexPath.section == 0) {
        track = self.currentTrack;
    } else if (indexPath.section == 1){
        if (self.queue.count>0) {
            track = [self.queue objectAtIndex:indexPath.row];
        } else {
            track = [self.nextTracks objectAtIndex:indexPath.row];
        }
        
    } else {
        track = [self.nextTracks objectAtIndex:indexPath.row];
    }
    self.tempTrack = track;
    ShareView *shareView = [ShareView createViewFromNib];
    shareView.track = track;
    shareView.delegate = self;
    [shareView showInWindow];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (self.queue.count > 0 ) {
            self.currentTrack = [self.queue objectAtIndex:indexPath.row];
            [self.trackListPlayer playTrack:self.currentTrack];
//            [self.queue removeObjectAtIndex:indexPath.row];
            [self.queue removeObjectsInArray:[self.queue subarrayWithRange:NSMakeRange(0, indexPath.row + 1)]];
        } else {
            self.currentTrack = [self.nextTracks objectAtIndex:indexPath.row];
            [self.nextTracks removeObjectsInArray:[self.nextTracks subarrayWithRange:NSMakeRange(0, indexPath.row + 1)]];
            [self.trackListPlayer playTrack:self.currentTrack];
//            self.currentPlayItem = indexPath.row;
        }
    } else if (indexPath.section == 2){
        self.currentTrack = [self.nextTracks objectAtIndex:indexPath.row];
        [self.nextTracks removeObjectsInArray:[self.nextTracks subarrayWithRange:NSMakeRange(0, indexPath.row + 1)]];
        [self.trackListPlayer playTrack:self.currentTrack];
//        self.currentPlayItem = indexPath.row;
    }
    [self.tblQueue reloadData];
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
    if ([sourceIndexPath isEqual:destinationIndexPath]) return;
        
    NKTrack* movedTrack = [[self tracks] objectAtIndex:[sourceIndexPath row]];
    NSInteger sourceRow = sourceIndexPath.row;
    NSInteger destinationRow = destinationIndexPath.row;
    [self.tracks removeObjectAtIndex:sourceRow];
    [self.tracks insertObject:movedTrack atIndex:destinationRow];

    self.trackListPlayer.tracks = self.tracks;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (IBAction)btnBackClick:(id)sender {
    self.playVC.queue = NSMutableArray.new;
    self.playVC.queue = [self.queue mutableCopy];
    self.playVC.currentPlayItem = self.currentPlayItem + self.offset;
    [self.playVC setTracks:self.savedtracks];
    self.playVC.trackListPlayer = self.trackListPlayer;
    [self.playVC configureForPlayer];
    [self.playVC addingNotifications];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}






- (IBAction)settingBtnTapped:(id)sender {
}

- (void) receiveSettingNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"Add2PLSNotification"])
        [self Toast:@"Added to Playlist."];
    if ([[notification name] isEqualToString:@"Add2LibSNotification"])
        [self Toast:@"Added to Library."];
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



- (IBAction)btnCloseClick:(id)sender {
    [self plistViewHide];
}

- (void) playlistButtonClicked: (id) sender {
    UIButton *btn = (UIButton *) sender;
    PlaylistCell *cell = (PlaylistCell *) [[btn superview] superview];
    NSIndexPath *indexPath = [self.tblPlaylists indexPathForCell:cell];
    NSLog(@"Btn's tag:  %ld", (long)indexPath.row);
    PlayList *playlist = [self.playLists objectAtIndex:indexPath.row];
    
    [self addTrack2PlayList:playlist.ID trackid:self.tempTrack];
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
        [self.tblQueue reloadData];
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

#pragma mark Player Setting

- (void)playbackStateDidChange:(NSNotification*)notification
{
    NKTrackPlayer *player = self.trackListPlayer.trackPlayer;
    if (player.playbackState == NKPlaybackStateFinished){
        if (self.queue.count > 0) {
            NKTrack *track = [self.queue firstObject];
            [self.trackListPlayer playTrack:track];
            [self.queue removeObjectAtIndex:0];
            self.currentTrack = track;

            
        } else {
//            self.currentPlayItem++;
//            if (self.currentPlayItem > self.nextTracks.count-1) {
//                self.currentPlayItem = 0;
//            }
            NKTrack *track = [self.nextTracks objectAtIndex:self.currentPlayItem];
            self.currentTrack = track;
            [self.nextTracks removeObject:track];
            [self.trackListPlayer playTrack:track];
        }
    }
    
    [self.tblQueue reloadData];
}


#pragma mark destructuring

-(void)dealloc {
   
    [self.napster.notificationCenter removeObserver:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
