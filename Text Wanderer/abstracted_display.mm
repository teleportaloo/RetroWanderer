//
//  abstracted_display.c
//  Text Wanderer
//
//  Created by Andrew Wallace on 5/3/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import <UIKit/UIKit.h>

extern "C"
{
#include "abstracted_display.h"
}
#include "abstracted_display_objc.h"

static id<AbstractedDisplay> disp;

static int xPos = 0;
static int yPos = 0;

extern "C"
{
void ad_set_display(id<AbstractedDisplay> display) {
    disp = display;
}
}

void ad_clear() {
    [disp ad_clear];
}

void ad_move_ch(char ch, int y, int x, int ny, int nx, char replace, char nch, char sound, int hint) {
    [disp ad_move_ch:ch fromY:y fromX:x toY:ny toX:nx replace:replace newch:nch sound:sound hint:hint];
}

void ad_move(int y, int x) {
    yPos = y;
    xPos = x;
}

void ad_addch(char ch) {
    [disp ad_draw_atY:yPos X:xPos ch:ch];
    xPos++;
}

void ad_addch_init(char ch) {
    [disp ad_init_atY:yPos X:xPos ch:ch];
    xPos++;
}

void ad_init_completed() {
    [disp ad_init_completed];
}

void ad_draw_at(int y, int x, char ch) {
    [disp ad_draw_atY:y X:x ch:ch];
}

void ad_refresh() {
    [disp ad_refresh];
}

void ad_score(long score) {
    [disp ad_score:score];
}

void ad_diamonds(int nf, int total) {
    [disp ad_diamondsNotFound:nf total:total];
}

void ad_teleport(void) {
    [disp ad_teleport];
}

void ad_maxmoves(int maxmoves) {
    [disp ad_maxmoves:maxmoves];
}

void ad_monster(int monster) {
    [disp ad_monster:monster];
}

void ad_screen_number(int n) {
    [disp ad_screen_number:n];
}

void ad_screen_name(char *name) {
    [disp ad_screen_name:name];
}

void ad_sound(char sound) {
    [disp ad_sound:sound];
}
