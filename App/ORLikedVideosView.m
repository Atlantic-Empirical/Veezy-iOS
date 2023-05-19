//
//  ORLikedVideosView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 20/03/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORLikedVideosView.h"
#import "ORVideoItemCell.h"
#import "ORWatchView.h"

@interface ORLikedVideosView ()

@property (nonatomic, strong) UIRefreshControl *refresh;
@property (strong, nonatomic) NSMutableOrderedSet *videos;
@property (strong, nonatomic) NSDate *lastRefresh;
@property (nonatomic, strong) NSString *cacheFile;
@property (assign, nonatomic) BOOL shouldReload;

@end

@implementation ORLikedVideosView

static NSString *cellIdentifier = @"cellIdentifier";

- (void)dealloc
{
    self.tableView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Favorites";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    
	[self.tableView registerNib:[UINib nibWithNibName:@"ORVideoItemCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 188.0f;
    
    self.refresh = [[UIRefreshControl alloc] init];
	self.refresh.tintColor = [APP_COLOR_FOREGROUND colorWithAlphaComponent:0.3f];
    [self.refresh addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.refresh;
    
    // Load the cached results if available
    self.cacheFile = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/liked_videos.cache"];
    self.videos = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cacheFile];
    [self.tableView reloadData];
    
    if (self.lastRefresh && [[NSDate date] timeIntervalSinceDate:self.lastRefresh] < 300) return;
	self.shouldReload = YES;
	
	self.view.backgroundColor = [UIColor clearColor];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.shouldReload) {
        self.shouldReload = NO;
        self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y - self.refresh.frame.size.height);
        [self refreshAction];
    }
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

#pragma mark - Refresh

- (void)refreshAction
{
    self.lastRefresh = [NSDate date];
    [self.refresh beginRefreshing];
    
    [ApiEngine likedVideosForUser:CurrentUser.userId completion:^(NSError *error, NSArray *result) {
        if (result) {
			self.videos = [NSMutableOrderedSet orderedSetWithArray:result];
            [self.tableView reloadData];
        }
        
        [self.refresh endRefreshing];
    }];
}

#pragma mark - Table view data source

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 242;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ORVideoItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.video = self.videos[indexPath.row];
    cell.parent = self;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	ORWatchView *vc = [[ORWatchView alloc] initWithVideo:self.videos[indexPath.row]];
	[self.navigationController pushViewController:vc animated:YES];
}

@end
