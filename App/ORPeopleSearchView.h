//
//  OREpicSearch.h
//  Epic
//
//  Created by Thomas Purnell-Fisher on 10/29/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORPeopleSearchView : GAITrackedViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *txtSearch;
@property (weak, nonatomic) IBOutlet UITableView *tblResults;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiSearch;
@property (weak, nonatomic) IBOutlet UIView *viewLoading;
@property (weak, nonatomic) IBOutlet UIView *viewLoadingInner;
@property (weak, nonatomic) IBOutlet UILabel *lblLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnInviteFriends;

- (IBAction)btnCancel_TouchUpInside:(id)sender;
- (IBAction)btnInviteFriends_TouchUpInside:(id)sender;

@end
