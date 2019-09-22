//
//  ViewController.h
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NapsterKit/NapsterKit.h>
#import "AppDelegate.h"
#import "MusicHomeViewController.h"

@interface ViewController : UIViewController <AuthoDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UIButton *btnCreate;
@property (weak, nonatomic) IBOutlet UIImageView *stickImageView;
@property (nonatomic) UIWindow* window;

@property (weak, nonatomic) MusicHomeViewController *homeViewController;
@property (nonatomic, strong) NKNapster *napster;


- (IBAction)btnConnectClick:(id)sender;

- (IBAction)btnCreateClick:(id)sender;




-(void)prettyButtons;

@end

