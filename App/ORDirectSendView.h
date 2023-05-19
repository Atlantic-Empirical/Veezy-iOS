//
//  ORContactSelectView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 13/06/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORContactSelectViewDelegate;

@interface ORDirectSendView : GAITrackedViewController

- (id)initWithVideo:(OREpicVideo *)video andSelectedContacts:(NSArray *)selectedContacts;
- (id)initWithVideo:(OREpicVideo *)video;

@property (nonatomic, weak) id<ORContactSelectViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *viewContactPickerParent;
@property (weak, nonatomic) IBOutlet UIView *viewContactPicker;
@property (weak, nonatomic) IBOutlet UIButton *btnAddressBook;
@property (weak, nonatomic) IBOutlet UIButton *btnGmail;
@property (weak, nonatomic) IBOutlet UIImageView *imgThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *lblAutotitle;
@property (weak, nonatomic) IBOutlet UILabel *lblDuration;
@property (weak, nonatomic) IBOutlet UIView *viewLoading;
@property (weak, nonatomic) IBOutlet UIView *viewLoadingInner;
@property (weak, nonatomic) IBOutlet UIView *viewConnect;
@property (weak, nonatomic) IBOutlet UILabel *lblLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@property (nonatomic, weak) UIViewController *parent;
@property (nonatomic, assign) BOOL willSendDirectly;
@property (nonatomic, assign) BOOL focusOnDisplay;

- (IBAction)btnAddressBook_TouchUpInside:(id)sender;
- (IBAction)btnGmail_TouchUpInside:(id)sender;
- (IBAction)btnCancel_TouchUpInside:(id)sender;

- (void)prepareDirectForContacts:(NSArray *)contacts;
- (void)sendDirect;

@end

@protocol ORContactSelectViewDelegate <NSObject>

- (void)contactSelectViewDidCancel:(ORDirectSendView *)contactSelect;
- (void)contactSelectView:(ORDirectSendView *)contactSelect didSelectContact:(ORContact *)contact;
- (void)contactSelectView:(ORDirectSendView *)contactSelect didSelectContacts:(NSArray *)contacts;
- (void)contactSelectView:(ORDirectSendView *)contactSelect didFinishSending:(BOOL)sent;

@end