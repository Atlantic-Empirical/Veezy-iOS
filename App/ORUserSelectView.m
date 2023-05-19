//
//  ORUserSelectView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORUserSelectView.h"
#import "ORUserCell.h"
#import "ORLoadingCell.h"

@interface ORUserSelectView () <UISearchBarDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) NSMutableOrderedSet *filteredUsers;
@property (nonatomic, strong) NSString *lastSearchString;
@property (nonatomic, assign) BOOL isLoadingUsers;

@end

@implementation ORUserSelectView

static NSString *loadingCell = @"LoadingCell";
static NSString *searchCell = @"SearchCell";
static NSString *userCell = @"UserCell";

- (void)dealloc
{
    self.tableView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Users";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ORLoadingCell" bundle:nil] forCellReuseIdentifier:loadingCell];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    [CurrentUser.relatedUsers sortUsingComparator:^NSComparisonResult(OREpicFriend *f1, OREpicFriend *f2) {
        return [f1.name compare:f2.name];
    }];
    
    self.lastSearchString = nil;
    self.filteredUsers = CurrentUser.relatedUsers;
    
    UISearchBar *search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    search.delegate = self;
    self.tableView.tableHeaderView = search;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isLoadingUsers) return 1;
    return (self.lastSearchString) ? self.filteredUsers.count + 1 : self.filteredUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isLoadingUsers) {
        ORLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCell forIndexPath:indexPath];
        return cell;
    }
    
    if (indexPath.row < self.filteredUsers.count) {
        ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:userCell];
        if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:userCell];
        cell.user = self.filteredUsers[indexPath.row];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:searchCell];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:searchCell];
        cell.textLabel.text = [NSString stringWithFormat:@"Search for \"%@\"", self.lastSearchString];
        cell.textLabel.textColor = cell.tintColor;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.isLoadingUsers) return;

    if (indexPath.row < self.filteredUsers.count) {
        OREpicFriend *user = self.filteredUsers[indexPath.row];
        [self.delegate userSelectView:self didSelectUser:user];
    } else {
        [self performSearch];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        self.lastSearchString = searchText;
        self.filteredUsers = [NSMutableOrderedSet orderedSetWithCapacity:10];
        for (OREpicFriend *f in CurrentUser.relatedUsers) {
            NSUInteger result = [f.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                [self.filteredUsers addObject:f];
            }
        }
    } else {
        self.lastSearchString = nil;
        self.filteredUsers = CurrentUser.relatedUsers;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.lastSearchString = nil;
    self.filteredUsers = CurrentUser.relatedUsers;
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (self.lastSearchString && self.filteredUsers.count == 0) [self performSearch];
    [self.view endEditing:YES];
}

#pragma mark - Custom

- (void)performSearch
{
    if (self.isLoadingUsers) return;
    if (!self.lastSearchString) return;
    NSString *query = self.lastSearchString;
    self.lastSearchString = nil;
    
    __weak ORUserSelectView *weakSelf = self;
    
    self.isLoadingUsers = YES;
    [self.tableView reloadData];
    
    [ApiEngine searchUsers:query completion:^(NSError *error, NSArray *result) {
        if (error) NSLog(@"Error: %@", error);
        
        weakSelf.filteredUsers = [NSMutableOrderedSet orderedSetWithArray:result];
        weakSelf.isLoadingUsers = NO;
        [weakSelf.tableView reloadData];
    }];
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate userSelectViewDidCancel:self];
}

#pragma mark - Keyboard

- (void)tapGesture:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
    
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

-(void)keyboardWillShow:(NSNotification*)notify
{
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:self.tapGesture];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    if (self.tapGesture) {
        [self.view removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

@end
