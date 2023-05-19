//
//  ORPreCaptureView.m
//  Veezy
//
//  Created by Rodrigo Sieiro on 24/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORPreCaptureView.h"
#import "ORTwitterTrend.h"
#import "ORLocationPicker.h"
#import "ORNavigationController.h"
#import "ORGooglePlaceDetails.h"
#import "ORGooglePlaceDetailsGeometry.h"
#import "ORGooglePlaceDetailsGeometryLocation.h"
#import "ORFoursquareVenue.h"
#import "ORFoursquareVenueLocation.h"
#import "ORRangeString.h"
#import "ORUserCell.h"

@interface ORPreCaptureView ()

@property (assign, nonatomic) CGRect previousFrame;
@property (nonatomic, assign) BOOL captionChanged;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) ORFoursquareVenue *selectedPlace;
@property (nonatomic, strong) NSString *cachedTagsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *cachedTags;
@property (nonatomic, assign) NSRange hashtagRange;
@property (nonatomic, assign) NSRange nameRange;
@property (nonatomic, strong) NSMutableOrderedSet *allHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredUsers;
@property (nonatomic, strong) NSMutableArray *taggedUsers;
@property (nonatomic, assign) BOOL tagsChanged;
@property (nonatomic, assign) BOOL nameSearch;

@end

@implementation ORPreCaptureView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUserSignedIn:) name:@"ORUserSignedIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPlacesListLoaded:) name:@"ORPlacesListLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationSelected:) name:@"ORLocationSelected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTags) name:@"ORHashtagsLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.viewTitle.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.viewTitle.layer.borderWidth = 1.0f;
    self.viewTitle.hidden = YES;
    
    RVC.tempVideo = [OREpicVideo startNewVideo];
    RVC.tempVideo.isAvailable = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.viewTrialMode.hidden = (CurrentUser.accountType != 3);
}

- (void)btnClearCaption_TouchUpInside:(id)sender
{
    self.txtCaption.text = nil;
    self.taggedUsers = nil;
    
    [self applyFormattingForTextView:self.txtCaption];
}

- (void)btnLocation_TouchUpInside:(id)sender
{
    ORLocationPicker *vc = [[ORLocationPicker alloc] initWithPlaces:[ORDataController sharedInstance].places selectedPlace:self.selectedPlace location:AppDelegate.lastKnownLocation];
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)viewOverlay_TouchUpInside:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)btnPlus_TouchUpInside:(id)sender
{
    CGRect f = self.viewTitle.frame;
    f.origin.y = self.view.frame.size.height;
    self.viewTitle.frame = f;
    self.viewTitle.hidden = NO;
    f.origin.y = self.view.frame.size.height - self.viewTitle.frame.size.height - 12.0f;
    
    RVC.tempVideo.isAvailable = YES;
    [self autoCaption];
    
    [UIView animateWithDuration:0.3f delay:0.0f
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.viewTitle.frame = f;
                         self.btnPlus.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         self.viewBackground.hidden = NO;
                     }];
}

- (IBAction)btnTrialMode_TouchUpInside:(id)sender
{
    [RVC presentSignInWithMessage:nil completion:^(BOOL success) {
        if (success) self.viewTrialMode.hidden = YES;
    }];
}

- (IBAction)viewBackground_TouchUpInside:(id)sender
{
    CGRect f = self.viewTitle.frame;
    f.origin.y = self.view.frame.size.height;
    self.viewBackground.hidden = YES;
    
    [UIView animateWithDuration:0.3f delay:0.0f
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.viewTitle.frame = f;
                         self.btnPlus.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         self.viewTitle.hidden = YES;
                     }];
}

- (void)autoCaption
{
    if (ORIsEmpty(self.txtCaption.text) || !self.captionChanged) {
        self.txtCaption.text = [RVC.tempVideo autoCaption];
        [self applyFormattingForTextView:self.txtCaption];
        self.captionChanged = NO;
    }
}

