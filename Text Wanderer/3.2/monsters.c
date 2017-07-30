/* File monsters.c */
/***************************************************************************
*  Copyright 2003 -   Steven Shipway <steve@cheshire.demon.co.uk>          *
*                     Put "nospam" in subject to avoid spam filter         *
*                                                                          *
*  This program is free software; you can redistribute it and/or modify    *
*  it under the terms of the GNU General Public License as published by    *
*  the Free Software Foundation; either version 2 of the License, or       *
*  (at your option) any later version.                                     *
*                                                                          *
*  This program is distributed in the hope that it will be useful,         *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
*  GNU General Public License for more details.                            *
*                                                                          *
*  You should have received a copy of the GNU General Public License       *
*  along with this program; if not, write to the Free Software             *
*  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA               *
*  02111-1307, USA.                                                        *
***************************************************************************/
/***************************************************************************
 *  Additional code Copyright 2017 -   Andrew Wallace                      *
 ***************************************************************************/

#include <stdlib.h>
#include "wand_head.h"

typedef struct { int d[2]; } direction;

direction new_direction(int, int, int, int);

extern  void draw_symbol(int ,int ,char );
extern int edit_mode;
extern char screen[NOOFROWS][ROWLEN+1];

/* Add a spirit to the chain */
/* Maintain a doubly linked list to make reuse possible.
   tail_of_list is *NOT* the last monster allocated, but
   the last monster alloted to a screen.  start_of_list
   is a dummy entry to ease processing. last_of_list
   is the last entry allocated. */

extern struct mon_rec *last_of_list, *tail_of_list;
extern struct mon_rec start_of_list;

/********************************************************
*                 function make_monster                 *
*********************************************************/
struct mon_rec *make_monster(x,y)
int x,y;
{
    #define MALLOC (struct mon_rec *)malloc(sizeof(struct mon_rec))
    struct mon_rec *monster;
    if(tail_of_list->next == NULL)
    {
        if((last_of_list = MALLOC) == NULL)
            return NULL;
        tail_of_list->next = last_of_list;
        last_of_list->prev = tail_of_list;
        last_of_list->next = NULL;
    }
    monster = tail_of_list = tail_of_list->next;
    monster->x = x;
    monster->y = y;
    monster->mx = 1;      /* always start moving RIGHT. (fix later)  */
    monster->my = 0;
    monster->under = ' ';
    return monster;
}

/********************************************************************
*                      function direction                           *
*********************************************************************/
/* 'follow lefthand wall' algorithm for baby monsters */

direction new_direction(x,y,bx,by)
                        int x,y,bx,by;
{
    direction out;
    if(VIABLE((x+by),(y-bx)))
    {
        out.d[0] = by;
        out.d[1] = -bx;
        return out;
    }
    if(VIABLE((x+bx),(y+by)))
    {
        out.d[0] = bx;
        out.d[1] = by;
        return out;
    }
    if(VIABLE((x-by),(y+bx)))
    {
        out.d[0] = -by;
        out.d[1] = bx;
        return out;
    }
    if(VIABLE((x-bx),(y-by)))
    {
        out.d[0] = -bx;
        out.d[1] = -by;
        return out;
    }
    out.d[0] = -bx;
    out.d[1] = -by;
    return out;
}

