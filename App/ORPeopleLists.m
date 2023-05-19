//
//  ORPeopleLists.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/30/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORPeopleLists.h"
#import "ORUserCell.h"
#import "ORUserProfileViewParent.h"
#import "ORPeopleSearchView.h"
#import "ORCell_ImportContactsFacebook.h"
#import "ORInviteUserCell.h"
#import "ORGroupCell.h"
#import "ORContact.h"
#import "ORManageGroup.h"

@interface ORPeopleLists () < UIScrollViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) ORPeopleSearchView *search;
@property (nonatomic, strong) UIButton *btnConnect;
@property (nonatomic, strong) UIButton *btnAllContacts;
@property (nonatomic, strong) UIButton *btnGroups;

@property (nonatomic, assign) BOOL isLoadingContacts;
@property (nonatomic, strong) NSMutableOrderedSet *allContacts;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSMutableOrderedSet *filteredContacts;

@property (nonatomic, strong) UISearchBar *searchContacts;

@end

@implementation ORPeopleLists

static NSString *friendCell = @"FriendCell";
static NSString *groupCell = @"GroupCell";

- (void)dealloc
{
    self.scrollView.delegate = nil;
    self.tblAllContacts.delegate = nil;
    self.tblGroups.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;

    self.title = @"Contacts";
	self.tabBarItem.image = [UIImage imageNamed:@"people-icon-white-40x"];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.navigationController.childViewControllers.count == 1) {
		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        self.navigationItem.leftBarButtonItem = done;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORGroupSaved:) name:@"ORGroupSaved" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORGroupDeleted:) name:@"ORGroupDeleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];

    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.screenName = @"PeopleArea";

    [self.tblAllContacts registerNib:[UINib nibWithNibName:@"ORInviteUserCell" bundle:nil] forCellReuseIdentifier:friendCell];
    [self.tblGroups registerNib:[UINib nibWithNibName:@"ORGroupCell" bundle:nil] forCellReuseIdentifier:groupCell];
	
    self.searchContacts = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
    self.searchContacts.delegate = self;
	self.searchContacts.placeholder = @"Search";
    self.tblAllContacts.tableHeaderView = self.searchContacts;
    
    [self refreshGroups];
    [self setupScrollView];
	[self setupBottomBar];
	
	[self resetBarButtonTints];
	[self refreshAllContactsForceReload:NO];

    if (self.connectTwitter) {
		[self btnConnect_TouchUpInside:nil];
	} else if (self.allContacts.count == 0) {
		[self btnConnect_TouchUpInside:nil];
	} else {
		[self btnContactList_TouchUpInside:nil];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.navigationItem.title = self.title;
	[self.view endEditing:animated];
	self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)doneAction:(id)sender
{
	[self.view endEditing:YES];
	[self.search.view endEditing:YES];
    
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [RVC showCamera];
    }
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tblAllContacts setContentOffset:CGPointMake(0.0f, -self.tblAllContacts.contentInset.top) animated:YES];
    [self.tblGroups setContentOffset:CGPointMake(0.0f, -self.tblGroups.contentInset.top) animated:YES];
}

#pragma mark - UI

- (IBAction)btnConnect_TouchUpInside:(id)sender
{
	[self resetBarButtonTints];
	[self.scrollView setContentOffset:CGPointMake(1 * self.scrollView.frame.size.width, 0) animated:NO];
	self.btnConnect.tintColor = APP_COLOR_PRIMARY;
	self.title = @"Connect";
}

- (IBAction)btnContactList_TouchUpInside:(id)sender
{
	[self resetBarButtonTints];
	[self.scrollView setContentOffset:CGPointMake(0 * self.scrollView.frame.size.width, 0) animated:NO];
	self.btnAllContacts.tintColor = APP_COLOR_PRIMARY;
	self.title = @"Contacts";
    
    [self refreshAllContactsForceReload:NO];
}

- (IBAction)btnGroups_TouchUpInside:(id)sender
{
	[self resetBarButtonTints];
	[self.scrollView setContentOffset:CGPointMake(2 * self.scrollView.frame.size.width, 0) animated:NO];
	self.btnGroups.tintColor = APP_COLOR_PRIMARY;
	self.title = @"Groups";
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addGroup:)];
    self.navigationItem.rightBarButtonItem = add;
}

