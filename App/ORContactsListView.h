//
//  ORFindFriendsView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 31/01/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ORFindFriendsTwitter,
    ORFindFriendsFacebook,
    ORFindFriendsGoogle,
    ORFindFriendsAddressBook
} ORFindFriendsType;

@interface ORContactsListView : GAITrackedViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tblResults;

- (id)initWithType:(ORFindFriendsType)type contacts:(NSMutableOrderedSet *)contacts;

@end
