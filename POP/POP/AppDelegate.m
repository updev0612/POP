//
//  AppDelegate.m
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "NKSNetworkActivityIndicatorController.h"
#import "NKSAppDelegate.h"
#import "NSDictionary+NKSExtensions.h"
#import "NKTrackListPlayer.h"
#import <NapsterKit/NKNapster.h>
#import "ViewController.h"
#import "PlayViewController.h"
#import "MusicHomeViewController.h"
#import <AVFoundation/AVFoundation.h>

#   define CONSUMER_KEY     @"OTY4Y2JmMTUtMzAzNS00ZDczLThjZDQtNzlkNDU2MTRmZDc4"
#   define CONSUMER_SECRET  @"ODBmMmE3ODAtMDBhNy00MzIyLWJhMWYtNzA5Nzc5NDgzODc5"

#define BASE_URL @"POP://authorize"
#define SIGN_URL  @"https://us.napster.com/pricing"



@interface AppDelegate () <NSURLSessionDelegate, UIAlertViewDelegate>

@property (nonatomic, strong  ) NKNapster     *napster;
@property (nonatomic, readonly) NKTrackPlayer  *player;
@property (nonatomic, strong)   ViewController *viewController;
@property (nonatomic, strong)   PlayViewController *playViewController;
@property (nonatomic, strong)   MusicHomeViewController *homeViewController;
@property (assign, nonatomic) BOOL shouldResumePlaybackAtInterruptionEnd;
@property  BOOL isSuccess;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString* consumerKey = CONSUMER_KEY;
    NSString* consumerSecret = CONSUMER_SECRET;

    NKNapster *napster = [NKNapster napsterWithConsumerKey:consumerKey
                                                  consumerSecret:consumerSecret
                                            sessionCachingPolicy:NKSessionCachingPolicy.defaultPolicy
                                              notificationCenter:[NSNotificationCenter defaultCenter]
                            ];
    
    self.napster = napster;
//    [self.napster closeSession];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
    [[self window] makeKeyAndVisible];
    
    
    
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];

    UINavigationController* navController;
    if (napster.isSessionOpen) {
        _homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];
        _homeViewController.napster = self.napster;

        navController = [[UINavigationController alloc] initWithRootViewController:_homeViewController];
    } else {
        _viewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginVC"];
        _viewController.napster = self.napster;
        navController = [[UINavigationController alloc] initWithRootViewController:_viewController];
    }
    navController.navigationBar.hidden = YES;
   _window.rootViewController = navController;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:NKNotificationPlaybackStateChanged object:nil];
    
    return YES;
}

+ (AppDelegate*)appDelegate
{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
    [self refreshAccessToken];
}

+ (NSURL*)authorizationURL {
    return [NSURL URLWithString:BASE_URL];
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    NSLog(@"Received URL: %@", url);
    self.isSuccess = NO;
    __weak typeof (self) weakSelf = self;
    if (![[url scheme] hasPrefix:@"pop"]) return NO;
    
    if ([[url host] isEqual:@"authorization-canceled"]) return YES;

    void (^showErrorLoggingIn)(void) = ^() {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In Failed", nil) message:NSLocalizedString(@"The sign in request failed.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertView show];
    };
    
    
    if ([[url host] isEqual:@"authorize"]) {
        NSDictionary* params = [NSDictionary rs_dictionaryWithQuery:[url query]];
        
        [self handleAuthenticationResponse:params onError:showErrorLoggingIn];
        return YES;
    }
    
    if ([[url host] isEqual:@"authorization-failed"]) {
        showErrorLoggingIn();
        return YES;
    }
    
    return NO;
}

