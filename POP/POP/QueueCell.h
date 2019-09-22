//
//  QueueCell.h
//  POP
//
//  Created by Ltiger on 8/31/19.
//  Copyright © 2019 Logikosoft Technologies LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QueueCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *artistImage;
@property (weak, nonatomic) IBOutlet UILabel *lblArtistName;
@property (weak, nonatomic) IBOutlet UILabel *lblTrackName;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;


@end

NS_ASSUME_NONNULL_END
