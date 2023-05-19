//
//  ORThumbnailPickerView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 11/21/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORThumbnailPickerView : GAITrackedViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

- (id)initWithVideo:(OREpicVideo*)video;

@property (weak, nonatomic) IBOutlet UICollectionView *cvThumbs;
@property (weak, nonatomic) IBOutlet UIView *viewTinyThumbs;
@property (strong, nonatomic) NSString *selectedThumbnailName;
@property (assign, nonatomic) NSUInteger selectedThumbnailIndex;
@property (assign, nonatomic, readonly) UIImage *selectedThumbnailImage;
@property (weak, nonatomic) IBOutlet UIImageView *imgPrevious;
@property (weak, nonatomic) IBOutlet UIButton *btnPrevious;
@property (weak, nonatomic) IBOutlet UIImageView *imgNext;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;

- (IBAction)btnNext_TouchUpInside:(id)sender;
- (IBAction)btnPrevious_TouchUpInside:(id)sender;

- (void)reloadThumbnails;
- (void)loadTinyThumbs;

@end
