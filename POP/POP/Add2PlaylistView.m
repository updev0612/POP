//
//  Add2PlaylistView.m
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import "Add2PlaylistView.h"
#import "UIView+TYAlertView.h"
@implementation Add2PlaylistView

- (IBAction)cancelAction:(id)sender {
    // hide view,or dismiss controller
    [self hideView];
}

- (IBAction)addAction:(id)sender {
    // hide view,or dismiss controller
    NSLog(@"go2Artist");
    
    [self hideView];
    
    [self.delegate add2ExistPL:self.track];
    
}

- (IBAction)createAction:(id)sender {
    // hide view,or dismiss controller
    NSLog(@"go2Artist");
    [self hideView];
    
    [self.delegate createPL:self.track];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
