//
//  ORThumbnailPickerHostView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 11/21/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORThumbnailPickerView.h"
#import "ORThumbnailCell.h"
#import "ORFaspPersistentEngine.h"
#import "OWSharedS3Client.h"
#import <QuartzCore/QuartzCore.h>

@interface ORThumbnailPickerView () <UIScrollViewDelegate>

@property (strong, nonatomic) OREpicVideo* video;
@property (nonatomic, assign) BOOL hasLocalFiles;

@end

@implementation ORThumbnailPickerView

- (void)dealloc
{
    self.cvThumbs.delegate = nil;
}

- (id)initWithVideo:(OREpicVideo*)video
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		_video = video;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Thumbnail";
	self.screenName = @"ThumbnailPicker";

	UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveAction:)];
	self.navigationItem.leftBarButtonItem = done;

    [self.cvThumbs registerClass:[ORThumbnailCell class] forCellWithReuseIdentifier:@"ORThumbnailCell"];

    NSString *basePath = [[ORUtility documentsDirectory] stringByAppendingPathComponent:self.video.videoId];
    self.hasLocalFiles = [[NSFileManager defaultManager] fileExistsAtPath:basePath];
    
    self.imgPrevious.hidden = (!self.hasLocalFiles || self.video.thumbnailIndex == 0);
    self.btnPrevious.hidden = self.imgPrevious.hidden;
    
    self.imgNext.hidden = (!self.hasLocalFiles || (self.video.thumbnailIndex >= (self.video.thumbnailCount - 1)));
    self.btnNext.hidden = self.imgNext.hidden;
    
    [self reloadThumbnails];
}

- (IBAction)btnNext_TouchUpInside:(id)sender
{
    if (self.hasLocalFiles && self.video.thumbnailCount > (self.video.thumbnailIndex + 1)) {
        NSIndexPath *ip = [NSIndexPath indexPathForItem:(self.video.thumbnailIndex + 1) inSection:0];
        if (ip) [self.cvThumbs scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (IBAction)btnPrevious_TouchUpInside:(id)sender
{
    if (self.hasLocalFiles && self.video.thumbnailIndex > 0) {
        NSIndexPath *ip = [NSIndexPath indexPathForItem:(self.video.thumbnailIndex - 1) inSection:0];
        if (ip) [self.cvThumbs scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (void)reloadThumbnails
{
	if (self.hasLocalFiles) [self loadTinyThumbs];
    [self.cvThumbs reloadData];
    
    if (self.hasLocalFiles && self.video.thumbnailIndex > 0 && self.video.thumbnailCount > self.video.thumbnailIndex) {
        NSIndexPath *ip = [NSIndexPath indexPathForItem:self.video.thumbnailIndex inSection:0];
        if (ip) [self.cvThumbs scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.frame.size;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.hasLocalFiles) {
        return self.video.thumbnailCount;
    } else {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ORThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ORThumbnailCell" forIndexPath:indexPath];
    
    NSString *name = nil;
    
    if (self.hasLocalFiles) {
        name = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, indexPath.row];
    } else {
        name = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, self.video.thumbnailIndex];
    }
    
    NSString *local = [[ORUtility documentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", self.video.videoId, name]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:local]) {
        UIImage *thumb = [UIImage imageWithContentsOfFile:local];
        cell.imageView.image = thumb;
    } else {
        if (self.video.thumbnailURL) {
            __weak ORThumbnailCell *weakCell = cell;
            NSURL *url = [NSURL URLWithString:self.video.thumbnailURL];
            
            [cell.aiLoading startAnimating];
            
            [[ORCachedEngine sharedInstance] imageAtURL:url size:collectionView.frame.size fill:YES maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
                [weakCell.aiLoading stopAnimating];
                if (image) weakCell.imageView.image = image;
            }];
        }
    }
    
    return cell;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) return;
    [self updateSelectedThumb];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateSelectedThumb];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateSelectedThumb];
}

- (void)updateSelectedThumb
{
    CGPoint point = CGPointMake(self.cvThumbs.contentOffset.x + 10.0f, self.cvThumbs.contentOffset.y + 10.0f);
    NSIndexPath *ip = [self.cvThumbs indexPathForItemAtPoint:point];
	
    self.selectedThumbnailName = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, ip.row];
    self.selectedThumbnailIndex = ip.row;
    
    self.imgPrevious.hidden = self.selectedThumbnailIndex == 0;
    self.btnPrevious.hidden = self.imgPrevious.hidden;
    
    self.imgNext.hidden = (self.selectedThumbnailIndex >= (self.video.thumbnailCount - 1));
    self.btnNext.hidden = self.imgNext.hidden;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORThumbnailSelected" object:nil];
}

- (void)loadTinyThumbs
{
    [self.viewTinyThumbs.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *basePath = [[ORUtility documentsDirectory] stringByAppendingPathComponent:self.video.videoId];
    NSString *name = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, 0];
    NSString *local = [basePath stringByAppendingPathComponent:name];
    
    UIImage *thumb0 = [UIImage imageWithContentsOfFile:local];

	if (!thumb0) return;
	
	CGFloat aspect = thumb0.size.width/thumb0.size.height;
	CGFloat shrunkH = self.viewTinyThumbs.frame.size.height;
	CGFloat shrunkW = shrunkH * aspect;

	int canFit = ceilf(self.viewTinyThumbs.frame.size.width / shrunkW);
	DLog(@"canFit: %d", canFit);
    
	CGFloat interval = (CGFloat)self.video.thumbnailCount / (CGFloat)canFit;

	for (int i = 0; i < canFit; i++) {
        int thumb = MIN(floorf((CGFloat)i * interval), self.video.thumbnailCount-1);
        name = [NSString stringWithFormat:VIDEO_THUMBNAIL_FORMAT, thumb];
        local = [basePath stringByAppendingPathComponent:name];

		UIImage *img = [UIImage imageWithContentsOfFile:local];
		UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(i * shrunkW, 0, shrunkW, shrunkH)];
		[b addTarget:self action:@selector(tinyThumbTapped:) forControlEvents:UIControlEventTouchUpInside];
		b.tag = thumb;
		[b setImage:img forState:UIControlStateNormal];
		[self.viewTinyThumbs addSubview:b];
	}
}

- (void)tinyThumbTapped:(UIButton*)sender
{
	[self.cvThumbs scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:YES];
}

- (UIImage*)selectedThumbnailImage
{
    CGPoint point = CGPointMake(self.cvThumbs.contentOffset.x + 10.0f, self.cvThumbs.contentOffset.y + 10.0f);
    NSIndexPath *ip = [self.cvThumbs indexPathForItemAtPoint:point];
	ORThumbnailCell *cell = (ORThumbnailCell*)[self.cvThumbs cellForItemAtIndexPath:ip];
	return cell.imageView.image;
}

@end
