/* File game.c */
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

extern int move_monsters(int *mxp, int *myp, long *score, char **howdead, int sx, int sy, int nf, int bell, int x, int y, int diamonds);

extern void showname(void);
extern int jumpscreen(int);
extern int check(int *, int *, int, int, int, int, int, int, char **);
extern void showpass(int);
extern void display(int, int, char (*)[ROWLEN + 1], long);
extern int fall(int *, int *, int, int, int, int, char **);
extern void map(char (*)[ROWLEN + 1]);
void redraw_screen(int *bell, int maxmoves, int num, long score, int nf, int diamonds, int mx, int sx, int sy, char (*frow)[ROWLEN + 1]);
extern struct mon_rec * make_monster(int, int);

/***************************************************************
 *         function declarations    from this file              *
 ****************************************************************/

extern int edit_mode;
extern int saved_game;
extern int record_file;
extern char screen[NOOFROWS][ROWLEN + 1];
extern char *edit_memory;
extern char *memory_end;

struct mon_rec start_of_list = {0, 0, 0, 0, 0, NULL, NULL};
struct mon_rec *last_of_list, *tail_of_list;

/***************************************************************
 *               function playscreen (the game)                 *
 ****************************************************************/
/********************************************************************
 * Actual game function - Calls fall() to move boulders and arrows   *
 *        recursively.                                               *
 *   Variable explaination :                                         *
 *     All the var names make sense to ME, but some people           *
 *     think them a bit confusing... :-) So heres an explanation.    *
 *   x,y : where you are                                             *
 *   nx,ny : where you're trying to move to                          *
 *   sx,sy : where the screen window on the playing area is          *
 *   mx,my : where the monster is                                    *
 *   tx,ty : teleport arrival                                        *
 *   bx,by : baby monster position                                   *
 *   nbx,nby : where it wants to be                                  *
 *   lx,ly : the place you left when teleporting                     *
 *   nf : how many diamonds youve got so far                         *
 *   new_disp : the vector the baby monster is trying                *
 *********************************************************************/



char * initscreen(int *num, long *score, int *bell, int maxmoves, char *keys, game *game) {
    struct mon_rec *monster;

    game->finished = 0;
    game->quit = 0;
    game->deadyet = 0;
    game->sx = -1;
    game->sy = -1;
    game->tx = -1;
    game->ty = -1;
    game->lx = 0;
    game->ly = 0;
    game->mx = -1;
    game->my = -1;
    game->recording = 0;
    game->diamonds = 0;
    game->nf = 0;
    game->frow = screen;
    game->maxmoves = maxmoves;


    tail_of_list = &start_of_list;
    game->memory_ptr = edit_memory;

    for (game->x = 0; game->x <= ROWLEN; game->x++) {
        for (game->y = 0; game->y < NOOFROWS; game->y++) {
            if ((screen[game->y][game->x] == '*') || (screen[game->y][game->x] == '+')) {
                game->diamonds++;
            }

            if (screen[game->y][game->x] == 'A') {   /* note teleport arrival point &  */
                /* replace with space */
                game->tx = game->x;
                game->ty = game->y;
                screen[game->y][game->x] = ' ';
            }

            if (screen[game->y][game->x] == '@') {
                game->sx = game->x;
                game->sy = game->y;
            }

            if (screen[game->y][game->x] == 'M') {   /* Put megamonster in */
                game->mx = game->x;
                game->my = game->y;
            }

            if (screen[game->y][game->x] == 'S') { /* link small monster to pointer chain */
                if ((monster = make_monster(game->x, game->y)) == NULL) {
                    game->howdead = "running out of memory";
                    return game->howdead;
                }

                if (!VIABLE(game->x, game->y - 1)) { /* make sure its running in the correct */
                    /* direction..                          */
                    monster->mx = 1;
                    monster->my = 0;
                } else if (!VIABLE(game->x + 1, game->y)) {
                    monster->mx = 0;
                    monster->my = 1;
                } else if (!VIABLE(game->x, game->y + 1)) {
                    monster->mx = -1;
                    monster->my = 0;
                } else if (!VIABLE(game->x - 1, game->y)) {
                    monster->mx = 0;
                    monster->my = -1;
                }
            }

            if (screen[game->y][game->x] == '-') {
                screen[game->y][game->x] = ' ';
            }
        }
    }

    ;
    game->x = game->sx;
    game->y = game->sy;

    if ((game->x == -1) && (game->y == -1)) {            /* no start position in screen ? */
        game->howdead = "a screen design error";
        return(game->howdead);
    }

    if (game->maxmoves < 1) {
        game->maxmoves = -1;
    }

 update_game:           /* M002  restored game restarts here        */

    ad_clear();
    redraw_screen(bell, game->maxmoves, *num, *score, game->nf, game->diamonds, game->mx, game->sx, game->sy, game->frow);

    return NULL;
}