- (void)updateCharCount
{
    int max = TWITTER_MAX_CHARS;
    int current = self.txtCaption.text.length;
    int remaining = max - current;
    self.lblChars.text = [NSString stringWithFormat:@"%d", remaining];
    self.lblChars.textColor = (remaining >= 0) ? [UIColor darkGrayColor] : [UIColor redColor];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.nameSearch) {
        return self.filteredUsers.count;
    } else {
        return self.filteredHashtags.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.nameSearch) {
        ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell"];
        if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"userCell"];
        
        cell.user = self.filteredUsers[indexPath.row];
        cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hashtagCell"];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hashtagCell"];
        
        cell.textLabel.text = self.filteredHashtags[indexPath.row];
        cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.nameSearch) {
        OREpicFriend *friend = self.filteredUsers[indexPath.row];
        NSString *name = [friend.name stringByAppendingString:@" "];
        ORRangeString *tagged = nil;
        
        if (!ORIsEmpty(name)) {
            if (self.nameRange.location < self.txtCaption.text.length) {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(self.nameRange.location, friend.name.length)];
                self.txtCaption.text = [self.txtCaption.text stringByReplacingCharactersInRange:self.nameRange withString:name];
            } else if (self.txtCaption.text) {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(self.txtCaption.text.length - 1, friend.name.length)];
                self.txtCaption.text = [self.txtCaption.text stringByAppendingString:name];
            } else {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(0, friend.name.length)];
                self.txtCaption.text = name;
            }
            
            if (tagged) {
                if (!self.taggedUsers) self.taggedUsers = [NSMutableArray arrayWithCapacity:1];
                [self.taggedUsers addObject:tagged];
            }
        }
    } else {
        NSString *hashtag = [self.filteredHashtags[indexPath.row] stringByAppendingString:@" "];
        
        if (!ORIsEmpty(hashtag)) {
            if (self.hashtagRange.location < self.txtCaption.text.length) {
                self.txtCaption.text = [self.txtCaption.text stringByReplacingCharactersInRange:self.hashtagRange withString:hashtag];
            } else if (self.txtCaption.text) {
                self.txtCaption.text = [self.txtCaption.text stringByAppendingString:hashtag];
            } else {
                self.txtCaption.text = hashtag;
            }
        }
    }
    
    [self applyFormattingForTextView:self.txtCaption];
    self.captionTableView.hidden = YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    self.viewOverlay.alpha = 0;
    self.viewOverlay.hidden = NO;
    
    CGRect f = self.viewTitle.frame;
    f.origin.x = 0;
    f.origin.y = 20.0f; // Status bar
    f.size.width = CGRectGetWidth(self.view.bounds);
    
    CGRect b = self.view.bounds;
    b.origin.y = f.origin.y;
    
    self.previousFrame = self.viewTitle.frame;
    [self updateOverlay];
    
    [UIView animateWithDuration:0.25f animations:^{
        self.viewTitle.frame = f;
        self.viewOverlay.alpha = 1.0f;
        [self updateOverlay];
    }];
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [UIView animateWithDuration:0.25f animations:^{
        self.viewTitle.frame = self.previousFrame;
        self.viewOverlay.alpha = 0;
    } completion:^(BOOL finished) {
        self.viewOverlay.hidden = YES;
    }];
    
    return YES;
}

- (void)updateOverlay
{
    CGRect of = self.viewOverlay.frame;
    of.origin.y = CGRectGetMaxY(self.viewTitle.frame);
    of.size.height = CGRectGetHeight(self.view.bounds) - 20.0f - self.viewTitle.frame.size.height - self.keyboardHeight + RVC.bottomMargin;
    
    self.viewOverlay.frame = of;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    self.captionChanged = YES;
    [self updateTaggedUsersWithRange:range replacementText:text];
    
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (ORIsEmpty(text)) range.location--;
    
    if ([newString rangeOfString:@"#"].location != NSNotFound) {
        NSCharacterSet *validSet = [NSCharacterSet alphanumericCharacterSet];
        
        unichar buffer[range.location + 2];
        [newString getCharacters:buffer range:NSMakeRange(0, range.location + 1)];
        
        NSRange hashtagRange = NSMakeRange(NSNotFound, 0);
        
        for (int i = range.location; i >= 0; i--) {
            if (![validSet characterIsMember:buffer[i]] && buffer[i] != '#') break;
            
            if (buffer[i] == '#') {
                hashtagRange.location = i;
                hashtagRange.length = (range.location - i) + 1;
                break;
            }
        }
        
        if (hashtagRange.location != NSNotFound) {
            self.hashtagRange = hashtagRange;
            [self searchTags:[newString substringWithRange:hashtagRange]];
            return YES;
        }
    }
    
    if ([newString rangeOfString:@"@"].location != NSNotFound) {
        NSCharacterSet *validSet = [NSCharacterSet alphanumericCharacterSet];
        
        unichar buffer[range.location + 2];
        [newString getCharacters:buffer range:NSMakeRange(0, range.location + 1)];
        
        NSRange nameRange = NSMakeRange(NSNotFound, 0);
        
        for (int i = range.location; i >= 0; i--) {
            if (![validSet characterIsMember:buffer[i]] && buffer[i] != '@') break;
            
            if (buffer[i] == '@') {
                nameRange.location = i;
                nameRange.length = (range.location - i) + 1;
                break;
            }
        }
        
        if (nameRange.location != NSNotFound) {
            self.nameRange = nameRange;
            [self searchNames:[newString substringWithRange:nameRange]];
            return YES;
        }
    }
    
    self.captionTableView.hidden = YES;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (!ORIsEmpty(textView.text)) {
        [self applyFormattingForTextView:textView];
    }
}

