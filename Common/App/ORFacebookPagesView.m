//
//  ORFacebookPagesView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 16/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORFacebookPagesView.h"
#import "ORFacebookPage.h"
#import "ORUserCell.h"

@interface ORFacebookPagesView () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *ownPages;
@property (nonatomic, strong) NSArray *filteredOwnPages;
@property (nonatomic, strong) NSArray *likedPages;
@property (nonatomic, strong) NSArray *filteredLikedPages;
@property (strong, nonatomic) UISearchBar *searchBar;

@end

@implementation ORFacebookPagesView

static NSString *fbCell = @"FBCell";

- (void)dealloc
{
    self.searchBar.delegate = nil;
    self.tableView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithOwnPages:(NSArray *)ownPages LikedPages:(NSArray *)likedPages
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.ownPages = ownPages;
    self.likedPages = likedPages;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Pick Page";
	self.screenName = @"FacebookPagePicker";
    
    if (self.navigationController.childViewControllers.count == 1) {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
        self.navigationItem.leftBarButtonItem = cancel;
    }
	
    self.filteredOwnPages = self.ownPages;
    self.filteredLikedPages = self.likedPages;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor clearColor];

    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:10];
        for (ORFacebookPage *item in self.ownPages) {
            NSUInteger result = NSNotFound;
            
            result = [item.pageName rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                [filtered addObject:item];
            }
        }
        self.filteredOwnPages = filtered;

        filtered = [NSMutableArray arrayWithCapacity:10];
        for (ORFacebookPage *item in self.likedPages) {
            NSUInteger result = NSNotFound;
            
            result = [item.pageName rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                [filtered addObject:item];
            }
        }
        self.filteredLikedPages = filtered;
    } else {
        self.filteredOwnPages = self.ownPages;
        self.filteredLikedPages = self.likedPages;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.filteredOwnPages = self.ownPages;
    self.filteredLikedPages = self.likedPages;
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 1;
    if (self.filteredOwnPages.count > 0) count++;
    if (self.filteredLikedPages.count > 0) count++;
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else if (section == 1 && self.filteredOwnPages.count > 0) {
        return @"Managed Pages";
    } else {
        return @"Liked Pages";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1 && self.filteredOwnPages.count > 0) {
        return self.filteredOwnPages.count;
    } else {
        return self.filteredLikedPages.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:fbCell];
    if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:fbCell];

    if (indexPath.section == 0) {
        NSString *fbName = CurrentUser.facebookName;
        if (ORIsEmpty(fbName)) {
            NSLog(@"Warning: Facebook Name empty, this shouldn't happen");
            fbName = CurrentUser.name;
        }

        cell.user = CurrentUser.asFriend;
        cell.textLabel.text = [NSString stringWithFormat:@"Post as %@", fbName];
        cell.detailTextLabel.text = nil;
    } else if (indexPath.section == 1 && self.filteredOwnPages.count > 0) {
        ORFacebookPage *page = self.filteredOwnPages[indexPath.row];
        cell.page = page;
        
        if (!ORIsEmpty(page.accessToken)) {
            cell.textLabel.text = [NSString stringWithFormat:@"Post as %@", page.pageName];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"Post to %@", page.pageName];
        }
    } else {
        ORFacebookPage *page = self.filteredLikedPages[indexPath.row];
        cell.page = page;
        
        if (!ORIsEmpty(page.accessToken)) {
            cell.textLabel.text = [NSString stringWithFormat:@"Post as %@", page.pageName];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"Post to %@", page.pageName];
        }
    }

    cell.textLabel.textColor = [UIColor darkGrayColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    ORFacebookPage *page = nil;
    
    if (indexPath.section == 0) {
        page = nil;
    } else if (indexPath.section == 1 && self.filteredOwnPages.count > 0) {
        page = self.filteredOwnPages[indexPath.row];
    } else {
        page = self.filteredLikedPages[indexPath.row];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORFacebookPageSelected" object:page];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Custom Methods

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

@end
