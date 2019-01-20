//
//  SimpleTextDisplay.m
//  Text Wanderer
//
//  Created by Andrew Wallace on 5/3/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "SimpleTextDisplay.h"

extern "C"
{
extern void ad_set_display(id<AbstractedDisplay> display);
}

@implementation SimpleTextDisplay



- (instancetype)init {
    if ((self = [super init]))
    {
        ad_set_display(self);
        [self ad_clear];
    }
    return self;
}


- (void) ad_clear
{
    int x;
    for (int y=0; y<kHeight; y++)
    {
        for (x =0; x<kWidth; x++)
        {
            _screen[y][x]=' ';
        }
        _screen[y][x] = '\0';
    }
}

- (void) ad_move_ch:(char)ch fromY:(int)y fromX:(int)x toY:(int)ny toX:(int)nx replace:(char)replace newch:(char)nch sound:(char)sound hint:(int)hint
{
    unichar uch = ch;
    if (nch)
    {
        uch = nch;
    }
    unichar urep = replace;
    
    if (ny<kHeight && nx<kWidth)
    {
        _screen[ny][nx] = uch;
    }
    
    if (y<kHeight && x<kWidth)
    {
        _screen[y][x] = urep;
    }
    
    
}

- (void) ad_draw_atY:(int)y X:(int)x ch:(char) ch
{
    unichar uch = ch;
    
    if (y<kHeight && x<kWidth)
    {
        _screen[y][x] = uch;
    }
}

- (void) ad_init_atY:(int)y X:(int)x ch:(char) ch
{
    [self ad_draw_atY:y X:x ch:ch];
}

- (void)ad_init_completed
{
    
}

- (bool)runSyncOnMainQueueWithoutDeadlocking:(void (^)(void))block
{
    static dispatch_once_t onceTokenAndKey;
    static void *contextValue = (void*)1;
    
    dispatch_once(&onceTokenAndKey, ^{
        dispatch_queue_main_t queue = dispatch_get_main_queue();
        dispatch_queue_set_specific (queue, &onceTokenAndKey, contextValue, NULL);
    });
    
    bool background = NO;
    if (dispatch_get_specific (&onceTokenAndKey) == contextValue)
    {
        block ();
    }
    else
    {
        background = YES;
        dispatch_sync (dispatch_get_main_queue(), block);
    }
    
    return background;
}

- (bool)updateLabel:(UILabel *)label text:(NSString *)text
{
    return [self runSyncOnMainQueueWithoutDeadlocking:^{
        if (label)
        {
            label.text = text;
        }
    }];
}

- (void) ad_refresh
{
    NSMutableString *str = [NSMutableString string];
    
    for (int y=0; y<kHeight; y++)
    {
        [str appendFormat:@"%S\n", (const unichar *)_screen[y]];
        // NSLog(@"%s", display[y]);
    }
    
    if ([self updateLabel:self.mainLabel text:str])
    {
        usleep(1000);
    }
}

- (void) ad_score:(long)score
{
     [self updateLabel:self.scoreLabel  text:[NSString stringWithFormat:@"Score %ld", score]];
}

- (void) ad_diamondsNotFound:(int) nf total:(int)total
{
    [self updateLabel:self.diamondsLabel  text:[NSString stringWithFormat:@"Diamonds: %d/%d", nf, total]];
}

- (void) ad_maxmoves:(int)maxmoves
{
    if (maxmoves >= 0)
    {
        [self updateLabel: self.maxMovesLabel  text:[NSString stringWithFormat:@"Max moves: %d", maxmoves]];
    }
    else
    {
        [self updateLabel: self.maxMovesLabel  text:@"Unlimited moves"];
        self.maxMovesLabel.text = @"Unlimited moves";
    }
}

- (void) ad_monster:(int)monster
{
    if (monster)
    {
        [self updateLabel:self.monsterLabel  text:@"Monster alert!"];
    }
    else
    {
        [self updateLabel:self.monsterLabel  text:@""];
    }
}

- (void) ad_screen_number:(int)n
{
    [self updateLabel:self.screenNumberLabel  text:[NSString stringWithFormat:@"Current Level: %d", n]];
}

- (void) ad_screen_name:(char *)name
{
    [self updateLabel:self.self.nameLabel  text:[NSString stringWithFormat:@"%s", name]];
}

- (void) ad_sound:(char)sound
{
    
}

@end
