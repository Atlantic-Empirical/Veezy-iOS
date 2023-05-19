//
//  ORWatchView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 23/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORWatchView.h"
#import "ORWatchVideoCell.h"
#import "ORCommentCell.h"
#import "ORMyCommentCell.h"
#import "ORTypingCell.h"
#import "ORVideoManagerView.h"
#import "ORViewsCell.h"
#import "ORLikesCell.h"
#import "ORReposterCell.h"
#import "ORAllowedCell.h"
#import "ORSeparatorCell.h"
#import "ORDirectSendView.h"
#import "ORNavigationController.h"
#import "ORRangeString.h"
#import "ORUserCell.h"

#define COMMENT_PLACEHOLDER @"Send a message"

@interface ORWatchView () <UIAlertViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, ORContactSelectViewDelegate>

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSMutableOrderedSet *comments;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL *pausedOnEnterBackground;
@property (nonatomic, assign) BOOL sentTypingNotification;
@property (nonatomic, assign) BOOL isWVVisible;

@property (nonatomic, assign) NSInteger viewsRow;
@property (nonatomic, assign) NSInteger likesRow;
@property (nonatomic, assign) NSInteger repostsRow;
@property (nonatomic, assign) NSInteger privacyRow;
@property (nonatomic, assign) NSInteger separatorRow;

@property (nonatomic, strong) OREpicVideoComment *selectedComment;
@property (nonatomic, strong) ORWatchVideoCell *videoCell;

@property (nonatomic, assign) NSRange hashtagRange;
@property (nonatomic, assign) NSRange nameRange;
@property (nonatomic, strong) NSString *cachedTagsFilename;
@property (nonatomic, strong) NSMutableOrderedSet *cachedTags;
@property (nonatomic, strong) NSMutableOrderedSet *allHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredHashtags;
@property (nonatomic, strong) NSMutableOrderedSet *filteredUsers;
@property (nonatomic, strong) NSMutableArray *taggedUsers;
@property (nonatomic, assign) BOOL tagsChanged;
@property (nonatomic, assign) BOOL nameSearch;

@end

@implementation ORWatchView

static NSString *allowedCell = @"allowedCell";
static NSString *commentCell = @"commentCell";
static NSString *myCommentCell = @"myCommentCell";
static NSString *typingCell = @"typingCell";
static NSString *viewsCell = @"viewsCell";
static NSString *likeCell = @"likeCell";
static NSString *repostCell = @"repostCell";
static NSString *separatorCell = @"separatorCell";

- (void)dealloc
{
    [self.videoCell stop];
    self.tableView.delegate = nil;
    self.alertView.delegate = nil;
    self.actionSheet.delegate = nil;
    self.tapGesture.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithVideo:(OREpicVideo *)video
{
    self = [super init];
    if (!self) return nil;
    
    self.videoId = video.videoId;
    self.video = video;
    
    return self;
}

- (id)initWithVideoId:(NSString *)videoId
{
    self = [super init];
    if (!self) return nil;
    
    self.videoId = videoId;
    self.video = nil;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.screenName = @"WatchVideo";
    
    [self registerForNotifications];
    [self initCachedTags];
    [self reloadTags];
    
    if (self.navigationController.childViewControllers.count == 1) {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
        self.navigationItem.leftBarButtonItem = done;
    }
	
    [self.tableView registerNib:[UINib nibWithNibName:@"ORAllowedCell" bundle:nil] forCellReuseIdentifier:allowedCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORCommentCell" bundle:nil] forCellReuseIdentifier:commentCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORMyCommentCell" bundle:nil] forCellReuseIdentifier:myCommentCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORTypingCell" bundle:nil] forCellReuseIdentifier:typingCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORReposterCell" bundle:nil] forCellReuseIdentifier:repostCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORLikesCell" bundle:nil] forCellReuseIdentifier:likeCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORViewsCell" bundle:nil] forCellReuseIdentifier:viewsCell];
    [self.tableView registerNib:[UINib nibWithNibName:@"ORSeparatorCell" bundle:nil] forCellReuseIdentifier:separatorCell];
    
    self.comments = [NSMutableOrderedSet orderedSetWithCapacity:1];
    
    if (self.video) {
        [self.aiLoading stopAnimating];
        self.tableView.hidden = NO;
        
        [self reloadCommentsAndScroll:self.shouldScrollToBottom];

        if ([CurrentUser.userId isEqualToString:self.video.userId]) {
            UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(presentVideoManager)];
            self.navigationItem.rightBarButtonItem = edit;
        }

        if (self.video.state == OREpicVideoStateExpired) {
            self.alertView.delegate = nil;
            self.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                        message:@"This video is expired."
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
            self.alertView.tag = 0;
            [self.alertView show];
        }
    } else {
        [self loadVideo];
    }
    
    self.videoCell = [[[NSBundle mainBundle] loadNibNamed:@"ORWatchVideoCell" owner:self options:nil] firstObject];
    
    self.txtComment.layer.cornerRadius = 4.0f;
	self.txtComment.layer.borderColor = [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1].CGColor;
	self.txtComment.layer.borderWidth = 1.0f;
    self.txtComment.text = COMMENT_PLACEHOLDER;
    self.txtComment.textColor = [UIColor lightGrayColor];
    self.btnSend.enabled = NO;
    [self setTextViewOriginalSize];
	self.aiLoading.color = APP_COLOR_PRIMARY;
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