char * onemove(int *num, long *score, int *bell, char *keys, game *game, char ch) {
/* ACTUAL GAME FUNCTION - Returns method of death in string  */

    if (game->deadyet == 0) {
        switch (game->recording) {
            case 1:
                *game->memory_ptr++ = ch;
                memory_end++;
                break;

            case 2:
                ch = *game->memory_ptr++;

                if (ch == '\0') {
                    ch = ')';
                }

                break;

            default:
                break;
        }

        if ((record_file != -1) && (ch != 'q')) {
            write(record_file, &ch, 1);
        }

        game->nx = game->x;
        game->ny = game->y;

        if ((ch == keys[3]) && (game->x < (ROWLEN - 1))) {
            /* move about - but thats obvious */
            game->nx++;
        }

        if ((ch == keys[2]) && (game->x > 0)) {
            game->nx--;
        }

        if ((ch == keys[1]) && (game->y < (NOOFROWS - 1))) {
            game->ny++;
        }

        if ((ch == keys[0]) && (game->y > 0)) {
            game->ny--;
        }

#if 0

        if (ch == '~') {                           /* level jump */
            if (edit_mode) {
                continue;
            }

            if ((newnum = jumpscreen(*num)) == 0) {
                howdead = "a jump error.";
                return howdead;
            }

            if (newnum != *num) { /* Sorry Greg, no points for free */
                sprintf(howdead, "~%c", newnum);
                return howdead;
            }

            continue;
        }

#endif

        if (ch == 'q') {
            game->howdead = "quitting the game";
            game->quit = 1;
            return game->howdead;
        }

        if ((ch == 'W') || ( (int)ch == 12)) {
            redraw_screen(bell, game->maxmoves, *num, *score, game->nf, game->diamonds, game->mx, game->sx, game->sy, game->frow);
            return NULL;
        }

        /* Edit screen memory functions */
#if 0

        if (edit_memory) {
            if ((ch == '(') && (game->recording == 0)) {
                /* start recording from beginning */
                memory_end = game->memory_ptr = edit_memory;
                st_move(10, 53);
                st_addstr(" -Recording-");
                st_refresh();
                game->recording = 1;
                return NULL;
            }

            if ((ch == ')') && (game->recording != 0)) {
                /* stop recording or playback */
                game->recording = 0;
                st_move(10, 53);
                st_addstr(" -- End --  ");
                st_refresh();
                st_move(10, 53);
                st_addstr(" -Occupied- ");
                return NULL;
            }

            if ((ch == '*') && (game->recording == 0)) { /* playback memory */
                game->memory_ptr = edit_memory;
                game->recording = 2;
                st_move(10, 53);
                st_addstr(" -Playback- ");
                st_refresh();
                return NULL;
            }

            if ((ch == '&') && (game->recording == 0)) {/* extend recording,either from*/
                /* end or from checkpoint        */
                game->recording = 1;
                st_move(10, 53);
                st_addstr(" -Recording-");
                st_refresh();

                if (*(game->memory_ptr - 1) != '-') {
                    game->memory_ptr--;
                }

                return NULL;
            }

            if ((ch == '+') && (game->recording == 0) && (game->memory_ptr < memory_end)) {
                /* continue from checkpoint */
                game->recording = 2;
                st_move(10, 53);
                st_addstr(" -Playback- ");
                st_refresh();
                return NULL;
            }

            if ((ch == '-') && (game->recording != 0)) {
                /*create or react to a checkpoint*/
                /* checkpoint */
                st_move(10, 53);
                st_addstr("-Checkpoint-");
                st_refresh();
                st_move(10, 53);

                if (game->recording == 2) {
                    game->recording = 0;
                    st_addstr(" -Occupied- ");
                } else {
                    st_addstr(" -Recording-");
                }

                return NULL;
            }
        }

#endif // if 0
       /* end of memory functions */

        /* M002  Added save/restore game feature.  Gregory H. Margo        */
        if (ch == 'S') {         /* save game */
            extern struct        save_vars zz;

            /* stuff away important local variables to be saved */
            /* so the game state may be acurately restored        */
            zz.z_x = game->x;
            zz.z_y = game->y;
            zz.z_sx = game->sx;
            zz.z_sy = game->sy;
            zz.z_tx = game->tx;
            zz.z_ty = game->ty;
            zz.z_mx = game->mx;
            zz.z_my = game->my;
            zz.z_diamonds = game->diamonds;
            zz.z_nf = game->nf;

            save_game(*num, score, bell, game->maxmoves); //, &start_of_list,tail_of_list);
            /* NOTREACHED ... unless there's been an error. */
        }

        if (ch == 'R') {          /* restore game */
            extern struct        save_vars zz;

            restore_game(num, score, bell, &game->maxmoves); // ,&start_of_list,&tail_of_list);

            /* recover important local variables */
            game->x = zz.z_x;
            game->y = zz.z_y;
            game->sx = zz.z_sx;
            game->sy = zz.z_sy;
            game->tx = zz.z_tx;
            game->ty = zz.z_ty;
            game->mx = zz.z_mx;
            game->my = zz.z_my;
            game->diamonds = zz.z_diamonds;
            game->nf = zz.z_nf;

            // goto update_game;        /* the dreaded goto        */
        }

        if (screen[game->ny][game->nx] == 'C') {
            screen[game->ny][game->nx] = ':';
            *score += 4;

            if (game->maxmoves != -1) {
                game->maxmoves += 250;
            }
        }

        switch (screen[game->ny][game->nx]) {
            case '@': break;

            case '*': *score += 9;
                game->nf++;
                ad_diamonds(game->nf, game->diamonds);

            case ':': *score += 1;
                ad_score(*score);

            case ' ': {
                char under = screen[game->ny][game->nx];
                screen[game->y][game->x] = ' ';
                screen[game->ny][game->nx] = '@';
                {
                    ad_move_ch('@', game->y + 1, game->x + 1, game->ny + 1, game->nx + 1, ' ', 0, under, ad_hint_slow_and_grouped);
                    //ad_move(game->y+1,game->x+1);
                    //ad_addch(' ');
                    //ad_move(game->ny+1,game->nx+1);
                    //ad_addch('@')
                }
                game->deadyet += check(&game->mx, &game->my, game->x, game->y, game->nx - game->x, game->ny - game->y, game->sx, game->sy, &game->howdead);
                ad_refresh();
                game->y = game->ny;
                game->x = game->nx;
            }
            break;

            case 'O':

                if ((game->nx == 0) || (game->nx == (ROWLEN - 1))) {
                    break;
                }

                if (screen[game->y][game->nx * 2 - game->x] == 'M') {
                    screen[game->y][game->nx * 2 - game->x] = ' ';
                    game->mx = game->my = -1;
                    *score += 100;
                    ad_score(*score);
                    ad_diamonds(game->nf, game->diamonds);
                    ad_monster(0);
                    ad_refresh();
                }

                if (screen[game->y][game->nx * 2 - game->x] == ' ') {
                    screen[game->y][game->nx * 2 - game->x] = 'O';
                    screen[game->y][game->x] = ' ';
                    screen[game->ny][game->nx] = '@';

                    ad_move_ch('O', game->ny + 1, game->nx + 1, game->y + 1, game->nx * 2 - game->x + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);


                    //ad_move(game->y+1,game->x+1);
                    //ad_addch(' ');
                    //ad_move(game->ny+1,game->nx+1);
                    //ad_addch('@');
                    //ad_move(game->y+1,game->nx*2-game->x+1);
                    //ad_addch('O');

                    game->deadyet += fall(&game->mx, &game->my, game->nx * 2 - game->x, game->y + 1, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x * 2 - game->nx, game->y, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y - 1, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y + 1, game->sx, game->sy, &game->howdead);
                    ad_refresh();
                    game->y = game->ny;
                    game->x = game->nx;
                }

                break;

            case '^':

                if ((game->nx == 0) || (game->nx == (ROWLEN - 1))) {
                    break;
                }

                if (screen[game->y][game->nx * 2 - game->x] == ' ') {
                    screen[game->y][game->nx * 2 - game->x] = '^';
                    screen[game->y][game->x] = ' ';
                    screen[game->ny][game->nx] = '@';


                    ad_move_ch('^', game->ny + 1, game->nx + 1, game->y + 1, game->nx * 2 - game->x + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);

                    //ad_move(game->y+1,game->x+1);
                    //ad_addch(' ');
                    //ad_move(game->ny+1,game->nx+1);
                    //ad_addch('@');
                    //ad_move(game->y+1,game->nx*2-game->x+1);
                    //ad_addch('^');

                    game->deadyet += fall(&game->mx, &game->my, game->nx * 2 - game->x, game->y - 1, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x * 2 - game->nx, game->y, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y + 1, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y - 1, game->sx, game->sy, &game->howdead);
                    ad_refresh();
                    game->y = game->ny;
                    game->x = game->nx;
                }

                break;

            case '<':
            case '>':

                if ((game->ny == 0) || (game->ny == (NOOFROWS - 1))) {
                    break;
                }

                if (screen[game->ny * 2 - game->y][game->x] == 'M') {
                    screen[game->ny * 2 - game->y][game->x] = ' ';
                    game->mx = game->my = -1;
                    *score += 100;
                    ad_score(*score);
                    ad_diamonds(game->nf, game->diamonds);
                    ad_monster(0);
                    ad_refresh();
                }

                if (screen[game->ny * 2 - game->y][game->x] == ' ') {
                    screen[game->ny * 2 - game->y][game->x] = screen[game->ny][game->nx];
                    screen[game->y][game->x] = ' ';
                    screen[game->ny][game->nx] = '@';

                    ad_move_ch(screen[game->ny * 2 - game->y][game->x], game->ny + 1, game->nx + 1, game->ny * 2 - game->y + 1, game->x + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);

                    //ad_move(game->y+1,game->x+1);
                    //ad_addch(' ');
                    //ad_move(game->ny+1,game->nx+1);
                    //ad_addch('@');
                    //ad_move(game->ny*2-game->y+1,game->x+1);
                    //ad_addch(screen[game->ny*2-game->y][game->x]);

                    game->deadyet += fall(&game->mx, &game->my, game->x, game->y, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x - 1, (game->ny > game->y) ? game->y : (game->y - 1), game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x + 1, (game->ny > game->y) ? game->y : (game->y - 1), game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x - 1, game->ny * 2 - game->y, game->sx, game->sy, &game->howdead);
                    game->deadyet += fall(&game->mx, &game->my, game->x + 1, game->ny * 2 - game->y, game->sx, game->sy, &game->howdead);;
                    ad_refresh();
                    game->y = game->ny;
                    game->x = game->nx;
                }

                break;

            case '~':

                if (((2 * game->nx - game->x) < 0) || ((game->ny * 2 - game->y) > NOOFROWS) || ((game->ny * 2 - game->y) < 0) || ((2 * game->nx - game->x) > ROWLEN)) {
                    break;
                }

                if (screen[game->ny * 2 - game->y][game->nx * 2 - game->x] == 'M') {
                    screen[game->ny * 2 - game->y][game->nx * 2 - game->x] = ' ';
                    game->mx = game->my = -1;
                    *score += 100;
                    ad_score(*score);
                    ad_diamonds(game->nf, game->diamonds);
                    ad_monster(0);
                    ad_refresh();
                }

                if (screen[game->ny * 2 - game->y][game->nx * 2 - game->x] == ' ') {
                    screen[game->ny * 2 - game->y][game->nx * 2 - game->x] = '~';
                    screen[game->y][game->x] = ' ';
                    screen[game->ny][game->nx] = '@';
                    {
                        ad_move_ch('~', game->ny + 1, game->nx + 1, game->ny * 2 - game->y + 1, game->nx * 2 - game->x + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                        ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);

                        //ad_move(game->y+1,game->x+1);
                        //ad_addch(' ');
                        //ad_move(game->ny+1,game->nx+1);
                        //ad_addch('@');
                        //ad_move(game->ny*2-game->y+1,game->nx*2-game->x+1);
                        //ad_addch('~');
                    }
                    game->deadyet += check(&game->mx, &game->my, game->x, game->y, game->nx - game->x, game->ny - game->y, game->sx, game->sy, &game->howdead);
                    ad_refresh();
                    game->y = game->ny; game->x = game->nx;
                }

                break;

            case '!':
                game->howdead = "exploding dynamite";
                game->deadyet = 1;
                {
                    //ad_move(game->y+1,game->x+1);
                    //ad_addch(' ');
                    //ad_move(game->ny+1,game->nx+1);
                    //ad_addch('@');

                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                }
                ad_refresh();
                break;

            case 'X':

                if (game->nf == game->diamonds) {
                    *score += 250;
                    // showpass(*num);
                    ad_score(*score);
                    game->finished = 1;


                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', '@', 'X', ad_hint_slow_and_grouped);
                    ad_refresh();
                    return NULL;
                }

                break;

            case 'T':

                if (game->tx > -1) {
                    screen[game->ny][game->nx] = ' ';
                    screen[game->y][game->x] = ' ';
                    game->lx = game->x;
                    game->ly = game->y;
                    game->y = game->ty;
                    game->x = game->tx;
                    screen[game->y][game->x] = '@';
                    game->sx = game->x;
                    game->sy = game->y;
                    *score += 20;


                    ad_score(*score);
                    ad_diamonds(game->nf, game->diamonds);

                    map(game->frow);

                    game->deadyet += fall(&game->mx, &game->my, game->nx, game->ny, game->sx, game->sy, &game->howdead);

                    if (game->deadyet == 0) {
                        game->deadyet = fall(&game->mx, &game->my, game->lx, game->ly, game->sx, game->sy, &game->howdead);
                    }

                    if (game->deadyet == 0) {
                        game->deadyet = fall(&game->mx, &game->my, game->lx + 1, game->ly - 1, game->sx, game->sy, &game->howdead);
                    }

                    if (game->deadyet == 0) {
                        game->deadyet = fall(&game->mx, &game->my, game->lx + 1, game->ly + 1, game->sx, game->sy, &game->howdead);
                    }

                    if (game->deadyet == 0) {
                        game->deadyet = fall(&game->mx, &game->my, game->lx - 1, game->ly + 1, game->sx, game->sy, &game->howdead);
                    }

                    if (game->deadyet == 0) {
                        game->deadyet = fall(&game->mx, &game->my, game->lx - 1, game->ly - 1, game->sx, game->sy, &game->howdead);
                    }

                    ;
                    ad_refresh();
                    ad_teleport();
                } else {
                    screen[game->ny][game->nx] = ' ';
                    printf("Teleport out of order");
                }

                break;

            case 'M':
                game->howdead = "a hungry monster";
                game->deadyet = 1;
                {
                    // ad_move(game->y+1,game->x+1);
                    // ad_addch(' ');
                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                };
                ad_refresh();
                break;

            case 'S':
                game->howdead = "walking into a monster";
                game->deadyet = 1;
                {
                    // ad_move(game->y+1,game->x+1);
                    // ad_addch(' ');

                    ad_move_ch('@', game->y + 1, game->x + 1,  game->ny + 1, game->nx + 1, ' ', 0, 0, ad_hint_slow_and_grouped);
                }
                ad_refresh();
                break;

            default:
                break;
        }

        if ((game->y == game->ny) && (game->x == game->nx) && (game->maxmoves > 0)) {
            ad_maxmoves(--game->maxmoves);
        }

        if (game->maxmoves == 0) {
            game->howdead = "running out of time";
            game->deadyet = 1;

            if (edit_mode) {
                game->maxmoves = -1;
            }
        }

        game->deadyet += move_monsters(&game->mx, &game->my, score, &game->howdead, game->sx, game->sy, game->nf, *bell, game->x, game->y, game->diamonds);

#if 0

        if ((edit_mode) && (game->deadyet)) {       /* stop death if testing */
            game->recording = 0;
            st_move(10, 53);
            st_addstr("-Occupied- ");

            if (!debug_disp) {
                st_move(18, 0);
            } else {
                st_move(20, 0);
            }

            st_addstr("You were killed by ");
            st_addstr(game->howdead);
            st_addstr("\nPress 'c' to continue.");
            st_refresh();

            // ch=userinput();
            if (ch == 'c') {
                game->deadyet = 0;
            }

            if (!debug_disp) {
                st_move(18, 0);
            } else {
                st_move(20, 0);
            }

            st_addstr("                                                              ");
            st_addstr("\n                      ");
            st_refresh();
        }

#endif // if 0
    }

    if (game->deadyet) {
        return(game->howdead);
    }

    return NULL;
}
