//
//  MusicHomeViewController.h
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NapsterKit/NapsterKit.h>
#import "NKTrackListPlayer.h"
#import "MBProgressHUD.h"
#import "iCarousel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MusicHomeViewController : UIViewController <UIScrollViewDelegate, iCarouselDataSource, iCarouselDelegate, UIAlertViewDelegate, NSURLSessionDataDelegate, NSURLSessionDelegate>{
    NSURLSession *session;
    NSURLSessionDataTask *sessionDataTask ;
    NSURLSessionTask *sessionTask;
}

@property (nonatomic, strong) NKNapster *napster;

@property (nonatomic) UIWindow* window;

@property NSInteger catIndex;

@property NSString *subCode;

@property (nonatomic, assign) NSInteger currentItem;

@property (nonatomic, assign) NSInteger currentPlayItem;

@property (nonatomic) NSMutableArray *imageArray;

@property (weak, nonatomic) NSMutableArray *miniImageArray;

@property (nonatomic          ) NSMutableArray        *queue;
@property (nonatomic          ) NSMutableArray        *myLibrary;

@property BOOL isMiniPlayerClicked;

-(void) next;
-(void) previous;

- (void)setTrackListPlayer:(NKTrackListPlayer *)trackListPlayer;





@end

NS_ASSUME_NONNULL_END
