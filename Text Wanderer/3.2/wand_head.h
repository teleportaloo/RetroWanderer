/* file wand_head.h */
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

#include <stdio.h>
#include "abstracted_display.h"
#include <string.h>
#include <fcntl.h>

#ifndef WAND_HEAD
#define WAND_HEAD

#undef MSDOS /* Marina */

#ifndef MSDOS
#include <sys/file.h>
#endif

#define VERSION "3.2"




/********** FILES ************/

/* Change these to the necessary directories or files */
// #define SCREENPATH  "/usr/local/share/wanderer/screens"
// #define HISCOREPATH "/var/games/wandererscores"
// #define DICTIONARY  "/usr/share/dict/words"
// #define LOCKFILE    "/tmp/wanderer.lock"

/********** PASSWORDS *********/

/* change this to anything, but dont forget what                         */
#define MASTERPASSWORD "chocolate chips"

/* change the numbers in this as well, but keep it in the same form         */
#define PASSWD         (num * num * 4373 + num * 16927 + 39)

/* this is the randon number seed used for encryption                          */
#define BLURFL         32451
/* the word blurfl is used for historical reasons                         */

/********** OPTIONS ***********/

/* To disable the recording of hiscores from games restored from saves         */
/* #define NO_RESTORED_GAME_HISCORES  */
/* #define COMPARE_BY_NAME   define this to compare by name, not uid         */
/* #define NO_ENCRYPTION define this to disable the savefile encryptor */
#define NOISY    /* do we want bells in the game ? */

/****** OTHER PARAMETERS ******/

#define GUESTUID 0    /* guestuid always compared by name         */
#define EMSIZE   1024 /* size of editor moves memory              */
#define ENTRIES  15   /* size of hiscore file                     */

/*********** CBREAK ***********/


/* cbreak switching via curses package.                                  */
/* on some Ultrix systems you may need to use crmode() and nocrmode()    */
/* if so, just change the #defs to the necessary. I also know that Xenix */
/* systems have to use crmode, so..                                      */
//#ifdef XENIX
#define CBON  // crmode()
#define CBOFF //nocrmode()
//#else
//#define CBON cbreak()
//#define CBOFF nocbreak()
//#endif

/**** NOTHING TO CHANGE BELOW HERE ****/

/* I wouldnt change these if I were you - it wont give you a bigger screen */
#define ROWLEN                 40
#define NOOFROWS               16

/* MSDOS modifications (M001) by Gregory H. Margo        */
#ifdef        MSDOS
#define        R_BIN           "rb" /* binary mode for non-text files */
#define        W_BIN           "wb"
# ifdef        VOIDPTR
#  define VOIDSTAR             (void *)
# else
#  define VOIDSTAR             (char *)
# endif
#define        ASKNAME              /* ask user's name if not in environment         */
#define        COMPARE_BY_NAME      /* compare users with name, not uid                */
#undef        getchar               /* remove stdio's definition to use curses'         */
#define        getchar() getch()    /* use curse's definition instead */

#else /* not MSDOS */
#define        R_BIN           "r"
#define        W_BIN           "w"
#define        VOIDSTAR
#endif

/* Save and Restore game additions (M002) by Gregory H. Margo        */
/* mon_rec structure needed by save.c */


typedef struct game {
    int x;
    int y;
    int nx;
    int ny;
    int deadyet;
    int sx;
    int sy;
    int tx;
    int ty;
    int lx;
    int ly;
    int mx;
    int my;
    int recording;
    int diamonds;
    int nf;
    char (*frow)[ROWLEN + 1];
    char *memory_ptr;
    int maxmoves;
    int finished;
    int quit;

    char *howdead;
} game;

struct mon_rec {
    int x, y, mx, my;
    char under;
    struct mon_rec *next, *prev;
};

struct        save_vars {
    int z_x, z_y,
        z_sx, z_sy,
        z_tx, z_ty,
        z_mx, z_my,
        z_diamonds,
        z_nf;
};

struct        old_save_vars {
    int z_x, z_y,
        z_nx, z_ny,
        z_sx, z_sy,
        z_tx, z_ty,
        z_lx, z_ly,
        z_mx, z_my,
        z_bx, z_by,
        z_nbx, z_nby,
        z_max_score,
        z_diamonds,
        z_nf,
        z_hd,
        z_vd,
        z_xdirection,
        z_ydirection;
};

/* prototypes added by Gregory H. Margo */
/* DISPLAY.c */
extern void map(char (*)[ROWLEN + 1]);
extern void display(int, int, char (*)[ROWLEN + 1], long);

/* EDIT.C */
extern void instruct(void);
extern void noins(void);
extern void editscreen(int, int *, int *, int, char *);

/* FALL.C */
extern int check(int *, int *, int, int, int, int, int, int, char **);
extern int fall(int *, int *, int, int, int, int, char **);

/* GAME.C */

extern struct mon_rec * make_monster(int, int);
extern char * initscreen(int *num, long *score, int *bell, int maxmoves, char *keys, game *game);
extern char * onemove(int *num, long *score, int *bell, char *keys, game *game, char ch);



/* ICON.C */
extern void draw_symbol(int, int, char);

/* JUMP.C */
extern int scrn_passwd(int, char *);
extern void showpass(int);
extern int jumpscreen(int);
extern int getnum(void);

/* READ.C */
extern int rscreen(int, int *, const char *);
extern int wscreen(int, int);

/* SAVE.C */
extern void save_game(int num, long *score, int *bell, int maxmoves);
extern void restore_game(int *, long *, int *, int *);

/* SCORES.C */
extern int savescore(char *, int, int, char *);
extern void delete_entry(int);
extern int erase_scores(void);

/* for monster movement */

#define VIABLE(x, y)                                    \
    (((screen[y][x] == ' ') || (screen[y][x] == ':') || \
      (screen[y][x] == '@') || (screen[y][x] == '+') || \
      (screen[y][x] == 'S')) && ((y) >= 0) &&           \
     ((x) >= 0) && ((y) < NOOFROWS) && ((x) < ROWLEN))

#endif // ifndef WAND_HEAD
