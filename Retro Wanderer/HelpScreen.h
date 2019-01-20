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

typedef void (^HelpAction)(void);

@interface HelpScreen : UITableViewController

@property (nonatomic, retain) NSArray<NSString *> *rowsInOrder;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *textForCharacter;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *links;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *linkText;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *linkImages;
@property (nonatomic, retain) NSDictionary<NSString *, NSString *> *titles;
@property (nonatomic, retain) NSMutableArray<NSNumber *> *sectionStart;
@property (nonatomic, copy) HelpAction action;
@property (nonatomic)  bool iPad;


@end
