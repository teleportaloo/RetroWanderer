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

#import "HelpScreen.h"
#import "WandererTile.h"
#import <Social/Social.h>

@interface HelpScreen ()

@end

@implementation HelpScreen

- (void)openURL:(NSString *)link
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL success){
        if (success)
        {
            NSIndexPath *ip = self.tableView.indexPathForSelectedRow;
            if (ip!=nil)
            {
                [self.tableView deselectRowAtIndexPath:ip animated:YES];
            }
        }
        
    }];
}


- (void)facebook
{
    static NSString *fbid=@"fb://profile/176036722924346";
    static NSString *fbpath = @"https://m.facebook.com/RetroWanderer";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:fbid]])
    {
        [self openURL:fbid];
    }
    else
    {
        [self openURL:fbpath];
    }
}


- (void)addSegmentToString:(UIFont *)font bold:(bool)boldText italic:(bool)italicText color:(UIColor *)color substring:(NSString *)substring string:(NSMutableAttributedString**)string
{
    UIFont *newFont = font;
    
    Class fontDesc = (NSClassFromString(@"UIFontDescriptor"));
    
    if ((boldText || italicText) && fontDesc !=nil)
    {
        UIFontDescriptor *fontDescriptor = font.fontDescriptor;
        // DEBUG_LOGO(fontDescriptor);
        uint32_t existingTraitsWithNewTrait = (boldText ? UIFontDescriptorTraitBold : 0 ) | (italicText ? UIFontDescriptorTraitItalic : 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:existingTraitsWithNewTrait];
        // DEBUG_LOGO(fontDescriptor);
        UIFont *updatedFont = [UIFont fontWithDescriptor:fontDescriptor size:font.pointSize];
        newFont = updatedFont;
    }
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName :color,
                                 NSFontAttributeName            :newFont};
    
    
    NSAttributedString  *segment =  [[NSAttributedString alloc] initWithString:substring attributes:attributes];
    [*string appendAttributedString:segment];
}

- (bool)canTweet
{
    
    Class messageClass = (NSClassFromString(@"SLComposeViewController"));
    
    if (messageClass != nil) {
        
        return YES;
        
        // if ([TWTweetComposeViewController canSendTweet]) {
        //    return YES;
        //}
    }
    
    return NO;
}



- (void)tweet
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Twitter"
                                                                   message:@"@RetroWanderer"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    if (self.canTweet)
    {
        [alert addAction:[UIAlertAction actionWithTitle:@"Send Tweet" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    SLComposeViewController *picker = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                                                    [picker setInitialText:@"@RetroWanderer"];
                                                    
                                                    picker.completionHandler =
                                                    ^(SLComposeViewControllerResult result) {
                                                        
                                                    };
                                                    
                                                    [self presentViewController:picker animated:YES completion:nil];
                                                    
                                                }]];
    }
    
    
    NSString *twitter=@"twitter://user?screen_name=@RetroWanderer";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:twitter]])
    {
        [alert addAction:[UIAlertAction actionWithTitle:@"Show in Twitter app" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    SLComposeViewController *picker = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
                                                    [picker setInitialText:@"@RetroWanderer"];
                                                    
                                                    picker.completionHandler = ^(SLComposeViewControllerResult result) {
                                                        
                                                
                                                        
                                                    };
                                                    
                                                    [self presentViewController:picker animated:YES completion:nil];
                                                    
                                                }]];

    }
    else
    {
        NSString *twitterWeb=@"https://mobile.twitter.com/@RetroWanderer";
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Show Twitter on the web" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [self openURL:twitterWeb];
                                                }]];

       
    }
    
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                   handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}


// Use # as escape characters
// #b - bold text on or off
// #i - italic text on or off
// #X For colors see the items just below

