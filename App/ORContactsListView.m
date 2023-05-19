//
//  ORFindFriendsView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 31/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <Social/Social.h>
#import "ORContactsListView.h"
#import "ORDataController.h"
#import "ORInviteUserCell.h"
#import "ORContact.h"

@interface ORContactsListView () <UISearchBarDelegate>

@property (nonatomic, assign) ORFindFriendsType type;

@property (nonatomic, strong) NSMutableOrderedSet *contacts;
@property (nonatomic, strong) NSMutableOrderedSet *filteredContacts;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation ORContactsListView

static NSString *userCell = @"UserCell";

- (void)dealloc
{
    self.tblResults.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithType:(ORFindFriendsType)type contacts:(NSMutableOrderedSet *)contacts
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.type = type;
    self.contacts = contacts;
    self.filteredContacts = contacts;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
//    if (self.navigationController.childViewControllers.count == 1) {
//		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = done;
//    }
    
	switch (self.type) {
		case ORFindFriendsAddressBook:
			self.title = @"Contacts";
			self.screenName = @"ContactsList-AddressBook";
			break;
		case ORFindFriendsFacebook:
			self.title = @"Facebook";
			self.screenName = @"ContactsList-Facebook";
			break;
		case ORFindFriendsGoogle:
			self.title = @"Google";
			self.screenName = @"ContactsList-Google";
			break;
		case ORFindFriendsTwitter:
			self.title = @"Twitter";
			self.screenName = @"ContactsList-Twitter";
			break;
			
		default:
			break;
	}
    
    [self.tblResults registerNib:[UINib nibWithNibName:@"ORInviteUserCell" bundle:nil] forCellReuseIdentifier:userCell];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    
    UISearchBar *search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    search.delegate = self;
	search.placeholder = @"Search";
	
    self.tblResults.tableHeaderView = search;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tblResults setContentOffset:CGPointMake(0.0f, -self.tblResults.contentInset.top) animated:YES];
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredContacts.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ORInviteUserCell *cell = [tableView dequeueReusableCellWithIdentifier:userCell forIndexPath:indexPath];
    ORContact *contact = self.filteredContacts[indexPath.row];
    cell.contact = contact;
    cell.parent = self;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!ORIsEmpty(searchText)) {
        self.filteredContacts = [NSMutableOrderedSet orderedSetWithCapacity:10];
        for (ORContact *c in self.contacts) {
            NSUInteger result = [c.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                [self.filteredContacts addObject:c];
            }
        }
    } else {
        self.filteredContacts = self.contacts;
    }
    
    [self.tblResults reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.filteredContacts = self.contacts;
    [self.tblResults reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
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
