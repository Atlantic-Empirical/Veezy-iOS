//
//  ORManageGroup.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORManageGroup.h"
#import "ORUserCell.h"
#import "ORUserProfileViewParent.h"
#import "ORUserSelectView.h"
#import "ORNavigationController.h"

@interface ORManageGroup () <UIAlertViewDelegate, ORUserSelectViewDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) NSMutableOrderedSet *users;
@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, assign) BOOL isNewGroup;
@property (nonatomic, assign) BOOL isGroupOwner;

@end

@implementation ORManageGroup

static NSString *userCell = @"UserCell";
static NSString *buttonCell = @"ButtonCell";

- (void)dealloc
{
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithGroup:(OREpicGroup *)group
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    _group = group;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if (self.group.name)
		self.title = self.group.name;
	else
		self.title = @"Group";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    if (self.group) {
        self.isNewGroup = NO;
        [self loadGroup];
    } else {
        self.isNewGroup = YES;
        [self newGroup];
    }
    
    self.isGroupOwner = [CurrentUser.userId isEqualToString:self.group.ownerId];
    self.txtName.enabled = self.isGroupOwner;
    [self.tableView reloadData];
    
    if (self.isGroupOwner) {
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveGroup:)];
        self.navigationItem.rightBarButtonItem = save;
    }
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (!self.isNewGroup) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return (self.isGroupOwner) ? self.users.count + 1 : self.users.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < self.users.count) {
            ORUserCell *cell = [tableView dequeueReusableCellWithIdentifier:userCell];
            if (!cell) cell = [[ORUserCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:userCell];
            cell.user = self.users[indexPath.row];
            
            if ([cell.user.userId isEqualToString:self.group.ownerId]) {
                cell.detailTextLabel.text = @"Group Owner";
                cell.detailTextLabel.textColor = [UIColor lightGrayColor];
            } else {
                cell.detailTextLabel.text = nil;
            }
            
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCell];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonCell];
            cell.textLabel.text = @"Add Member";
            cell.textLabel.textColor = cell.textLabel.tintColor;
            return cell;
        }
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCell];
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:buttonCell];
        cell.textLabel.text = (self.isGroupOwner) ? @"Delete Group" : @"Leave Group";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor redColor];
        return cell;
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return [NSString stringWithFormat:@"Members (%d)", self.users.count];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 0) {
        if (indexPath.row < self.users.count) {
            ORUserProfileViewParent *profile = [[ORUserProfileViewParent alloc] initWithFriend:self.users[indexPath.row]];
            [self.navigationController pushViewController:profile animated:YES];
        } else {
            ORUserSelectView *vc = [ORUserSelectView new];
            vc.delegate = self;
            
            ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
    } else if (indexPath.section == 1) {
        if (self.isGroupOwner) {
            [self askDeleteGroup];
        } else {
            [self askLeaveGroup];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isGroupOwner) return NO;
    if (indexPath.section != 0) return NO;
    if (indexPath.row >= self.users.count) return NO;
    
    OREpicFriend *friend = self.users[indexPath.row];
    if ([friend.userId isEqualToString:self.group.ownerId]) return NO;
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 0) return;
    if (indexPath.row >= self.users.count) return;
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.users removeObjectAtIndex:indexPath.row];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - ORUserSelectViewDelegate

- (void)userSelectViewDidCancel:(ORUserSelectView *)userSelect
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)userSelectView:(ORUserSelectView *)userSelect didSelectUser:(OREpicFriend *)user
{
    [self.users addObject:user];
    [self.tableView reloadData];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Custom

- (void)loadGroup
{
    self.txtName.text = self.group.name;
    [self.tableView reloadData];
    
    self.users = [NSMutableOrderedSet orderedSetWithCapacity:self.group.userIds.count];
    NSMutableArray *unknownIds = [NSMutableArray arrayWithCapacity:self.group.userIds.count];
    
    for (NSString *userId in self.group.userIds) {
        OREpicFriend *empty = [[OREpicFriend alloc] initWithId:userId];
        NSUInteger idx = [CurrentUser.relatedUsers indexOfObject:empty];
        
        if (idx != NSNotFound) {
            [self.users addObject:[CurrentUser.relatedUsers objectAtIndex:idx]];
        } else {
            [self.users addObject:empty];
            [unknownIds addObject:userId];
        }
    }
    
    if (unknownIds.count > 0) {
        __weak ORManageGroup *weakSelf = self;
        
        [ApiEngine friendsWithIds:unknownIds completion:^(NSError *error, NSArray *result) {
            if (error) NSLog(@"Error: %@", error);
            
            for (OREpicFriend *friend in result) {
                NSUInteger idx = [weakSelf.users indexOfObject:friend];
                
                if (idx != NSNotFound) {
                    [weakSelf.users replaceObjectAtIndex:idx withObject:[CurrentUser relatedUserWithUser:friend]];
                } else {
                    [weakSelf.users addObject:[CurrentUser relatedUserWithUser:friend]];
                }
                
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)newGroup
{
    self.group = [OREpicGroup new];
    self.group.groupId = [ORUtility newGuidString];
    self.group.ownerId = CurrentUser.userId;
    self.group.userIds = [NSMutableArray arrayWithObject:CurrentUser.userId];
    
    [self loadGroup];
}

- (IBAction)saveGroup:(id)sender
{
    if (ORIsEmpty(self.txtName.text)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Group"
                                                        message:@"Please type a group name"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self.txtName becomeFirstResponder];
        return;
    }
    
    self.group.name = self.txtName.text;
    
    self.group.userIds = [NSMutableArray arrayWithCapacity:self.users.count];
    for (OREpicFriend *user in self.users) {
        [self.group.userIds addObject:user.userId];
    }
    
    [ApiEngine saveGroup:self.group cb:^(NSError *error, OREpicGroup *group) {
        if (error) NSLog(@"Error: %@", error);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGroupSaved" object:self.group];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)askLeaveGroup
{
    self.alertView.delegate = nil;
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                message:@"You won't be able to rejoin this group unless the owner adds you again. Are you sure?"
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Leave Group", nil];
    self.alertView.tag = 2;
    [self.alertView show];
}

- (void)leaveGroup
{
    [ApiEngine leaveGroupWithId:self.group.groupId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGroupDeleted" object:self.group];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)askDeleteGroup
{
    self.alertView.delegate = nil;
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                message:@"This group and all its messages will be deleted. You cannot undo this action. Delete this group?"
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Delete Group", nil];
    self.alertView.tag = 1;
    [self.alertView show];
}

- (void)deleteGroup
{
    [ApiEngine deleteGroupWithId:self.group.groupId cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORGroupDeleted" object:self.group];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    
    if (alertView.tag == 1) { // Delete Group
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self deleteGroup];
        }
    } else if (alertView.tag == 2) { // Leave Group
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self leaveGroup];
        }
    }
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
