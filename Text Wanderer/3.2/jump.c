/* File jump.c */
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


#include "wand_head.h"

#if 0

extern int debug_disp;
extern int no_passwords;
extern int maxscreens;

/************************************************************ 
*                   function scrn_passwd                    *
*              reads password num into passwd               *
*************************************************************/
int scrn_passwd(num, passwd)    /* reads password num into passwd */
int num;
char *passwd;
{
        long position;
        FILE *fp;

        position = PASSWD;
        while(position > 200000)
                position -= 200000;
        if((fp = fopen(DICTIONARY,"r")) == NULL)
                return 0;
        fseek(fp,position,(int)ftell(fp));
        while(fgetc(fp) != '\n');
        fscanf(fp,"%s\n",passwd);
        /* read a word into passwd */
        fclose(fp);
        return (1);
}

/*******************************************************
*                   function showpass                  *
********************************************************/
void showpass(num)
     int num;
{
    // long position;
    char correct[20];
    char buffer[100];
    // FILE *fp;
    // char ch;
    if(no_passwords)
        return;
    if(!debug_disp)
        st_move(18,0);
    else
        st_move(20,0);
    if(!scrn_passwd(num,correct))
        return;
    (void) sprintf(buffer,"The password to jump to level %d ( using ~ ) is : %s        \n",(num+1),correct);
    st_addstr(buffer);
    st_addstr("PRESS ANY KEY TO REMOVE IT AND CONTINUE                          \n");
    st_refresh();
    // ch = userinput();
    if(!debug_disp)
        st_move(18,0);
    else
        st_move(20,0);
    st_addstr("                                                                        \n");
    st_addstr("                                              ");
    if(!debug_disp)
        st_move(18,0);
    else
        st_move(20,0);
    st_refresh();
}

/**********************************************************
*                    function jumpscreen                  *
***********************************************************/
#if 0
int jumpscreen(num)
    int num;
{
    char word[20],
         buffer[100],
         correct[20];
    int index=0; //, input;
    // char ch;
    // long position;
    int  /*fp,*/ scrn;

    if(no_passwords == 1) {
        if(!debug_disp)
            st_move(16,0);
        else
            st_move(18,0);
        st_addstr("Enter number of desired level.\n");
        st_refresh();
        scrn = getnum();
        if(scrn > num) {
            if(!debug_disp)
                st_move(16,0);
            else
                st_move(18,0);
            st_addstr("                                                ");
            return scrn;
            }
        if(!debug_disp)
            st_move(16,0);
        else
            st_move(18,0);
        st_addstr("No way, Jose! Back-jumping is prohibited!");
        st_refresh();
        return num;
    }

    if(!debug_disp)
        st_move(16,0);
    else
        st_move(18,0);
    st_addstr("Please enter password of screen to jump to:");
    st_refresh();
    while(((word[index++] = userinput()) != '\n')&&(index < 19))
    {
        st_addch('*');
        st_refresh();
    }
    word[--index]='\0';
    if(!debug_disp)
        st_move(16,0);
    else
        st_move(18,0);
    st_addstr("Validating...                                             \n");
    st_refresh();

    if(strcmp(word,MASTERPASSWORD) == 0)
    {
        if(!debug_disp)
            st_move(16,0);
        else
            st_move(18,0);
        st_addstr("Enter number of desired level.");
        st_refresh();
        num = getnum();
        (void) scrn_passwd(num-1,correct);
        sprintf(buffer,"Certainly master, but the correct word is %s.       \n",correct);
        if(!debug_disp)
            st_move(16,0);
        else
            st_move(18,0);
        st_addstr(buffer);
        st_addstr("PRESS ANY KEY TO REMOVE IT AND CONTINUE                          \n");
        st_refresh();
        // userinput();
        if(!debug_disp)
            st_move(16,0);
        else
            st_move(18,0);
        st_addstr("                                                             ");
        if(!debug_disp)
            st_move(17,0);
        else
            st_move(19,0);
        st_addstr("                                                             ");
        if(!debug_disp)
            st_move(16,0);
        else
            st_move(18,0);
        st_refresh();
        return num;
    }

    for(scrn = num;scrn < maxscreens;scrn++) {
        if(!scrn_passwd(scrn,correct))
            break;
        if(strcmp(correct,word) == 0)
        {
            if(!debug_disp)
                st_move(16,0);
            else
                st_move(18,0);
            st_addstr("Password Validated..... Jumping to desired screen.        ");
            st_refresh();
            return ++scrn;
        }
    }

    if(!debug_disp)
        st_move(16,0);
    else
        st_move(18,0);
    st_addstr("PASSWORD NOT RECOGNISED!                    ");
    st_refresh();
    usleep(750000);  /* Marina */
    if(!debug_disp)
        st_move(16,0);
    else
        st_move(18,0);
    st_addstr("                                                          ");

    return num;
}
#endif

/***********************************************************
*                     function getnum                      *
************************************************************/
#if 0
int getnum()
{
    char ch;
    int num = 0;

    for(ch = userinput(),st_addch(ch),st_refresh(); 
        ch >= '0' && ch <= '9'; 
        ch = getch(),st_addch(ch),st_refresh())
    {
        num = num * 10 + ch - '0';
    }
    return num;
}
#endif

#endif
