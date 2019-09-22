//
//  ViewController.m
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "ViewController.h"

#import "PlayViewController.h"
#import "NKSAlertView.h"
#import "NKSLoadingOverlay.h"
#import "NKTrackListPlayer.h"
#import "NKSNetworkActivityIndicatorController.h"
#import "NKSAppDelegate.h"
#import "NKAPI+Parsing.h"
#import "NKNapster+Extensions.h"
#import "MusicHomeViewController.h"

#   define CONSUMER_KEY     @"OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4"
#   define CONSUMER_SECRET  @"ODBmMmE3ODAtMDBhNy00MzIyLWJhMWYtNzA5Nzc5NDgzODc5"

#   define BASE_URL @"POP://authorize"

#define SIGN_URL  @"https://us.napster.com/pricing"

typedef enum : NSInteger {
    NKSRootViewControllerAlertViewAccessTokenFailure = 1,
    NKSRootViewControllerAlertViewMemberBenefits,
    NKSRootViewControllerAlertViewSignInOptions,
} NKSRootViewControllerAlertView;

@interface ViewController ()

@property (nonatomic, strong) NKTrackListPlayer    *trackListPlayer;

@property (nonatomic          ) NSMutableArray        *tracks;
@property (weak, nonatomic ) NKSLoadingOverlay      *loadingOverlay;

@property (strong,nonatomic) AppDelegate *appController;

@property (nonatomic, readonly) NKTrackPlayer        *player;

@end

@implementation ViewController
@synthesize btnCreate, btnConnect, stickImageView, napster;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.appController = (AppDelegate *)[[UIApplication sharedApplication] delegate];
       self.appController.delegate = self;
    [self prettyButtons];
    
//    self.trackListPlayer = [[NKTrackListPlayer alloc] initWithNapster:self.napster
//                 containerID:nil
//    andSequencingContextSize:2];
}

-(void) loginSuccess{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    MusicHomeViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];
    vc.napster = self.napster;
    
//    [(UINavigationController *)self.window.rootViewController pushViewController:vc animated:YES];
//    [self presentViewController:vc animated:YES completion:nil];
//    [self.navigationController pushViewController:vc animated:YES];
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
    [[self window] makeKeyAndVisible];
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.hidden = YES;
    _window.rootViewController = navController;
    
    NSLog(@"Success!");
}


-(void)viewWillDisappear:(BOOL)animated {
    NSLog(@"First viewWillDisappear");
    [super viewWillDisappear:animated];
    self.appController.delegate = nil;
}

- (IBAction)btnConnectClick:(id)sender {
    NSURL *authorizationUrl = [AppDelegate authorizationURL];
    NSString* address = [NKNapster loginUrlWithConsumerKey:self.napster.consumerKey
                                                redirectUrl:authorizationUrl];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:address]];
    
    
    
//    NSString * storyboardName = @"Main";
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
//    PlayViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];


//    [self presentViewController:vc animated:YES completion:nil];
    
    
    
    
    
//    if ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:address]]) {
//        NSString * storyboardName = @"Main";
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
//        PlayViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"PlayVC"];
//        vc.napster = self.napster;
//        [self presentViewController:vc animated:YES completion:nil];
//    } else {
//        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Signed In Failed", nil) message:NSLocalizedString(@"Sign in failed.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
//    }

    
    
    
}

- (IBAction)btnCreateClick:(id)sender {
    
//    [self playViewController:vc animated:YES completion:nil];
//    [self.navigationController pushViewController:vc animatied:YES];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:SIGN_URL]];
    
    
}

-(void)prettyButtons{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    btnConnect.layer.cornerRadius = btnConnect.frame.size.height/15;
    btnConnect.layer.masksToBounds = true;
    gradient.frame = btnConnect.bounds;
    gradient.colors = @[(id)[UIColor colorWithRed:131/255.0 green:114/255.0 blue:246/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:88/255.0 green:170/255.0 blue:252/255.0 alpha:1.0].CGColor];
    gradient.startPoint = CGPointMake(0, 0.5);
    gradient.endPoint = CGPointMake(1, 0.5);
    
    [btnConnect.layer insertSublayer:gradient atIndex:0];
    //[btnConnect.titleLabel setTextColor:[UIColor whiteColor]];
    [self.view layoutIfNeeded];
    
    CAGradientLayer *gradientBG = [CAGradientLayer layer];
    gradientBG.frame = btnCreate.bounds;
    gradientBG.colors = @[(id)[UIColor colorWithRed:131/255.0 green:114/255.0 blue:246/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:88/255.0 green:170/255.0 blue:252/255.0 alpha:1.0].CGColor];
    gradientBG.startPoint = CGPointMake(0, 0.5);
    gradientBG.endPoint = CGPointMake(1, 0.5);
    
    [btnCreate.layer insertSublayer:gradientBG atIndex:0];
    [btnCreate setMaskView:btnCreate.titleLabel];
    
    CAGradientLayer *gradientStick = [CAGradientLayer layer];
    gradientStick.frame = stickImageView.bounds;
    gradientStick.colors = @[(id)[UIColor colorWithRed:131/255.0 green:114/255.0 blue:246/255.0 alpha:1.0].CGColor, (id)[UIColor colorWithRed:88/255.0 green:170/255.0 blue:252/255.0 alpha:1.0].CGColor];
    gradientStick.startPoint = CGPointMake(0, 0.5);
    gradientStick.endPoint = CGPointMake(1, 0.5);
    [stickImageView.layer insertSublayer:gradientStick atIndex:0];
    
    [self.view layoutIfNeeded];
    
}

@end