#pragma mark - Custom

- (void)resetBarButtonTints
{
	UIColor *tint = [UIColor blackColor];
	self.btnAllContacts.tintColor = tint;
	self.btnGroups.tintColor = tint;
	self.btnConnect.tintColor = tint;
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)setupBottomBar
{
	// CONNECT
	self.btnConnect = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnConnect.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:11.0f];
    self.btnConnect.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
	[self.btnConnect setImage:[UIImage imageNamed:@"address-card-icon-wire-black-40x"] forState:UIControlStateNormal];
	[self.btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
	[self.btnConnect addTarget:self action:@selector(btnConnect_TouchUpInside:)forControlEvents:UIControlEventTouchUpInside];
	self.btnConnect.frame = CGRectMake(0, 0, 50, 40);
    self.btnConnect.titleEdgeInsets = UIEdgeInsetsMake(0, -50, 0, 0);
	UIBarButtonItem *barButton4 = [[UIBarButtonItem alloc] initWithCustomView:self.btnConnect];

	// ALL CONTACTS
	self.btnAllContacts = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnAllContacts.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:11.0f];
    self.btnAllContacts.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
	[self.btnAllContacts setImage:[UIImage imageNamed:@"people-icon-solid-blue-40x"] forState:UIControlStateNormal];
	[self.btnAllContacts setTitle:@"Contacts" forState:UIControlStateNormal];
	[self.btnAllContacts addTarget:self action:@selector(btnContactList_TouchUpInside:)forControlEvents:UIControlEventTouchUpInside];
	self.btnAllContacts.frame = CGRectMake(0, 0, 50, 40);
    self.btnAllContacts.titleEdgeInsets = UIEdgeInsetsMake(0, -50, 0, 0);
	UIBarButtonItem *barButton3 = [[UIBarButtonItem alloc] initWithCustomView:self.btnAllContacts];

	// GROUPS
	self.btnGroups = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnGroups.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:11.0f];
    self.btnGroups.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
	[self.btnGroups setImage:[UIImage imageNamed:@"groups-icon-wire-black-40x"] forState:UIControlStateNormal];
	[self.btnGroups setTitle:@"Groups" forState:UIControlStateNormal];
	[self.btnGroups addTarget:self action:@selector(btnGroups_TouchUpInside:)forControlEvents:UIControlEventTouchUpInside];
	self.btnGroups.frame = CGRectMake(0, 0, 50, 40);
    self.btnGroups.titleEdgeInsets = UIEdgeInsetsMake(0, -50, 0, 0);
	UIBarButtonItem *barButton5 = [[UIBarButtonItem alloc] initWithCustomView:self.btnGroups];

	UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *flex3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *flex6 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	
	self.toolbarItems = [NSArray arrayWithObjects:flex1, barButton3, flex6, barButton4, flex2, barButton5, flex3, nil]; // barButton1, flex4, barButton2, flex5
	[[UIToolbar appearance] setBackgroundColor:[UIColor whiteColor]];

}

