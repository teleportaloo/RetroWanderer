//
//  abstracted_display.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 5/3/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#ifndef abstracted_display_h
#define abstracted_display_h



#include <stdio.h>

enum
{
    Hint_Slow,
    Hint_Fast
};



void ad_clear();
void ad_draw_at(int y, int x, char ch);
void ad_move(int y, int x);
void ad_move_ch(char ch, int y, int x, int ny, int nx, char replace, char nch, char sound, int hint);
void ad_addch(char ch);
void ad_addch_init(char ch);
void ad_init_completed();
void ad_refresh();
void ad_sound(char sound);
void ad_score(long score);
void ad_diamonds(int nf, int total);
void ad_maxmoves(int maxmoves);
void ad_monster(int monster);
void ad_screen_number(int n);
void ad_screen_name(char *name);



#endif /* abstracted_display_h */
