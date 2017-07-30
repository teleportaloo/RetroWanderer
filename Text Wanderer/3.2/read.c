/* File read.c */
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


#include "wand_head.h"
#include <err.h>

extern int edit_mode;
extern char *edit_screen;
extern char screen[NOOFROWS][ROWLEN+1];

extern char screen_name[62];

void inform_me(char *str, int qable)
{
    
}

#define BUF_LEN 80

char buffer[BUF_LEN];

#define NAME_LEN 500

/****************************************************************************
*                                   rscreen                                 *
*****************************************************************************/
int rscreen(num,maxmoves, basePath)
int *maxmoves, num;
const char *basePath;
{
    int  y,numr;
    FILE *fp;
    char name[NAME_LEN];
    char (*row_ptr)[ROWLEN+1] = screen;
    if(!edit_mode)
        snprintf(name,NAME_LEN, "%s%d", basePath,num);
    else
    {
        if(!edit_screen)
            snprintf(name,NAME_LEN,"./screen");
        else
            snprintf(name,NAME_LEN,"%s",edit_screen);
    }
    
    if((fp = fopen(name,"r"))== NULL)
    {
        if(edit_mode)
            snprintf(buffer,BUF_LEN, "Cannot find file %s.",name);
        else
            snprintf(buffer,BUF_LEN, "File for screen %d unavailable.",num);
        inform_me(buffer,0);
    }
    else
    {
        for(y = 0;y<NOOFROWS;y++)
        {
            fgets(*row_ptr,ROWLEN + 2,fp);
            numr = (int)strlen( *row_ptr ) - 1;
            while(numr < ROWLEN) (*row_ptr)[numr++] = ' ';
            row_ptr++;
        };
        fgets(screen_name,60,fp);
        screen_name[61] = '\0';
        screen_name[strlen(screen_name)-1] = '\0';
        if(fscanf(fp,"%d",maxmoves) != 1)
            *maxmoves=0;
        fclose(fp);
    };
    return (fp == NULL);
}

/*********************************************************************
*                              wscreen                               *
**********************************************************************/
int wscreen(num,maxmoves)
    int maxmoves, num;
{
    int  y,x;
    FILE *fp;
    char name[NAME_LEN];
    char (*row_ptr)[ROWLEN+1] = screen;
    
    if(!edit_screen)
        snprintf(name,NAME_LEN,"./screen");
    else
        snprintf(name,NAME_LEN,"%s",edit_screen);
    
    if((fp = fopen(name,"w")) == NULL)
    {
        snprintf(name,NAME_LEN,"/tmp/screen.%d",getpid());
        if((fp = fopen(name,"w")) != NULL)
        {
            snprintf(buffer,BUF_LEN,"Written file is %s",name);
            inform_me(buffer,0);
        }
        else
            err(1,"Could not open %s.\n",buffer);
    }
    if(fp == NULL)
    {
        inform_me("File for screen cannot be written.",0) ;
    }
    else
    {
        for(y = 0;y<NOOFROWS;y++)
        {
            for(x = 0;x<ROWLEN;x++)
                fputc(row_ptr[y][x],fp);
            fputc('\n',fp);
        };
        if( *screen_name == '\0' )
            fputc('#',fp);
        else
            fputs(screen_name,fp);
        fputc('\n',fp);
        if(maxmoves != 0)
            fprintf(fp,"%d\n",maxmoves);
        fclose(fp);
    };
    return (fp == NULL);
}