- (void)handleAuthenticationResponse:(NSDictionary*)response onError:(void(^)(void))onError {
    NSString *code = [response objectForKey:@"code"];
    
    [self.napster openSessionWithOAuthCode:code
                                    baseURL:[NSURL URLWithString:BASE_URL]
                          completionHandler:^(NKSession *session, NSError *error) {
        NSLog(@"session check");
        if (!session) {
            onError();
            return;
        }
//        [self refreshAccessToken];
//        self.viewController.napster = self.napster;
//        dispatch_async(dispatch_get_main_queue(), ^{
// self.isSuccess = YES;
        
//        });
//        self->_homeViewController.napster = self.napster;
        
//
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"SignedIn" object:self];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Signed In", nil) message:NSLocalizedString(@"You have successfully signed in.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];

        [alertView show];
        
    }];
    
}

//- (void) receiveSignInNotification:(NSNotification *) notification
//{
//    NSString * storyboardName = @"Main";
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
//        MusicHomeViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];
//        vc.napster = self.napster;
//
//    //    [(UINavigationController *)self.window.rootViewController pushViewController:vc animated:YES];
//        [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
//}


-(void) loginSuccess{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    
    MusicHomeViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];
    vc.napster = self.napster;
//    [(UINavigationController *)self.window.rootViewController pushViewController:vc animated:YES];
    [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
}




- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
//        NSString * storyboardName = @"Main";
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
////        MusicHomeViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];
////        vc.napster = self.napster;
//
//        _homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeVC"];
//        _homeViewController.napster = self.napster;
//        UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:_homeViewController];
//        navController.navigationBar.hidden = YES;
//        _window.rootViewController = navController;
//        [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
//        [(UINavigationController *)self.window.rootViewController pushViewController:vc animated:YES];
        [self.delegate loginSuccess];
    }
}


- (void)beginInterruption
{
    NSLog(@"Audio session interruption began.");
    switch (self.player.playbackState) {
        case NKPlaybackStateStopped:
        case NKPlaybackStateFinished:
        case NKPlaybackStatePaused:
            return;
        case NKPlaybackStateBuffering:
        case NKPlaybackStatePlaying:
            [self setShouldResumePlaybackAtInterruptionEnd:YES];
            [self.player pausePlayback];
            return;
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
    NSLog(@"Audio session interruption ended.");
    if (![self shouldResumePlaybackAtInterruptionEnd]) return;
    [self setShouldResumePlaybackAtInterruptionEnd:NO];
    if (flags != AVAudioSessionInterruptionOptionShouldResume) return;
    [self.player resumePlayback];
}

#pragma mark - Audio route change

- (void) audioRouteChangeListenerCallback:(NSNotification*)notification
{
    // Pause when switching to the internal speaker, i.e. unplugging headphones.
    @autoreleasepool {
        NSUInteger reason = [[notification userInfo][AVAudioSessionRouteChangeReasonKey] integerValue];
        if (reason != AVAudioSessionRouteChangeReasonOldDeviceUnavailable) return;

        AVAudioSessionRouteDescription* currentRoute = [[AVAudioSession sharedInstance] currentRoute];

        NSArray* outputs = [currentRoute outputs];

        for (AVAudioSessionPortDescription* output in outputs) {
            NSString* portType = [output portType];

            if ([portType isEqualToString: AVAudioSessionPortBuiltInSpeaker]) {
                continue;
            }

            switch (self.player.playbackState) {
                case NKPlaybackStateStopped:
                case NKPlaybackStateFinished:
                case NKPlaybackStatePaused:
                    return;
                case NKPlaybackStateBuffering:
                case NKPlaybackStatePlaying:
                    NSLog(@"Pausing playback because of switch to internal speaker.");
                    [self.player pausePlayback];
                    return;
            }

        }
    }
}

#pragma mark - Remote control

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
    switch ([event subtype]) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            switch (self.player.playbackState) {
                case NKPlaybackStateStopped:
                case NKPlaybackStateFinished:
                    break;
                case NKPlaybackStatePaused:
                    [self.player resumePlayback];
                    break;
                case NKPlaybackStatePlaying:
                case NKPlaybackStateBuffering:
                    [self.napster.player pausePlayback];
                    break;
            }
            break;
        case UIEventSubtypeRemoteControlNextTrack:
//            [self.homeViewController next];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
//            [self.homeViewController previous];
            break;
        default:
            break;
    }
}