- (void)setupScrollView
{
	self.scrollView.contentSize = CGSizeMake(3 * self.scrollView.frame.size.width, self.scrollView.frame.size.height);

	self.search = [[ORPeopleSearchView alloc] initWithNibName:@"ORPeopleSearchView" bundle:nil];
    self.search.connectTwitter = self.connectTwitter;
    
	[self addChildViewController:self.search];
	[self.scrollView addSubview:self.search.view];

	self.tblAllContacts.frame = CGRectMake(0 * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
	self.tblGroups.frame = CGRectMake(2 * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
	self.search.view.frame = CGRectMake(1 * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tblGroups)
		return self.groups.count;
	else if (tableView == self.tblAllContacts)
		return self.filteredContacts.count;
	else
		return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tblAllContacts) {
        ORInviteUserCell *cell = [tableView dequeueReusableCellWithIdentifier:friendCell forIndexPath:indexPath];
        ORContact *contact = self.filteredContacts[indexPath.row];
        cell.contact = contact;
        cell.parent = self;
        cell.btnInvite.hidden = YES;
        return cell;
	} else if (tableView == self.tblGroups) {
        ORGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:groupCell forIndexPath:indexPath];
        cell.group = self.groups[indexPath.row];;
        return cell;
	} else {
		return nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
	if (tableView == self.tblGroups) {
        ORManageGroup *vc = [[ORManageGroup alloc] initWithGroup:self.groups[indexPath.row]];
        [self.navigationController pushViewController:vc animated:YES];
	} else if (tableView == self.tblAllContacts) {
		return;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	if (tableView == self.tblAllContacts) {
		UILabel *l = [[UILabel alloc] init];
		l.text = [NSString stringWithFormat:@"%d CONTACTS", self.filteredContacts.count];
		l.textAlignment = NSTextAlignmentCenter;
		l.backgroundColor = [UIColor whiteColor];
		l.textColor = [UIColor darkGrayColor];
		return l;
	} else if (tableView == self.tblGroups) {
		UILabel *l = [[UILabel alloc] init];
		l.text = [NSString stringWithFormat:@"%d GROUPS", self.groups.count];
		l.textAlignment = NSTextAlignmentCenter;
		l.backgroundColor = [UIColor whiteColor];
		l.textColor = [UIColor darkGrayColor];
		return l;
	}
    
	return nil;
}

- (float)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	if (tableView == self.tblAllContacts || tableView == self.tblGroups) {
		return 30.0f;
	} else {
		return 0;
	}
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchBar == self.searchContacts) {
        if (!ORIsEmpty(searchText)) {
            self.filteredContacts = [NSMutableOrderedSet orderedSetWithCapacity:10];
            for (ORContact *c in self.allContacts) {
                NSUInteger result = [c.name rangeOfString:searchText options:NSCaseInsensitiveSearch].location;
                if (result != NSNotFound) [self.filteredContacts addObject:c];
            }
        } else {
            self.filteredContacts = self.allContacts;
        }
        
        [self.tblAllContacts reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (searchBar == self.searchContacts) {
        self.filteredContacts = self.allContacts;
        [self.tblAllContacts reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}

#pragma mark - Custom

- (void)refreshAllContactsForceReload:(BOOL)forceReload
{
    if (self.isLoadingContacts) return;
    
    self.isLoadingContacts = YES;
    __weak ORPeopleLists *weakSelf = self;

    [[ORDataController sharedInstance] allContactsForceReload:forceReload cacheOnly:!forceReload completion:^(NSError *error, NSMutableOrderedSet *items) {
        if (error) NSLog(@"Error: %@", error);
        
        weakSelf.allContacts = items;
        weakSelf.filteredContacts = items;
        [weakSelf.tblAllContacts reloadData];
        self.isLoadingContacts = NO;
    }];
}

#pragma mark - Groups

- (void)refreshGroups
{
    __weak ORPeopleLists *weakSelf = self;
    
    [[ORDataController sharedInstance] userGroupsForceReload:NO cacheOnly:NO completion:^(NSError *error, BOOL final, NSArray *feed) {
        if (error) NSLog(@"Error: %@", error);
        
        weakSelf.groups = [feed mutableCopy];
        [weakSelf.tblGroups reloadData];
    }];
}

- (IBAction)addGroup:(id)sender
{
    if (CurrentUser.accountType == 3) {
        [RVC presentSignInWithMessage:@"Sign-in to create a group!" completion:^(BOOL success) {
            [self refreshGroups];
        }];
        
        return;
    }

    ORManageGroup *vc = [ORManageGroup new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)handleORGroupSaved:(NSNotification *)n
{
    if (!n.object || ![n.object isKindOfClass:[OREpicGroup class]]) return;

    OREpicGroup *group = n.object;
    if (!group) return;

    [self.groups removeObject:group];
    [self.groups insertObject:group atIndex:0];
    [self.tblGroups reloadData];
}

- (void)handleORGroupDeleted:(NSNotification *)n
{
    if (!n.object || ![n.object isKindOfClass:[OREpicGroup class]]) return;
    
    OREpicGroup *group = n.object;
    if (!group) return;
    
    [self.groups removeObject:group];
    [self.tblGroups reloadData];
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