- (void)viewWillAppear:(BOOL)animated
{
	self.title = @"W  A  T  C  H";
}

- (void)viewWillDisappear:(BOOL)animated
{
	self.title = @"WATCH";
    [self.videoCell stop];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.isWVVisible = YES;
    [self.videoCell play];
	
    if (self.video && self.shouldOpenManager && [CurrentUser.userId isEqualToString:self.video.userId]) {
        self.shouldOpenManager = NO;
        [self presentVideoManager];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.isWVVisible = NO;
    [self removeTypingNotification];
}

#pragma mark - Orientation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.view endEditing:YES];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self configureForOrientation:toInterfaceOrientation];
}

- (void)configureForOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        self.commentView.hidden = YES;
        self.tblTags.hidden = YES;
        self.tableView.scrollEnabled = NO;
        self.tableView.contentOffset = CGPointMake(0, 115.0f);
    } else {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.commentView.hidden = NO;
        self.tableView.scrollEnabled = YES;
        self.tableView.contentOffset = CGPointMake(0, 0);
    }
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (section == 0) {
            if (!self.video) return 0;

            self.viewsRow = NSNotFound;
            self.likesRow = NSNotFound;
            self.repostsRow = NSNotFound;
            self.privacyRow = NSNotFound;
            self.separatorRow = NSNotFound;
            
            NSInteger count = 1;
            
            if (self.video.uniqueViewCount > 0) {
                self.viewsRow = count;
                count++;
            }
            
            if (self.video.likeCount > 0) {
                self.likesRow = count;
                count++;
            }
            
            if (self.video.repostCount > 0) {
                self.repostsRow = count;
                count++;
            }
            
            self.privacyRow = count;
            count++;
            
            self.separatorRow = count;
            count++;

            return count;
        } else {
            return self.comments.count;
        }
    } else {
        if (self.nameSearch) {
            return self.filteredUsers.count;
        } else {
            return self.filteredHashtags.count;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 525.0f : [self.videoCell heightForCellWithVideo:self.video];
            } else if (indexPath.row == self.viewsRow) {
                return 24.0f;
            } else if (indexPath.row == self.likesRow) {
                return 24.0f;
            } else if (indexPath.row == self.repostsRow) {
                return 24.0f;
            } else if (indexPath.row == self.privacyRow) {
                return [ORAllowedCell heightForCellWithVideo:self.video];
            } else if (indexPath.row == self.separatorRow) {
                return 30.0f;
            } else {
                return 0;
            }
        } else {
            OREpicVideoComment *comment = self.comments[indexPath.row];
            if (comment.isTyping) return 30.0f;
            if (comment.cachedHeight == 0) comment.cachedHeight = [ORCommentCell heightForCellWithComment:comment];
            return comment.cachedHeight;
        }
    } else {
        return 44.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                self.videoCell.parent = self;
                self.videoCell.video = self.video;
                return self.videoCell;
            } else if (indexPath.row == self.viewsRow) {
                ORViewsCell *cell = [tableView dequeueReusableCellWithIdentifier:viewsCell forIndexPath:indexPath];
                cell.parent = self;
                cell.video = self.video;
                return cell;
            } else if (indexPath.row == self.likesRow) {
                ORLikesCell *cell = [tableView dequeueReusableCellWithIdentifier:likeCell forIndexPath:indexPath];
                cell.parent = self;
                cell.video = self.video;
                return cell;
            } else if (indexPath.row == self.repostsRow) {
                ORReposterCell *cell = [tableView dequeueReusableCellWithIdentifier:repostCell forIndexPath:indexPath];
                cell.parent = self;
                cell.video = self.video;
                return cell;
            } else if (indexPath.row == self.privacyRow) {
                ORAllowedCell *cell = [tableView dequeueReusableCellWithIdentifier:allowedCell forIndexPath:indexPath];
                cell.video = self.video;
                return cell;
            } else if (indexPath.row == self.separatorRow) {
                ORSeparatorCell *cell = [tableView dequeueReusableCellWithIdentifier:separatorCell forIndexPath:indexPath];
                return cell;
            } else {
                return nil;
            }
        } else {
            OREpicVideoComment *comment = self.comments[indexPath.row];
            
            if (comment.isTyping) {
                ORTypingCell *cell = [tableView dequeueReusableCellWithIdentifier:typingCell forIndexPath:indexPath];
                cell.comment = comment;
                return cell;
            } else if ([comment.userId isEqualToString:CurrentUser.userId]) {
                ORMyCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:myCommentCell forIndexPath:indexPath];
                cell.parent = self;
                cell.comment = comment;
                
                if (comment.isFailed) {
                    cell.backgroundColor = APP_COLOR_LIGHT_RED;
                } else {
                    cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREEN : APP_COLOR_LIGHTER_GREEN;
                }
                
                return cell;
            } else {
                ORCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:commentCell forIndexPath:indexPath];
                cell.parent = self;
                cell.comment = comment;
                cell.backgroundColor = (indexPath.row % 2 == 0) ? APP_COLOR_LIGHT_GREY : APP_COLOR_LIGHTER_GREY;
                return cell;
            }
        }
    } else {
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (tableView == self.tableView) {
        if (indexPath.section == 1) {
            OREpicVideoComment *comment = self.comments[indexPath.row];
            
            if ([comment.userId isEqualToString:CurrentUser.userId]) {
                if (comment.isFailed) {
                    [self sendComment:comment];
                } else if (!comment.isPending) {
                    self.actionSheet.delegate = nil;
                    self.actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"You: \"%@\"", comment.comment]
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:@"Delete"
                                                          otherButtonTitles:nil];
                    self.actionSheet.tag = 1;
                    self.selectedComment = comment;
                    [self.actionSheet showInView:self.view];
                }
            } else if ([self.video.userId isEqualToString:CurrentUser.userId]) {
                self.actionSheet.delegate = nil;
                self.actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@: \"%@\"", comment.user.firstName, comment.comment]
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                 destructiveButtonTitle:@"Delete"
                                                      otherButtonTitles:nil];
                self.actionSheet.tag = 1;
                self.selectedComment = comment;
                [self.actionSheet showInView:self.view];
            }
        }
    } else {
        if (self.nameSearch) {
            OREpicFriend *friend = self.filteredUsers[indexPath.row];
            NSString *name = [friend.name stringByAppendingString:@" "];
            ORRangeString *tagged = nil;
            
            if (self.nameRange.location < self.txtComment.text.length) {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(self.nameRange.location, friend.name.length)];
                self.txtComment.text = [self.txtComment.text stringByReplacingCharactersInRange:self.nameRange withString:name];
            } else if (self.txtComment.text) {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(self.txtComment.text.length - 1, friend.name.length)];
                self.txtComment.text = [self.txtComment.text stringByAppendingString:name];
            } else {
                tagged = [[ORRangeString alloc] initWithString:friend.userId range:NSMakeRange(0, friend.name.length)];
                self.txtComment.text = name;
            }
            
            if (tagged) {
                if (!self.taggedUsers) self.taggedUsers = [NSMutableArray arrayWithCapacity:1];
                [self.taggedUsers addObject:tagged];
            }
        } else {
            NSString *hashtag = [self.filteredHashtags[indexPath.row] stringByAppendingString:@" "];
            
            if (self.hashtagRange.location < self.txtComment.text.length) {
                self.txtComment.text = [self.txtComment.text stringByReplacingCharactersInRange:self.hashtagRange withString:hashtag];
            } else if (self.txtComment.text) {
                self.txtComment.text = [self.txtComment.text stringByAppendingString:hashtag];
            } else {
                self.txtComment.text = hashtag;
            }
        }
        
        [self applyFormattingForTextView:self.txtComment];
        self.tblTags.hidden = YES;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    actionSheet.delegate = nil;
    if (actionSheet.tag == 1) {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        } else if (buttonIndex == actionSheet.destructiveButtonIndex) {
            self.alertView.delegate = nil;
            self.alertView = [[UIAlertView alloc] initWithTitle:@"Delete Comment"
                                                        message:@"Are you sure? This action cannot be undone."
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
            self.alertView.tag = 2;
            [self.alertView show];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	
	switch (alertView.tag) {
        case 0: // Video unplayable
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case 1: // Push permission
            if (buttonIndex == alertView.cancelButtonIndex) return;
            [AppDelegate registerForPushNotifications];
            break;
        case 2: // Delete comment
            if (buttonIndex == alertView.cancelButtonIndex) return;
            [self deleteComment:self.selectedComment];
            self.selectedComment = nil;
            break;
        default:
            break;
	}
}

#pragma mark - Direct Send

- (void)presentDirectSend
{
    ORDirectSendView *vc = [[ORDirectSendView alloc] initWithVideo:self.video];
    vc.willSendDirectly = YES;
    vc.parent = vc;
    vc.delegate = self;
    
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)contactSelectViewDidCancel:(ORDirectSendView *)contactSelect
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactSelectView:(ORDirectSendView *)contactSelect didSelectContact:(ORContact *)contact
{
    [self contactSelectView:contactSelect didSelectContacts:@[contact]];
}

- (void)contactSelectView:(ORDirectSendView *)contactSelect didSelectContacts:(NSArray *)contacts
{
    [contactSelect prepareDirectForContacts:contacts];
    [contactSelect sendDirect];
}

- (void)contactSelectView:(ORDirectSendView *)contactSelect didFinishSending:(BOOL)sent
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoModified:) name:@"ORVideoViewed" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoModified:) name:@"ORVideoModified" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoModified:) name:@"ORVideoLikedUnliked" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORVideoModified:) name:@"ORVideoRepostedUnreposted" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPausePlayerHARD:) name:@"ORPausePlayerHARD" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORPausePlayerSOFT:) name:@"ORPausePlayerSOFT" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORUnpausePlayer:) name:@"ORUnpausePlayer" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStatusBarTapped:) name:@"ORStatusBarTapped" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)handleORVideoModified:(NSNotification*)n
{
    [self.tableView reloadData];
}