- (void)updateTaggedUsersWithRange:(NSRange)range replacementText:(NSString *)text
{
    NSMutableIndexSet *remove = [NSMutableIndexSet indexSet];
    NSUInteger idx = 0;
    
    NSRange r = NSMakeRange(range.location, MAX(range.length, 1));
    
    for (ORRangeString *string in self.taggedUsers) {
        if (NSIntersectionRange(r, string.range).length > 0) {
            [remove addIndex:idx];
        } else {
            if (range.location > string.range.location) {
                idx++;
                continue;
            }
            
            string.range = NSMakeRange(string.range.location + (text.length - range.length), string.range.length);
        }
        
        idx++;
    }
    
    if (remove.count > 0) [self.taggedUsers removeObjectsAtIndexes:remove];
}

- (void)applyFormattingForTextView:(UITextView *)textView
{
    textView.scrollEnabled = NO;
    NSRange selectedRange = textView.selectedRange;
    NSString *text = textView.text;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text
                                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:18.0f],
                                                                                                      NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:NULL];
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    for (NSTextCheckingResult *match in matches) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:APP_COLOR_LIGHT_PURPLE range:[match rangeAtIndex:0]];
    }
    
    for (ORRangeString *string in self.taggedUsers) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:APP_COLOR_LIGHT_PURPLE range:string.range];
    }
    
    textView.attributedText = attributedString;
    textView.selectedRange = selectedRange;
    textView.scrollEnabled = YES;
    
    RVC.tempVideo.name = ORIsEmpty(self.txtCaption.text) ? nil : self.txtCaption.text;
    RVC.tempVideo.taggedUsers = ORIsEmpty(self.taggedUsers) ? nil : self.taggedUsers;
    
    [self updateCharCount];
}

- (void)initCachedTags
{
    self.cachedTagsFilename = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/hashtags.cache"];
    self.cachedTags = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedTagsFilename];
    if (!self.cachedTags) self.cachedTags = [NSMutableOrderedSet orderedSetWithCapacity:1];
    
    [self reloadTags];
}

