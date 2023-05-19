//
//  ORWatchView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 23/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORWatchView : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIView *commentView;
@property (nonatomic, weak) IBOutlet UITextView *txtComment;
@property (nonatomic, weak) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UIView *viewMessageFieldBorder;
@property (nonatomic, weak) IBOutlet UITableView *tblTags;

- (IBAction)btnSend_TouchUpInside:(id)sender;

@property (nonatomic, assign) BOOL shouldAutoplay;
@property (nonatomic, assign) BOOL shouldScrollToBottom;
@property (nonatomic, assign) BOOL shouldOpenManager;
@property (nonatomic, strong) OREpicVideo *video;

- (id)initWithVideo:(OREpicVideo *)video;
- (id)initWithVideoId:(NSString *)videoId;
- (void)sendComment:(OREpicVideoComment *)newComment;
- (void)deleteComment:(OREpicVideoComment *)comment;
- (void)handleCommentNotification:(NSDictionary *)notification;
- (void)handleTypingNotification:(NSDictionary *)notification;
- (void)configureForOrientation:(UIInterfaceOrientation)orientation;
- (void)close;
- (void)presentDirectSend;

@end
