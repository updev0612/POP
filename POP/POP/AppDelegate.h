//
//  AppDelegate.h
//  FirstNapsterMusicApp
//
//  Created by Ltiger on 8/15/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <NapsterKit/NapsterKit.h>

@protocol AuthoDelegate <NSObject>

- (void) loginSuccess;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

//@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (nonatomic) UIWindow* window;

@property (nonatomic, weak) id<AuthoDelegate> delegate;

//-(instancetype)initWithNapster:(NKNapster*)napster andNibNamed:(NSString*)nibName;

+ (AppDelegate*)appDelegate;

+ (NSURL*) authorizationURL;
//
//- (void)saveContext;


@end

