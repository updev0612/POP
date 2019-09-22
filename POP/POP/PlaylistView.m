//
//  PlaylistView.m
//  POP
//
//  Created by Ltiger on 9/2/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "PlaylistView.h"
#import "UIView+TYAlertView.h"
@implementation PlaylistView

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tblPlaylist
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"QueueCell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    NSInteger rowindex = indexPath.row;
//    NKTrack *track = [self.tracks objectAtIndex:indexPath.row];
//
//    NSString *albumID = track.album.ID;
//    NSString *path = [NSString stringWithFormat:@"https://api.napster.com/imageserver/v2/albums/%@/images/70x70.jpg", albumID];
//    NSURL *url = [NSURL URLWithString:path];
//    cell.artistImage.image = nil;
//
//    if ([self.imgCache objectForKey:url]) {
//        cell.artistImage.image = [self.imgCache objectForKey:url];
//    } else {
//        [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//
//            if (error!= nil) {
//                NSLog(@"%@", error);
//                return;
//            }
//
//            UIImage *imgAlbum = [[UIImage alloc] initWithData:data];
//            if (!imgAlbum) {
//                imgAlbum = [UIImage imageNamed:@"Background"];
//            }
//
//
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                UIImage *imageToCache = imgAlbum;
//
//                [self.imgCache setObject:imageToCache forKey:url];
//
//                cell.artistImage.image = imageToCache;
//            });
//        }] resume];
//    }
//    cell.settingBtn.tag = indexPath.row;
//    [cell.settingBtn addTarget:self action:@selector(cellButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//    cell.lblArtistName.text = track.artist.name;
//    cell.lblTrackName.text = track.name;
//    cell.artistImage.layer.cornerRadius = 7.5f;
//    cell.artistImage.clipsToBounds = YES;
//    cell.userInteractionEnabled = YES;
//    cell.exclusiveTouch = YES;
//    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

//- (void) cellButtonClicked: (id) sender {
//    UIButton *btn = (UIButton *) sender;
//    QueueCell *cell = (QueueCell *) [[btn superview] superview];
//    NSIndexPath *indexPath = [self.tblQueue indexPathForCell:cell];
//    NSLog(@"Btn's tag:  %ld", (long)indexPath.row);
//    NKTrack *track = [self.tracks objectAtIndex:indexPath.row];
//    [self.delegate cellButtonClicked:track];
////    ShareView *shareView = [ShareView createViewFromNib];
////
////    // use UIView Category
////    [shareView showInWindow];
//   //do something with indexPath...
//}

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//
//}

- (IBAction)btnCloseClick:(id)sender {
    [self setHidden:YES];
}
@end
