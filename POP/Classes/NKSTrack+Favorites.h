//
//  NKSTrack+Favorites.h
//  Track Playback Sample
//
//  Created by Emanuel Kotzayan on 9/7/16.
//  Copyright © 2016 Napster International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NapsterKit/NKPreviewTrack.h>
#import <NapsterKit/NapsterKit.h>

@interface NKTrack (Favorites)

+(instancetype)parseFromFavoriteJson:(NSDictionary*)json;

@end