- (NSAttributedString*)formatAttributedString:(NSString *)str regularFont:(UIFont *)regularFont
{
    NSMutableAttributedString *string = [NSMutableAttributedString alloc].init;
    NSString *substring = nil;
    
    static NSDictionary *colors = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colors = @{
                   @"0" : [UIColor blackColor],
                   @"O" : [UIColor orangeColor],
                   @"G" : [UIColor greenColor],
                   @"A" : [UIColor grayColor],
                   @"R" : [UIColor redColor],
                   @"B" : [UIColor blueColor],
                   @"Y" : [UIColor yellowColor],
                   @"W" : [UIColor whiteColor] };
        
    });
    
    bool boldText   = NO;
    bool italicText = NO;
    unichar c;
    UIColor *currentColor = [UIColor blackColor];
    
    NSScanner *escapeScanner = [NSScanner scannerWithString:str];
    
    escapeScanner.charactersToBeSkipped = nil;
    
    while (!escapeScanner.isAtEnd)
    {
        [escapeScanner scanUpToString:@"#" intoString:&substring];
        
        // DEBUG_LOGS(substring);
        
        if (!escapeScanner.isAtEnd)
        {
            escapeScanner.scanLocation++;
        }
        
        if (!escapeScanner.isAtEnd)
        {
            c = [str characterAtIndex:escapeScanner.scanLocation];
            escapeScanner.scanLocation++;
            
            if (c=='#')
            {
                if (substring)
                {
                    substring = [substring stringByAppendingString:@"#"];
                }
                else
                {
                    substring = @"#";
                }
            }
            
            if (substring && substring.length > 0)
            {
                [self addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
                substring = nil;
            }
            
            if (c=='b')
            {
                boldText = !boldText;
            }
            else if (c=='i')
            {
                italicText = !italicText;
            }
            else if (c!='#')
            {
                NSString *colorKey = [NSString stringWithCharacters:&c length:1];
                
                UIColor *newColor = colors[colorKey];
                
                if (newColor!=nil)
                {
                    currentColor = newColor;
                }
            }
        }
        else
        {
            [self addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
            substring = nil;
        }
    }
    
    return string;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-string-concatenation"
    
    self.sectionStart = [NSMutableArray array];
    
    self.rowsInOrder = @[@"title0",
                         @"link4",
                         @"#iiOS port by #BAndrew Wallace#B#i",
                         @"title1",
                         @"*", @"X", @"@", @"#", @"C", @":", @"T", @"=", @"|", @"O", @"<", @">", @"+", @"S", @"!", @"/", @"\\", @"M", @"^",
                         @"Touch #B#bSave checkpoint#b#0 to save where you are, then #B#bStart playback#b#0 to play it back again. Each screen is saved separately.",
                         @"The game will remember the moves for each screen you finish.",
                         @"Use a game controller! Buttons and dialog options are mapped to buttons on the controller too.",
                         @"title2",
                         @"link2",
                         @"link3",
                         @"link0"
                         ];
#pragma clang diagnostic pop
    
    self.textForCharacter = @{@"*" : @"Collect all the treasure...",
                              @"X" : @"...then go home.",
                              @"@" : @"This is you, use controls or swipe to move.",
                              @"#" : @"Solid rock.",
                              @"=" : @"More rock.",
                              @"|" : @"Even more rock.",
                              @"C" : @"Time capsule (#G5 points#0, #B+250#0 extra moves).",
                              @":" : @"Passable earth (#G1 point#0).",
                              @"T" : @"Teleport (#G50 points#0 for using it).",
                              @"O" : @"Boulder (falls down, other boulders and arrows fall off of it).",
                              @"<" : @"Arrow - runs #Rleft#0.",
                              @">" : @"Arrow - runs #Rright#0.",
                              @"+" : @"Cage - holds baby monster and changes into diamonds.",
                              @"S" : @"Baby monster (kills you)\nWhen a baby monster hits a cage it is captured and you get #G50 points#0. The cage also becomes a diamond.",
                              @"!" : @"#R#bInstant#b annihilation#0.",
                              @"/" : @"Slopes (boulder etc will slide off).",
                              @"\\": @"Slopes (boulder etc will slide off).",
                              @"M" : @"#b#RMonster#0#b (eats you up whole. Yum Yum Yum...) (#G100 points#0 - kill with a boulder or arrow).",
                              @"^" : @"Balloon - rises, and is popped by arrows. It does #i#bnot#b#i kill you."};
    
    self.links = @{@"link0" : @"https://github.com/teleportaloo/RetroWanderer",
                   @"link2" : @"@tweet",
                   @"link3" : @"@facebook",
                   @"link4" : @"https://github.com/teleportaloo/RetroWanderer/blob/github1.0/README.markdown"
                   };
    
    self.linkText = @{@"link0" : [NSString stringWithFormat:@"Version %@ source code & credits", [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]],
                      @"link2" : @"Twitter",
                      @"link3" : @"Facebook",
                      @"link4" : @"Original by #BSteven Shipway#0, screens developed by many others"
                      };
    
    self.linkImages = @{
                      @"link2" : @"Twitter.png",
                      @"link3" : @"Facebook.png",
                      @"link0" : @"github.png"
                      };
    
    
    self.titles = @{
                    @"title0" : @"#iRetro#i #bW A N D E R E R#b",
                    @"title1" : @"Instructions",
                    @"title2" : @"Links"
                    };
    

    for (int i=0; i<self.rowsInOrder.count; i++)
    {
        if (self.titles[self.rowsInOrder[i]]!=nil)
        {
            [self.sectionStart addObject:@(i)];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return self.sectionStart.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (section+1 < self.sectionStart.count)
    {
        return self.sectionStart[section+1].integerValue - self.sectionStart[section].integerValue - 1;
    }
    
    return self.rowsInOrder.count - self.sectionStart[section].integerValue - 1;
}

- (NSInteger)indexForPath:(NSIndexPath *)indexPath
{
    return indexPath.row +  self.sectionStart[indexPath.section].integerValue + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"1"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"1"];
    }
    
    NSString *maybeCharacter = self.rowsInOrder[[self indexForPath:indexPath]];
    NSString *textForCharacter = self.textForCharacter[maybeCharacter];
    NSString *maybeLink  = self.links[maybeCharacter];
    NSString *linkText   = self.linkText[maybeCharacter];
    NSString *linkImage   = self.linkImages[maybeCharacter];
    
    NSString *stringToFormat = maybeCharacter;
    
    if (textForCharacter)
    {
        stringToFormat = textForCharacter;
    }
    else if (linkText)
    {
        stringToFormat = linkText;
    }

    
    cell.textLabel.attributedText = [self formatAttributedString:stringToFormat regularFont:[UIFont systemFontOfSize:18]];
    cell.textLabel.numberOfLines = 0;
    
    if (textForCharacter)
    {
        WandererTile *tile = [WandererTile initTileFromCh:[maybeCharacter characterAtIndex:0]];
        cell.imageView.image = tile.image;
        if ([WandererTile retro])
        {
            cell.imageView.backgroundColor = [UIColor blackColor];
        }
        else
        {
            cell.imageView.backgroundColor = nil;
        }
    }
    else
    {
        cell.imageView.image = nil;
    }
    
    if (maybeLink)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    

    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    
    
    if (linkImage)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:linkImage ofType:nil];
        
        cell.imageView.image = [UIImage imageWithContentsOfFile:path];
        cell.imageView.backgroundColor = nil;
    }
        
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:18]];
    
    /* Section header is in 0th index... */
    
    label.attributedText = [self formatAttributedString:self.titles[self.rowsInOrder[self.sectionStart[section].integerValue]]
                                            regularFont:[UIFont systemFontOfSize:18]];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];
    [view setBackgroundColor:[UIColor grayColor]]; //your background color...
    return view;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.titles[self.rowsInOrder[self.sectionStart[section].integerValue]];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *maybeCharacter = self.rowsInOrder[[self indexForPath:indexPath]];
    NSString *maybeLink  = self.links[maybeCharacter];
    
    if ([maybeLink characterAtIndex:0]=='@')
    {
        NSString *selector = [maybeLink substringFromIndex:1];
        
        SEL action = NSSelectorFromString(selector);
        
        if ([self respondsToSelector:action])
        {
            IMP imp = [self methodForSelector:action];
            void (*func)(id, SEL) = (void (*)(id, SEL))imp;
            func(self, action);
            
        }

    }
    else if (maybeLink!=nil)
    {
        [self openURL:maybeLink];
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //minimum size of your cell, it should be single line of label if you are not clear min. then return UITableViewAutomaticDimension;
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