#pragma mark - Notification handlers

- (void)playbackStateChanged:(NSNotification*)notification
{
    switch ([self.player playbackState]) {
        case NKPlaybackStateBuffering:
        case NKPlaybackStatePaused:
        case NKPlaybackStateFinished:
            return;
        case NKPlaybackStatePlaying: {
            NSError* sessionActivationError = nil;
            BOOL activatedSession = [[AVAudioSession sharedInstance] setActive:YES error:&sessionActivationError];
            if (!activatedSession) {
                NSLog(@"Failed to activate audio session: %@", sessionActivationError);
                return;
            }

            NSError* sessionCategorizationError = nil;
            BOOL categorizedSession = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionCategorizationError];
            if (!categorizedSession) {
                NSLog(@"Failed to set audio session category: %@", sessionCategorizationError);
                return;
            }

            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(audioRouteChangeListenerCallback:)
                                                         name:AVAudioSessionRouteChangeNotification
                                                       object: [AVAudioSession sharedInstance]];

            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            return;
        }
        case NKPlaybackStateStopped: {
            [[UIApplication sharedApplication] endReceivingRemoteControlEvents];


            [[AVAudioSession sharedInstance] setActive:NO error:NULL];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:NULL];
            [[NSNotificationCenter defaultCenter] removeObserver: self name: AVAudioSessionRouteChangeNotification object: [AVAudioSession sharedInstance]];
            return;
        }
    }
}

#pragma mark - Authentication

- (void)refreshAccessToken
{
    if (self.napster.isSessionOpen) {
        [self.napster refreshSessionWithCompletionHandler:^(NKSession *session, NSError *error) {
            if (!session) {
                // ... some error happened
            }
        }];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application{
    [self.napster closeSession];
    [self.napster.notificationCenter removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"Terminating");
}

- (NSString*)stringByEscapingURLQueryComponent:(NSString*)key
{
    NSString *result = key;

    CFStringRef originalAsCFString = (__bridge CFStringRef) key;
    CFStringRef leaveAlone = CFSTR(" ");
    CFStringRef toEscape = CFSTR("\n\r\"?[]()$,!'*;:@&=#%+/");

    CFStringRef escapedStr;
    escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalAsCFString, leaveAlone, toEscape, kCFStringEncodingUTF8);

    if (escapedStr) {
        NSMutableString *mutable = [NSMutableString stringWithString:(__bridge_transfer NSString *) escapedStr];

        [mutable replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [mutable length])];
        result = mutable;
    }
    return result;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)){
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


#pragma mark - Core Data stack

//@synthesize persistentContainer = _persistentContainer;
//
//- (NSPersistentContainer *)persistentContainer {
//    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
//    @synchronized (self) {
//        if (_persistentContainer == nil) {
//            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"FirstNapsterMusicApp"];
//            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
//                if (error != nil) {
//                    // Replace this implementation with code to handle the error appropriately.
//                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//                    /*
//                     Typical reasons for an error here include:
//                     * The parent directory does not exist, cannot be created, or disallows writing.
//                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                     * The device is out of space.
//                     * The store could not be migrated to the current model version.
//                     Check the error message to determine what the actual problem was.
//                    */
//                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
//                    abort();
//                }
//            }];
//        }
//    }
//
//    return _persistentContainer;
//}

#pragma mark - Core Data Saving support

//- (void)saveContext {
//    NSManagedObjectContext *context = self.persistentContainer.viewContext;
//    NSError *error = nil;
//    if ([context hasChanges] && ![context save:&error]) {
//        // Replace this implementation with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
//        abort();
//    }
//}

@end
