//
//  ORTwitterPostView.m
//  Veezy
//
//  Created by Rodrigo Sieiro on 11/12/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORTwitterPostView.h"
#import "ORRangeString.h"
#import "ORTwitterTrend.h"
#import "ORTwitterPicker.h"
#import "ORTwitterAccount.h"

@interface ORTwitterPostView ()

@property (nonatomic, strong) ORTwitterPicker *twitterPicker;
@property (nonatomic, strong) OREpicVideo *video;
@property (nonatomic, copy) NSString *shareString;

@property (assign, nonatomic) CGRect previousFrame;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) NSString *cachedTagsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *cachedTags;
@property (nonatomic, assign) NSRange hashtagRange;
@property (nonatomic, strong) NSMutableOrderedSet *allHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredHashtags;
@property (nonatomic, assign) BOOL tagsChanged;

@end

@implementation ORTwitterPostView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithVideo:(OREpicVideo *)video andShareString:(NSString *)shareString
{
    self = [super init];
    if (!self) return nil;
    
    self.video = video;
    self.shareString = shareString;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Twitter";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    UIBarButtonItem *post = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleDone target:self action:@selector(post)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.rightBarButtonItem = post;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTags) name:@"ORHashtagsLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.viewTitle.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.viewTitle.layer.borderWidth = 1.0f;
    
    self.twitterPicker = [ORTwitterPicker new];
    [self addChildViewController:self.twitterPicker];
    [self.twitterPicker.view setFrame:self.viewTwitter.bounds];
    [self.viewTwitter addSubview:self.twitterPicker.view];
    [self.twitterPicker didMoveToParentViewController:self];
    
    self.twitterPicker.forceSelected = YES;
    self.twitterPicker.selected = YES;
    
    self.txtCaption.text = self.shareString;
    [self applyFormattingForTextView:self.txtCaption];
}

- (void)btnClearCaption_TouchUpInside:(id)sender
{
    self.txtCaption.text = nil;
    
    [self applyFormattingForTextView:self.txtCaption];
}

- (IBAction)viewOverlay_TouchUpInside:(id)sender
{
    [self.view endEditing:YES];
}

- (void)updateCharCount
{
    int max = TWITTER_MAX_CHARS;
    int current = self.txtCaption.text.length;
    int remaining = max - current;
    self.lblChars.text = [NSString stringWithFormat:@"%d", remaining];
    self.lblChars.textColor = (remaining >= 0) ? [UIColor darkGrayColor] : [UIColor redColor];
}

- (void)close
{
    if (self.completionBlock) self.completionBlock(NO);
}

- (void)post
{
    [self.view endEditing:YES];
    self.viewPosting.hidden = NO;
    
    if (CurrentUser.selectedTwitterAccount) {
        CurrentUser.twitterTempToken = CurrentUser.selectedTwitterAccount.token;
        CurrentUser.twitterTempSecret = CurrentUser.selectedTwitterAccount.tokenSecret;
    }
    
    NSString *text = self.txtCaption.text;
    if (text.length > TWITTER_MAX_CHARS) {
        text = [text substringWithRange:NSMakeRange(0, TWITTER_MAX_CHARS - 1)];
        text = [text stringByAppendingString:@"…"];
    }

    NSString *tweet = [NSString stringWithFormat:@"%@ %@", text, self.video.playerUrlPublic];
    
    if (!ORIsEmpty(CurrentUser.twitterTempToken) && !ORIsEmpty(CurrentUser.twitterTempSecret)) {
        [AppDelegate.twitterEngine setAccessToken:CurrentUser.twitterTempToken secret:CurrentUser.twitterTempSecret];
    }
    
    [AppDelegate.twitterEngine postTweet:tweet completion:^(NSError *error, ORTweet *tweetPosted) {
        if (error) NSLog(@"Error: %@", error);
        
        if (!ORIsEmpty(CurrentUser.twitterTempToken) && !ORIsEmpty(CurrentUser.twitterTempSecret)) {
            [AppDelegate.twitterEngine setAccessToken:CurrentUser.twitterToken secret:CurrentUser.twitterSecret];
            CurrentUser.twitterTempToken = nil;
            CurrentUser.twitterTempSecret = nil;
        }

        if (self.completionBlock) self.completionBlock(error == nil && tweetPosted != nil);
    }];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredHashtags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hashtagCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hashtagCell"];
    
    cell.textLabel.text = self.filteredHashtags[indexPath.row];
    cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
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
    
    [self applyFormattingForTextView:self.txtCaption];
    self.captionTableView.hidden = YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self.view bringSubviewToFront:self.viewOverlay];
    self.viewOverlay.alpha = 0;
    self.viewOverlay.hidden = NO;
    
    CGRect f = self.viewTitle.frame;
    f.origin.x = 0;
    f.origin.y = 0;
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
    
    self.captionTableView.hidden = YES;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (!ORIsEmpty(textView.text)) {
        [self applyFormattingForTextView:textView];
    }
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

    regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:NULL];
    matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    for (NSTextCheckingResult *match in matches) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:APP_COLOR_LIGHT_PURPLE range:[match rangeAtIndex:0]];
    }

    textView.attributedText = attributedString;
    textView.selectedRange = selectedRange;
    textView.scrollEnabled = YES;
    
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