- (void)handleORPausePlayerHARD:(NSNotification*)n
{
    if (!self.isWVVisible) return;
    
	[self.videoCell hardPause];
}

- (void)handleORPausePlayerSOFT:(NSNotification*)n
{
	if (!self.isWVVisible) return;
	
	[self.videoCell softPause];
}

- (void)handleORUnpausePlayer:(NSNotification*)n
{
    if (!self.isWVVisible) return;
    
	[self.videoCell unpause];
}

- (void)handleORStatusBarTapped:(NSNotification *)n
{
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:YES];
}

- (void)handleDidBecomeActive:(NSNotification*)n
{
    if (!self.isWVVisible) return;
    
	if (self.pausedOnEnterBackground) {
		self.pausedOnEnterBackground = NO;
		[self.videoCell unpause];
	}
    
    [self reloadCommentsAndScroll:NO];
}

- (void)handleWillResignActive:(NSNotification *)notification
{
    if (!self.isWVVisible) return;
    
//    self.pausedOnEnterBackground = YES;
//    [self.videoCell pause];
}

#pragma mark - Custom

- (void)presentVideoManager
{
	ORVideoManagerView *vc = [[ORVideoManagerView alloc] initWithVideo:self.video andPlaces:nil];
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)loadVideo
{
    __weak ORWatchView *weakSelf = self;
    [ApiEngine videoWithId:self.videoId completion:^(NSError *error, OREpicVideo *video) {
        if (error) NSLog(@"Error: %@", error);
        if (!weakSelf) return;
        
        if (!video) {
            weakSelf.alertView.delegate = nil;
            weakSelf.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                            message:@"This video is no longer available."
                                                           delegate:weakSelf
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            weakSelf.alertView.tag = 0;
            [weakSelf.alertView show];
        } else {
            [weakSelf.aiLoading stopAnimating];
            weakSelf.tableView.hidden = NO;
            weakSelf.video = video;
            
            if ([CurrentUser.userId isEqualToString:weakSelf.video.userId]) {
                UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:weakSelf action:@selector(presentVideoManager)];
                weakSelf.navigationItem.rightBarButtonItem = edit;
            }
            
            NSIndexSet *is = [NSIndexSet indexSetWithIndex:0];
            [weakSelf.tableView reloadSections:is withRowAnimation:UITableViewRowAnimationAutomatic];

            [weakSelf reloadCommentsAndScroll:weakSelf.shouldScrollToBottom];
            
            if (self.video.state == OREpicVideoStateExpired) {
                weakSelf.alertView.delegate = nil;
                weakSelf.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                            message:@"This video is expired."
                                                           delegate:weakSelf
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
                weakSelf.alertView.tag = 0;
                [weakSelf.alertView show];
                return;
            }

            if (weakSelf.shouldOpenManager && [CurrentUser.userId isEqualToString:weakSelf.video.userId]) {
                weakSelf.shouldOpenManager = NO;
                [weakSelf presentVideoManager];
            }
        }
    }];
}

