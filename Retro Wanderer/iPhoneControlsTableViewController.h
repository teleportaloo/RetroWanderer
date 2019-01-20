/***************************************************************************
 *  Copyright 2017 -   Andrew Wallace                                       *
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

#import <UIKit/UIKit.h>

@class GameViewControlleriPhone;

#define kStart          @"▶️ Start playback"
#define kStartOver      @"↩️ #RStart over#0"
#define kSaveCheckpoint @"💾 Save checkpoint"
#define kStop           @"⏹ Stop playback"


typedef void (^SelectAction)();
typedef NSString* (^ProcessAction)();

@interface iPhoneControlsTableViewController : UITableViewController
{
    GameViewControlleriPhone *_game;   // weak
}

@property (nonatomic, retain) NSMutableArray<NSString *> *rowsInOrder;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *titles;
@property (nonatomic, retain) NSDictionary<NSString *, SelectAction> *pushAction;
@property (nonatomic, retain) NSDictionary<NSString *, SelectAction> *closeAction;
@property (nonatomic, retain) NSDictionary<NSString *, ProcessAction> *processAction;
@property (nonatomic, retain) NSMutableArray<NSNumber *> *sectionStart;


@end
