//
//  abstracted_display_objc.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 5/3/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AbstractedDisplay <NSObject>

- (void) ad_clear;
- (void) ad_draw_atY:(int)y X:(int)x ch:(char) ch;
- (void) ad_init_atY:(int)y X:(int)x ch:(char) ch;
- (void) ad_init_completed;
- (void) ad_move_ch:(char)ch fromY:(int)y fromX:(int)x toY:(int)ny toX:(int)nx replace:(char)replace newch:(char)nch sound:(char)sound hint:(int)hint;
- (void) ad_refresh;
- (void) ad_score:(long)score;
- (void) ad_diamondsNotFound:(int) nf total:(int)total;
- (void) ad_maxmoves:(int)maxmoves;
- (void) ad_monster:(int)monsterg;
- (void) ad_screen_number:(int)n;
- (void) ad_screen_name:(char *)name;
- (void) ad_sound:(char) sound;



@end