- (void)reloadCommentsAndScroll:(BOOL)scroll
{
    __weak ORWatchView *weakSelf = self;
    if (!self.video.videoId) return;
    
    [ApiEngine commentsForVideo:self.video.videoId after:nil completion:^(NSError *error, NSArray *result) {
        if (error) {
            NSLog(@"Error: %@", error);
            return;
        }
        
        if (!weakSelf) return;

        weakSelf.comments = [NSMutableOrderedSet orderedSetWithArray:result];
        
        [weakSelf.tableView beginUpdates];
        NSIndexSet *is = [NSIndexSet indexSetWithIndex:1];
        [weakSelf.tableView reloadSections:is withRowAnimation:UITableViewRowAnimationAutomatic];
        [weakSelf.tableView endUpdates];
        
        if (scroll && weakSelf.comments.count > 0 && !UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [weakSelf.tableView reloadData];
            NSIndexPath *ip = [NSIndexPath indexPathForItem:weakSelf.comments.count - 1 inSection:1];
            [weakSelf.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

- (void)loadCommentWithId:(NSString *)commentId
{
    __weak ORWatchView *weakSelf = self;
    
    [ApiEngine comment:commentId forVideo:self.video.videoId completion:^(NSError *error, OREpicVideoComment *comment) {
        if (error) NSLog(@"Error: %@", error);
        if (!weakSelf) return;
        
        if (comment && weakSelf) {
            comment.created = [NSDate date];

            [weakSelf.tableView beginUpdates];

            OREpicVideoComment *typing = [weakSelf typingCommentWithUserId:comment.userId name:nil];
            [self removeUserIsTyping:typing];

            [weakSelf.comments addObject:comment];
            weakSelf.video.commentCount++;
            
            NSIndexPath *ip = [NSIndexPath indexPathForItem:weakSelf.comments.count - 1 inSection:1];
            [weakSelf.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationTop];
            [weakSelf.tableView reloadData];
            [weakSelf.tableView endUpdates];
            
            if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
                [weakSelf.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORVideoModified" object:weakSelf.video];
        }
    }];
}

- (void)handleCommentNotification:(NSDictionary *)notification
{
    NSString *commentId = notification[@"cid"];
    NSUInteger count = [notification[@"cc"] integerValue];
    
    if (commentId && count == self.video.commentCount + 1) {
        [self loadCommentWithId:commentId];
    } else {
        [self reloadCommentsAndScroll:YES];
    }
}

- (void)handleTypingNotification:(NSDictionary *)notification
{
    NSString *userId = notification[@"user_id"];
    NSString *userName = notification[@"name"];
    BOOL stopped = [notification[@"stop"] isEqualToString:@"stop"];

    // Don't show "is typing" to yourself
    if ([userId isEqualToString:CurrentUser.userId]) return;
    
    OREpicVideoComment *comment = [self typingCommentWithUserId:userId name:userName];
    
    if (stopped) {
        [self removeUserIsTyping:comment];
    } else {
        [self addUserIsTyping:comment];
    }
}

- (OREpicVideoComment *)typingCommentWithUserId:(NSString *)userId name:(NSString *)name
{
    OREpicVideoComment *comment = [OREpicVideoComment new];
    comment.commentId = [NSString stringWithFormat:@"%@_typing", userId];
    comment.videoId = self.video.videoId;
    comment.userId = userId;
    comment.comment = [NSString stringWithFormat:@"%@ is typing...", name];
    comment.isTyping = YES;
    
    return comment;
}

- (void)addUserIsTyping:(OREpicVideoComment *)comment
{
    NSUInteger idx = [self.comments indexOfObject:comment];
    
    if (idx == NSNotFound) {
        [self.comments addObject:comment];
 
        [self.tableView beginUpdates];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:self.comments.count - 1 inSection:1];
        [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView reloadData];
        [self.tableView endUpdates];

        if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

- (void)removeUserIsTyping:(OREpicVideoComment *)comment
{
    NSUInteger idx = [self.comments indexOfObject:comment];
    
    if (idx != NSNotFound) {
        [self.comments removeObjectAtIndex:idx];
        NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:1];
        [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)sendTypingNotification
{
    NSLog(@"Sending typing notification...");
    self.sentTypingNotification = YES;
    
    [ApiEngine notifyTypingOnVideo:self.video.videoId stopped:NO completion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
    }];
}

- (void)removeTypingNotification
{
    if (!self.sentTypingNotification) return;
    
    NSLog(@"Removing typing notification...");
    self.sentTypingNotification = NO;

    [ApiEngine notifyTypingOnVideo:self.video.videoId stopped:YES completion:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
    }];
}

#pragma mark - New Comment

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([self.txtComment.text isEqualToString:COMMENT_PLACEHOLDER]) {
        self.txtComment.text = @"";
        self.btnSend.enabled = NO;
    }
    
    self.txtComment.textColor = [UIColor blackColor];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (!self.txtComment.text || [self.txtComment.text isEqualToString:@""]) {
        self.txtComment.text = COMMENT_PLACEHOLDER;
        self.txtComment.textColor = [UIColor lightGrayColor];
        self.btnSend.enabled = NO;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [self updateTaggedUsersWithRange:range replacementText:text];
    
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if (ORIsEmpty(text)) range.location--;

    if ([self.txtComment.text isEqualToString:COMMENT_PLACEHOLDER]) {
        self.txtComment.text = @"";
        self.btnSend.enabled = NO;
        self.txtComment.textColor = [UIColor blackColor];
        return YES;
    }

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
    
    self.tblTags.hidden = YES;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    float height = [self.txtComment sizeThatFits:CGSizeMake(self.txtComment.frame.size.width, CGFLOAT_MAX)].height + 6.0f;
    height = MAX(height, 38.0f);
    
    CGRect cf = self.commentView.frame;
    cf.size.height = height;
    
    if (self.keyboardHeight > 0) {
        cf.origin.y = self.view.bounds.size.height - (cf.size.height + self.keyboardHeight) + RVC.bottomMargin;
    } else {
        cf.origin.y = self.view.bounds.size.height - cf.size.height;
    }
    
    CGRect tf = self.tblTags.frame;
    tf.size.height = cf.origin.y;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.commentView.frame = cf;
        self.tblTags.frame = tf;
        
        if (self.keyboardHeight > 0) {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, (cf.size.height + self.keyboardHeight) - RVC.bottomMargin, 0);
        } else {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, cf.size.height, 0);
        }
    }];
    
    self.btnSend.enabled = (self.txtComment.text && ![self.txtComment.text isEqualToString:@""] && ![self.txtComment.text isEqualToString:COMMENT_PLACEHOLDER]);
    
    // Don't send typing notification for anonymous
    if (CurrentUser.accountType == 3) return;
    
    if (!self.sentTypingNotification) {
        [self sendTypingNotification];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeTypingNotification) object:nil];
    [self performSelector:@selector(removeTypingNotification) withObject:nil afterDelay:5.0f];
    
    if (self.btnSend.enabled) {
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
                                                                                         attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:15.0f],
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
}

- (void)setTextViewOriginalSize
{
    CGRect cf = self.commentView.frame;
    cf.size.height = 43.0f;
    
    if (self.keyboardHeight > 0) {
        cf.origin.y = self.view.bounds.size.height - (cf.size.height + self.keyboardHeight) + RVC.bottomMargin;
    } else {
        cf.origin.y = self.view.bounds.size.height - cf.size.height;
    }
    
    CGRect tf = self.tblTags.frame;
    tf.size.height = cf.origin.y;
    
//	CGRect f = self.viewMessageFieldBorder.frame;
	
    [UIView animateWithDuration:0.2f animations:^{
        self.commentView.frame = cf;
        self.tblTags.frame = tf;
        
        if (self.keyboardHeight > 0) {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, (cf.size.height + self.keyboardHeight) - RVC.bottomMargin, 0);
        } else {
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, cf.size.height, 0);
        }
    }];
}

