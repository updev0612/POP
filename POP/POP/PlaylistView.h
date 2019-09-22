//
//  PlaylistView.h
//  POP
//
//  Created by Ltiger on 9/2/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlaylistView : UIView

- (IBAction)btnCloseClick:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *tblPlaylists;

@end

NS_ASSUME_NONNULL_END
