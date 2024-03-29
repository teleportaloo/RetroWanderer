/* File save.c */
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
#include <errno.h>
#include <stdlib.h>

extern char screen[NOOFROWS][ROWLEN + 1];
extern int saved_game;
extern char screen_name[ROWLEN + 1];
extern void crypt_file(void);
extern int voidinform_me(void);
extern void readstring(void);
void inform_me(char *str, int qable);

struct saved_game {
    short num;
    long score;
    short bell;
    short maxmoves;
    short num_monsters;
};

struct save_vars zz;

extern struct mon_rec start_of_list, *tail_of_list;

#define BUF_SIZ 70


/*********************************************************
 *                    function save_game                  *
 **********************************************************/
void save_game(num, score, bell, maxmoves)
int num, *bell, maxmoves;
long *score;
{
    char fname[128], buf[BUF_SIZ], *fp;
    FILE *fo;
    struct saved_game s;
    extern char * getenv(const char *);
    struct mon_rec *mp;

    if ((char *)NULL == (fp = getenv("SAVENAME"))) {
        /*
           st_move(20,0);
           st_addstr("Saving: Filename? ");
           st_refresh();
           // readstring(fname,127);
           fp = fname;
         */
    }

    //st_move(20,0);
    //st_addstr("                                                                             ");
    //st_move(20,0);
    //st_refresh();
    if ((FILE *)NULL == (fo = fopen(fp, W_BIN))) {
        perror(fp);
        return;
    }

    s.num = num;
    s.score = *score;
    s.bell = *bell;
    s.maxmoves = maxmoves;
    s.num_monsters = 0;

    mp = &start_of_list;                 /* first entry is dummy        */

    while (mp != tail_of_list) {
        mp = mp->next;
        s.num_monsters++;                /* count them monsters        */
    }

    if ( (1 != fwrite((char *)&s, sizeof(s), 1, fo)) ||
         (1 != fwrite((char *)screen, sizeof(screen), 1, fo)) ||
         (1 != fwrite((char *)&zz, sizeof(zz), 1, fo)) ) {
        snprintf(buf, BUF_SIZ, "Write error on '%s'\n", fname);
        inform_me(buf, 0);
        fclose(fo);
        unlink(fname);
        return;
    }

    mp = &start_of_list;

    while (mp != tail_of_list) {
        /* save them monsters */
        mp = mp->next;

        if (1 != fwrite((char *)mp, sizeof(struct mon_rec), 1, fo)) {
            snprintf(buf, BUF_SIZ, "Write error on '%s'\n", fname);
            inform_me(buf, 0);
            fclose(fo);
            unlink(fname);
            return;
        }
    }
    fwrite(screen_name, sizeof(char), strlen(screen_name), fo);
    fclose(fo);
#ifndef NO_ENCRYPTION
    // crypt_file(fp,0);   /* encrpyt the saved game */
#endif
    // st_clear();
    CBON;
    //echo();
    //st_refresh();
    //st_endwin();
    printf("Game saved.\n\nWanderer Copyright (C) 1988 S Shipway\n\n");
    // exit(0);
}

/*************************************************
 *              function restore_game             *
 **************************************************/
void restore_game(num, score, bell, maxmoves)
int *num, *maxmoves, *bell;
long *score;
{
    FILE *fi;
    struct        saved_game s;
    struct        mon_rec *mp, *tmp, tmp_monst;
    char fname[128], *fp;
    // char        *m_terminate = NULL;
    // FILE        *fo;
    extern char * getenv(const char *);

    if ((char *)NULL == (fp = getenv("SAVENAME"))) {
        //st_move((ST_LINES-1),0);
        //st_addstr("Restore Filename ? ");
        //st_refresh();
        //echo(); CBOFF;
        fp = fname;
        fgets(fp, sizeof(fname), stdin); /* Marina Brown */
        //m_terminate=strchr(fp,'\n');
        //m_terminate="\0";           /* End Marina delta */
        // CBON; noecho();
    }

    //st_clear();
    //st_refresh();
#ifndef NO_ENCRYPTION
    // crypt_file(fp,1);   /* decrypt it */
#endif

    if ((FILE *)NULL == (fi = fopen(fp, R_BIN))) {
        //st_endwin();
        printf("Open error on '%s'\n", fp);
        printf("Cannot restore game --- sorry.\n");
        exit(1);
    }

    if ( (1 != fread((char *)&s, sizeof(s), 1, fi)) ||
         (1 != fread((char *)screen, sizeof(screen), 1, fi)) ||
         (1 != fread((char *)&zz, sizeof(zz), 1, fi)) ) {
        //st_endwin();
        printf("Read error on '%s'n", fp);
        printf("Cannot restore game --- sorry.\n");
        fclose(fi);
        exit(1);
    }

    *num = s.num;
    *score = (int)s.score;
    *bell = s.bell;
    *maxmoves = s.maxmoves;

    /* free any monsters already on chain, to start clean */
    mp = start_of_list.next;

    while ((mp != NULL) && (mp != &start_of_list)) {
        /* free them monsters        */
        tmp = mp;
        mp = mp->next;
        free(tmp);
    }

    /* re-initialize the monster list        */
    /* start_of_list = {0,0,0,0,0,NULL,NULL}; */
    start_of_list.x = 0;
    start_of_list.y = 0;
    start_of_list.mx = 0;
    start_of_list.my = 0;
    start_of_list.under = 0;
    start_of_list.next = (struct mon_rec *)NULL;
    start_of_list.prev = (struct mon_rec *)NULL;

    tail_of_list = &start_of_list;

    while (s.num_monsters--) {
        /* use make_monster to allocate the monster structures     */
        /* to get all the linking right without even trying        */
        if ((struct mon_rec *)NULL == (mp = make_monster(0, 0))) {
            printf("Monster alloc error on '%s'n", fp);
            printf("Try again - it might work.\nBut then,pigs might fly...\n");
            fclose(fi);
            exit(1);
        }

        if (1 != fread((char *)&tmp_monst, sizeof(struct mon_rec), 1, fi)) {
            printf("Monster read error on '%s'\n", fp);
            printf("Cannot restore game --- sorry.\n");
            fclose(fi);
            exit(1);
        }

        /* copy info without trashing links        */
        mp->x = tmp_monst.x;
        mp->y = tmp_monst.y;
        mp->mx = tmp_monst.mx;
        mp->my = tmp_monst.my;
        mp->under = tmp_monst.under;
    }

    if (fgets(screen_name, ROWLEN, fi) == NULL) {
        *screen_name = '#';
    }

    fclose(fi);
    unlink(fp);
    saved_game = 1;
}
