//
//  ORHashtagPicker.m
//  Session
//
//  Created by Thomas Purnell-Fisher on 11/13/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORHashtagPicker.h"
#import "ORTwitterTrend.h"

@interface ORHashtagPicker () <UIScrollViewDelegate>

@property (nonatomic, strong) UIRefreshControl *refresh;
@property (nonatomic, strong) NSString *cachedTagsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *cachedTags;
@property (nonatomic, strong) NSMutableOrderedSet *allHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredHashtags;

@end

@implementation ORHashtagPicker

static NSString *hashtagCell = @"hashtagCell";

- (void)dealloc
{
    self.tbMain.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORHashtagsLoaded:) name:@"ORHashtagsLoaded" object:nil];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Hashtags";
	self.screenName = @"HashtagPicker";

    if (self.navigationController.viewControllers.count < 2) {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.rightBarButtonItem = cancel;
    }

    [self txtSearch_EditingChanged:nil];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tbMain;
    
	self.refresh = [[UIRefreshControl alloc] init];
    [self.refresh addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
	self.refresh.tintColor = [APP_COLOR_PRIMARY colorWithAlphaComponent:0.3f];
    tableViewController.refreshControl = self.refresh;
    
    [self initCachedTags];
    [self reloadTags];
}

- (void)cancelAction:(id)sender
{
	[self close];
}

- (void)close
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [RVC showCamera];
    }
}

- (void)handleORHashtagsLoaded:(NSNotification *)n
{
    [self reloadTags];
}

#pragma mark - UI

- (void)txtSearch_EditingChanged:(id)sender
{
    NSString *query = self.txtSearch.text;
    
    if (!query || [query isEqualToString:@""]) {
        self.filteredHashtags = self.allHashtags;
		[self.tbMain reloadData];
    } else {
        NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSString *hashQuery = [[query componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
        if (!ORIsEmpty(hashQuery)) hashQuery = ([hashQuery hasPrefix:@"#"]) ? hashQuery : [@"#" stringByAppendingString:hashQuery];
        
        self.filteredHashtags = [NSMutableOrderedSet orderedSetWithCapacity:1];
        BOOL foundExact = NO;
        
        for (NSString *tag in self.allHashtags) {
            NSUInteger result = [tag rangeOfString:query options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                if ([tag caseInsensitiveCompare:hashQuery] == NSOrderedSame) foundExact = YES;
                [self.filteredHashtags addObject:tag];
            }
        }
        
        if (!foundExact && !ORIsEmpty(hashQuery)) {
            [self.filteredHashtags insertObject:hashQuery atIndex:0];
        }
		
        [self.tbMain reloadData];
    }
}

- (void)btnCancelSearch_TouchUpInside:(id)sender
{
    self.selectedHashtag = nil;
	[self close];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.view endEditing:YES];
}

#pragma mark - Refresh

- (void)refreshAction
{
    [self.refresh beginRefreshing];
    [self reloadTags];
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.filteredHashtags.count + 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:hashtagCell];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:hashtagCell];
    cell.imageView.image = nil;
    cell.backgroundColor = [UIColor clearColor];

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Clear Hashtags";
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.text = self.filteredHashtags[indexPath.row - 1];
        cell.textLabel.textColor = APP_COLOR_PRIMARY;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row > self.filteredHashtags.count) return;
    
    if (indexPath.row == 0) {
        self.selectedHashtag = nil;
    } else {
        self.selectedHashtag = self.filteredHashtags[indexPath.row - 1];
        [self addTagToCache:self.selectedHashtag];
    }

    [self.txtSearch resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORHashtagSelected" object:self.selectedHashtag];
	[self close];
}

#pragma mark - Hashtags Search

- (void)initCachedTags
{
    self.cachedTagsFilename = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/hashtags.cache"];
    self.cachedTags = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedTagsFilename];
    if (!self.cachedTags) self.cachedTags = [NSMutableOrderedSet orderedSetWithCapacity:1];
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
    
    [self.tbMain reloadData];
    [self.refresh endRefreshing];
}

- (void)addTagToCache:(NSString *)tag
{
    if (!tag) return;
    
    if ([self.cachedTags containsObject:tag]) [self.cachedTags removeObject:tag];
    [self.cachedTags insertObject:tag atIndex:0];
    [NSKeyedArchiver archiveRootObject:self.cachedTags toFile:self.cachedTagsFilename];
}

@end
