/* File display.c */
/*
 *  Copyright 2003 -   Steven Shipway <steve@cheshire.demon.co.uk>
 *                     Put "nospam" in subject to avoid spam filter
 */

/* See email note - license changed to an app store compatible
 * open source license.
 */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 *  Additional code Copyright 2017 -   Andrew Wallace
 */

#include "wand_head.h"

/***********************************
 *        extern variables          *
 ************************************/
extern int edit_mode;
extern char screen_name[61];
extern char *edit_memory, *memory_end;


/****************************************
 *         function declarations         *
 *****************************************/
void map(char (*row_ptr)[ROWLEN + 1]);
int inform_me(char *, int qable);
void showname(void);


/******************************************
 *                   map                   *
 *******************************************/
void map(char (*row_ptr)[ROWLEN + 1]) {
    int x, y;
    char ch;

    ad_move(0, 0);
    ad_addch_init('=');

    for (x = 0; x < ROWLEN; x++) {
        ad_addch_init('-');
    }

    ad_addch('=');

    for (y = 0; y < NOOFROWS; y++) {
        ad_move(y + 1, 0);
        ad_addch_init('|');

        for (x = 0; x < ROWLEN; x++) {
            ch = (*row_ptr)[x];

            if (ch != '\0') {
                ad_addch_init(ch);
            } else {
                ad_addch_init('"');
            }
        }

        ad_addch_init('|');
        row_ptr++;
    }

    ad_move(y + 1, 0);
    ad_addch_init('=');

    for (x = 0; x < ROWLEN; x++) {
        ad_addch_init('-');
    }

    ad_addch_init('=');
    ad_init_completed();
    ad_refresh();
}

/*************************************************************
 *                         showname                           *
 **************************************************************/
void showname() {
    ad_move(19, 0);

    if ((screen_name[0] == '#') || (screen_name[0] == '\0')) {
        ad_screen_name("");
    } else {
        ad_screen_name(screen_name);
    }

#if 0

    if (edit_memory) {
        st_move(7, 45);
        st_addstr("MEMORY: ( Start, ) End,");
        st_move(8, 53);
        st_addstr("* Play, & Extend.");
        st_move(9, 53);
        st_addstr("- Chkpt, + Cont.");
        st_move(10, 53);

        if (memory_end == edit_memory) {
            st_addstr("--Empty--");
        } else {
            st_addstr("-Occupied-");
        }
    }

#endif
}

/**/
/******************************************************************
 *                           redraw_screen                         *
 *******************************************************************/
void redraw_screen(int *bell, int maxmoves, int num, long score, int nf, int diamonds, int mx, int sx, int sy, char (*frow)[ROWLEN + 1]) {
    ad_score(score);
    ad_diamonds(nf, diamonds);

#if 0

    if (!edit_mode) {
        st_move(6, 48);
        (void)sprintf(buffer, "Current screen %d", num);
        (void)st_addstr(buffer);
    }

#endif
    ad_maxmoves(maxmoves);
    ad_monster(mx != -1);
    ad_screen_number(num);

    showname();
    map(frow);
}