- (IBAction)btnSend_TouchUpInside:(id)sender
{
    if (ORIsEmpty(self.txtComment.text) || [self.txtComment.text isEqualToString:COMMENT_PLACEHOLDER]) return;
    
    if (CurrentUser.accountType == 3) {
        [self.view endEditing:YES];
        
        [RVC presentSignInWithMessage:@"Who's commenting on this video? Sign-in now!" completion:^(BOOL success) {
            if (success) {
                [self btnSend_TouchUpInside:sender];
            }
        }];
        
        return;
    }
    
    // Create the comment
    OREpicVideoComment *comment = [[OREpicVideoComment alloc] init];
    comment.commentId = [ORUtility newGuidString];
    comment.videoId = self.video.videoId;
    comment.userId = CurrentUser.userId;
    comment.comment = self.txtComment.text;
    comment.created = [NSDate date];
    comment.isPending = YES;
    comment.taggedUsers = (self.taggedUsers.count > 0) ? self.taggedUsers : nil;
    
    // Add the comment to the array
    [self.comments addObject:comment];
    self.video.commentCount++;
    
    // Update the Table View
    NSIndexPath *ip = [NSIndexPath indexPathForItem:self.comments.count - 1 inSection:1];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView reloadData];
    [self.tableView endUpdates];
    
    if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }

    // Clear the sending text
    self.btnSend.hidden = NO;
    self.btnSend.enabled = NO;
    self.txtComment.text = @"";
    self.tblTags.hidden = YES;
    [self setTextViewOriginalSize];
    self.sentTypingNotification = NO;
    
    [self sendComment:comment];
    
    if (!AppDelegate.pushNotificationsEnabled) {
        NSString *msg = nil;
        
        if ([self.video.userId isEqualToString:CurrentUser.userId]) {
            msg = [NSString stringWithFormat:@"Would you like to be notified when people reply to your message?"];
        } else {
            msg = [NSString stringWithFormat:@"Would you like to be notified when %@ replies to your message?", self.video.user.firstName];
        }
        
        self.alertView.delegate = nil;
        self.alertView = [[UIAlertView alloc] initWithTitle:APP_NAME
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        self.alertView.tag = 1;
        [self.alertView show];
    }
}

