//
//  CreatePlaylistView.m
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "CreatePlaylistView.h"
#import "UIView+TYAlertView.h"

@implementation CreatePlaylistView


- (IBAction)cancelAction:(id)sender {
    // hide view,or dismiss controller
    [self hideView];
}

- (IBAction)createAction:(id)sender {
    // hide view,or dismiss controller
    NSLog(@"go2Artist");
    [self hideView];
    
    [self.delegate createPL:self.txtPlaylist.text trackID:self.track];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
