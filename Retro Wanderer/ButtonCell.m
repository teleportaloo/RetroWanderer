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

#import "ButtonCell.h"

#define kButtonSide (40)
#define kButtonGap (10)
#define kButtonRowHeight (50)


@implementation ButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.buttonWidth = kButtonSide;
        self.buttonHeight = kButtonSide;
        self.rowHeight  = kButtonRowHeight;
        self.buttonGap  = kButtonGap;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)createButtons
{
    self.buttons = [NSMutableArray array];
    for (int i=0;  i<self.numberOfButtons; i++)
    {
        CGRect frame = CGRectMake(self.buttonGap + (self.buttonGap + self.buttonWidth) * i,  (self.rowHeight - self.buttonHeight)/2, self.buttonWidth, self.buttonHeight);
        UIButton *button = [[UIButton alloc] initWithFrame:frame];
        self.buttons[i] = button;
        [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:button];
    }
    CGRect labelFrame = CGRectMake(self.buttonGap + (self.buttonGap + self.buttonWidth) , (self.rowHeight - self.buttonHeight)/2, (self.buttonWidth+self.buttonGap)*(self.numberOfButtons-1)-self.buttonGap , self.buttonHeight);
    
    self.rightLabel = [[UILabel alloc] initWithFrame:labelFrame];
    
    [self.contentView addSubview:self.rightLabel];

    [self layoutSubviews];
}

- (void)buttonTouched:(id)sender
{
    UIButton *touched = (UIButton *)sender;
    for (int i = 0; i<self.buttons.count; i++)
    {
        if (self.buttons[i] == touched)
        {
            self.action(i);
            break;
        }
    }
}

+ (CGFloat)cellHeight
{
    return kButtonRowHeight;
}

@end