- (void)sendComment:(OREpicVideoComment *)newComment
{
    if (!newComment.isPending) {
        newComment.isPending = YES;
        newComment.isFailed = NO;
        
        NSUInteger idx = [self.comments indexOfObject:newComment];
        if (idx != NSNotFound) {
            NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:1];
            [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    __weak ORWatchView *weakSelf = self;
    
    [ApiEngine addVideoComment:newComment cb:^(NSError *error, OREpicVideoComment *comment) {
        if (error) NSLog(@"Error: %@", error);
        if (!weakSelf) return;
        
        newComment.isPending = NO;
        newComment.isFailed = (!comment);
        
        NSUInteger idx = [weakSelf.comments indexOfObject:newComment];
        if (idx != NSNotFound) {
            NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:1];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
}

- (void)deleteComment:(OREpicVideoComment *)comment
{
    NSUInteger idx = [self.comments indexOfObject:comment];
    if (idx != NSNotFound) {
        [self.comments removeObjectAtIndex:idx];
        
        NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:1];
        [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [ApiEngine removeVideoComment:comment cb:^(NSError *error, BOOL result) {
            if (error) NSLog(@"Error: %@", error);
        }];
    }
}

- (void)initCachedTags
{
    self.cachedTagsFilename = [[ORUtility cachesDirectory] stringByAppendingPathComponent:@"user_cache/hashtags.cache"];
    self.cachedTags = [NSKeyedUnarchiver unarchiveObjectWithFile:self.cachedTagsFilename];
    if (!self.cachedTags) self.cachedTags = [NSMutableOrderedSet orderedSetWithCapacity:1];
}

- (void)reloadTags
{
    NSMutableOrderedSet *tags = [NSMutableOrderedSet orderedSetWithCapacity:self.cachedTags.count];
    
    for (NSString *tag in self.cachedTags) {
        NSCharacterSet *notAllowedChars = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSString *fixed = [[tag componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
        if (!ORIsEmpty(fixed)) [tags addObject:[@"#" stringByAppendingString:fixed]];
    }
    
    self.allHashtags = tags;
    self.filteredHashtags = self.allHashtags;
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
        
        self.nameSearch = NO;
        [self.tblTags reloadData];
        self.tblTags.hidden = (self.filteredHashtags.count == 0);
    } else {
        self.tblTags.hidden = YES;
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
        [self.tblTags reloadData];
        self.tblTags.hidden = (self.filteredUsers.count == 0);
    } else {
        self.tblTags.hidden = YES;
    }
}

- (void)addTagToCache:(NSString *)tag
{
    if (!tag) return;
    
    if ([self.cachedTags containsObject:tag]) [self.cachedTags removeObject:tag];
    [self.cachedTags insertObject:tag atIndex:0];
    [NSKeyedArchiver archiveRootObject:self.cachedTags toFile:self.cachedTagsFilename];
}

#pragma mark - Keyboard

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)tapGesture:(UITapGestureRecognizer *)sender
{
    [self.view endEditing:YES];
    
    if (self.tapGesture) {
        [self.tableView removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
}

-(void)keyboardWillShow:(NSNotification*)notify
{
    if (!self.isWVVisible) return;
    
	NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.keyboardHeight = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    CGRect cf = self.commentView.frame;

    if (self.keyboardHeight > 0) {
        cf.origin.y = self.view.bounds.size.height - (cf.size.height + self.keyboardHeight) + RVC.bottomMargin;
    } else {
        cf.origin.y = self.view.bounds.size.height - cf.size.height;
    }
    
    CGRect tf = self.tblTags.frame;
    tf.size.height = cf.origin.y;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.commentView.frame = cf;
        self.tblTags.frame = tf;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, (cf.size.height + self.keyboardHeight) - RVC.bottomMargin, 0);
        
        if (!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            CGPoint bottomOffset = CGPointMake(0, self.tableView.contentSize.height + self.tableView.contentInset.bottom - self.tableView.frame.size.height);
            self.tableView.contentOffset = bottomOffset;
        }
    }];
    
    if (self.tapGesture) {
        [self.tableView removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.cancelsTouchesInView = NO;
    self.tapGesture.delegate = self;
    [self.tableView addGestureRecognizer:self.tapGesture];
}

-(void)keyboardWillHide:(NSNotification*)notify
{
    if (!self.isWVVisible) return;
    
	NSDictionary* keyboardInfo = [notify userInfo];
    NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
    self.keyboardHeight = 0;
    
    CGRect cf = self.commentView.frame;
    cf.origin.y = self.view.bounds.size.height - cf.size.height;
    
    CGRect tf = self.tblTags.frame;
    tf.size.height = cf.origin.y;
    
    [UIView animateWithDuration:[animationDuration doubleValue] animations:^{
        self.tblTags.hidden = YES;
        self.commentView.frame = cf;
        self.tblTags.frame = tf;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, cf.size.height, 0);
    }];
    
    if (self.tapGesture) {
        [self.tableView removeGestureRecognizer:self.tapGesture];
        self.tapGesture = nil;
    }
    
    [self removeTypingNotification];
}

@end