/***********************************************************
*                   function move_monsters                 *
************************************************************/
int move_monsters(mxp, myp, score, howdead, sx, sy, nf, bell, x, y, diamonds)
                  int *mxp, *myp, *score, sx, sy, nf, bell, x, y, diamonds;
                  char **howdead;
{
    int xdirection, ydirection, hd, vd;
    int deadyet = 0;
    // int bx, by, nbx, nby, tmpx,tmpy;
    direction new_disp;
    struct mon_rec *monster,*current;

/* big monster first */
    if(*mxp == -2)                       /* has the monster been killed ? */
    {
        *score+=100;
        *mxp = *myp = -1;
        ad_score(*score);
        ad_monster(0);
        ad_sound('M');
        ad_refresh();
    }                                     /* if monster still alive */

    if(*mxp != -1)                        /* then move that monster ! */
    {
        int fromX;
        int fromY;
        char under = 0;
        
        screen[*myp][*mxp] = ' ';
        if(*mxp>x)
            xdirection = -1;
        else
            xdirection = 1;
        {
            fromY = *myp+1;
            fromX = *mxp+1;
            under = ' ';
        }
        if((hd = (*mxp-x))<0)
            hd = -hd;
        if((vd = (*myp-y))<0)
            vd = -vd;
        if((hd>vd)&&((*mxp+xdirection)<ROWLEN)&&((screen[*myp][*mxp+xdirection] == ' ')||(screen[*myp][*mxp+xdirection] == '@')))
            *mxp+=xdirection;
        else
        {
            if(*myp>y)
                ydirection = -1;
            else
                ydirection = 1;
            if(((*myp+ydirection)<NOOFROWS)&& ((screen[*myp+ydirection][*mxp]
== ' ')||(screen[*myp+ydirection][*mxp] == '@')))
                *myp+=ydirection;
            else
                if(((*mxp+xdirection)<ROWLEN)&&((screen[*myp][*mxp+xdirection] == ' ')||(screen[*myp][*mxp+xdirection] == '@')))
            *mxp+=xdirection;
        }
        if (under==0)
        {
            ad_move(*myp+1,*mxp+1);
            ad_addch('M');
        }
        else
        {
            ad_move_ch('M', fromY, fromX, *myp+1,*mxp+1, under,0,0, Hint_Slow);
        }
        
        if(screen[*myp][*mxp] == '@')                     /* ha! gottim! */
        {
            *howdead="a hungry monster";
            deadyet = 1;
        }
        screen[*myp][*mxp] = 'M';
        ad_refresh();
    }

    current = &start_of_list;                         /* baby monsters now */
    while((current != tail_of_list)&&(!deadyet))
    /* deal with those little monsters */
    {
        int fromX=0;
        int fromY=0;
        char under = 0;
        
        monster = current->next;
        new_disp = new_direction( monster->x, monster->y, monster->mx, monster->my );
        if(monster->under!='S')             /* if on top of another baby */
        {
            screen[monster->y][monster->x] = monster->under;
            
            fromX = monster->x+1;
            fromY = monster->y+1;
            under = monster->under;
            
            //ad_move(monster->y+1,monster->x+1);
            //ad_addch(monster->under);
            if(monster->under == ' ')
                deadyet+=check(&*mxp,&*myp,monster->x,monster->y,new_disp.d[0],new_disp.d[1],sx,sy,howdead);
        }
        
        monster->mx = new_disp.d[0];
        monster->my = new_disp.d[1];
        
        if (VIABLE(monster->x + monster->mx, monster->y + monster->my))
        {
               monster->x += monster->mx;
               monster->y += monster->my;
        }
        
        monster->under = screen[monster->y][monster->x];
        screen[monster->y][monster->x] = 'S';        /* move into new space */
        
        if (under==0)
        {
            ad_move(monster->y+1,monster->x+1);
            ad_addch('S');
        }
        else if (under!='+')
        {
            ad_move_ch('S', fromY, fromX, monster->y+1,monster->x+1, under, 0, 0, Hint_Slow);
        }
        
        
        if(monster->under == '@')                     /* monster hit you? */
        {
            *howdead="the little monsters";
            ad_refresh();
            deadyet = 1;
            monster->under = ' ';
        }
        if(monster->under == '+')                    /* monster hit cage? */
        {
            *score +=20;
            ad_score(*score);
        /* remove from chain, and insert at the end (at last_of_list) */
            if(monster == tail_of_list)
                tail_of_list = tail_of_list->prev;
            else
            {
                current->next = monster-> next;
                current->next->prev = current;
                monster->next = NULL;
                monster->prev = last_of_list;
                last_of_list->next = monster;
                last_of_list = monster;
            }
            screen[monster->y][monster->x] = '*';
            //ad_move(monster->y+1,monster->x+1);

            ad_move_ch('S', fromY, fromX, monster->y+1,monster->x+1, ' ', '*', '+', Hint_Slow);

        }
        else
            current = monster;
        ad_refresh();
    }
    return deadyet;
}