- (void)reloadTags
{
    NSMutableOrderedSet *tags = [NSMutableOrderedSet orderedSetWithCapacity:self.cachedTags.count + [ORDataController sharedInstance].twitterHashtags.count];
    
    for (NSString *tag in self.cachedTags) {
        NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSString *fixed = [[tag componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
        if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
    }
    
    for (ORTwitterTrend *hashtag in [ORDataController sharedInstance].twitterHashtags) {
        if (hashtag.name) {
            NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
            NSString *fixed = [[hashtag.name componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
            if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
        }
    }
    
    self.allHashtags = tags;
    self.filteredHashtags = self.allHashtags;
    [self.captionTableView reloadData];
}

- (void)searchTags:(NSString *)query
{
    if (self.allHashtags.count > 0 && !ORIsEmpty(query)) {
        if ([query isEqualToString:@"#"]) {
            self.filteredHashtags = self.allHashtags;
        } else {
            self.filteredHashtags = [NSMutableOrderedSet orderedSetWithCapacity:self.allHashtags.count];
            query = [query substringWithRange:NSMakeRange(1, query.length - 1)];
            
            for (NSString *hashtag in self.allHashtags) {
                NSUInteger result = [hashtag rangeOfString:query options:NSCaseInsensitiveSearch].location;
                
                if (result != NSNotFound) {
                    [self.filteredHashtags addObject:hashtag];
                }
            }
        }
        
        [self.captionTableView reloadData];
        self.captionTableView.hidden = (self.filteredHashtags.count == 0);
    } else {
        self.captionTableView.hidden = YES;
    }
}

- (void)searchNames:(NSString *)query
{
    if (CurrentUser.relatedUsers.count > 0 && !ORIsEmpty(query)) {
        if ([query isEqualToString:@"@"]) {
            self.filteredUsers = CurrentUser.relatedUsers;
        } else {
            self.filteredUsers = [NSMutableOrderedSet orderedSetWithCapacity:CurrentUser.relatedUsers.count];
            query = [query substringWithRange:NSMakeRange(1, query.length - 1)];
            
            for (OREpicFriend *friend in CurrentUser.relatedUsers) {
                NSUInteger result = [friend.name rangeOfString:query options:NSCaseInsensitiveSearch].location;
                
                if (result != NSNotFound) {
                    [self.filteredUsers addObject:friend];
                }
            }
        }
        
        self.nameSearch = YES;
        [self.captionTableView reloadData];
        self.captionTableView.hidden = (self.filteredUsers.count == 0);
    } else {
        self.captionTableView.hidden = YES;
    }
}

- (void)addTagToCache:(NSString *)tag
{
    if (!tag) return;
    
    if ([self.cachedTags containsObject:tag]) [self.cachedTags removeObject:tag];
    [self.cachedTags insertObject:tag atIndex:0];
    [NSKeyedArchiver archiveRootObject:self.cachedTags toFile:self.cachedTagsFilename];
}

- (NSArray *)extractHashtagsFromString:(NSString *)string
{
    NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSMutableArray *hashtags = [NSMutableArray arrayWithCapacity:1];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    [scanner scanUpToString:@"#" intoString:nil];
    
    while (![scanner isAtEnd]) {
        NSString *substring = nil;
        [scanner scanString:@"#" intoString:nil];
        
        if ([scanner scanUpToCharactersFromSet:notAllowedChars intoString:&substring]) {
            if (!ORIsEmpty(substring)) [hashtags addObject:[@"#" stringByAppendingString:substring]];
        }
        
        [scanner scanUpToString:@"#" intoString:nil];
    }
    
    return hashtags;
}

#pragma mark - Notifications

- (void)handleORUserSignedIn:(NSNotification *)n
{
    self.viewTrialMode.hidden = (CurrentUser.accountType != 3);
}

- (void)handleORPlacesListLoaded:(NSNotification *)n
{
    ORFoursquareVenue *pl = [[ORDataController sharedInstance].places firstObject];
    self.selectedPlace = pl;
    RVC.tempVideo.locationFriendlyName = pl.name;
    RVC.tempVideo.locationIsCity = pl.isCity;
    
    [self autoCaption];
}

- (void)handleORLocationSelected:(NSNotification*)n
{
    if (!n.object) {
        RVC.tempVideo.locationFriendlyName = nil;
        RVC.tempVideo.latitude = 0;
        RVC.tempVideo.longitude = 0;
    } else {
        ORFoursquareVenue *pl = (ORFoursquareVenue*)n.object;
        RVC.tempVideo.locationFriendlyName = pl.name;
        RVC.tempVideo.locationIsCity = pl.isCity;
        
        if (RVC.tempVideo.latitude == 0 && RVC.tempVideo.longitude == 0) {
            if (!pl.location && pl.googleId) {
                [[ORGoogleEngine sharedInstance] getPlaceDetailsWithPlaceId:pl.googleId completion:^(NSError *error, ORGooglePlaceDetails *details) {
                    RVC.tempVideo.latitude = [details.geometry.location.lat doubleValue];
                    RVC.tempVideo.longitude = [details.geometry.location.lng doubleValue];
                }];
            } else {
                RVC.tempVideo.latitude = [pl.location.lat doubleValue];
                RVC.tempVideo.longitude = [pl.location.lng doubleValue];
            }
        }
    }
    
    [self autoCaption];
}

#pragma mark - Keyboard

-(void)keyboardWillShow:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        [self updateOverlay];
    }];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.keyboardHeight = 0;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        [self updateOverlay];
    }];
}

@end
