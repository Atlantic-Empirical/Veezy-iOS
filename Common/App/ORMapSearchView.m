//
//  ORMapSearchView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/25/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORMapSearchView.h"
#import "ORGooglePlacesAutoCompleteResult.h"
#import "ORGooglePlacesAutoCompleteItem.h"
#import "ORGooglePlaceDetails.h"

@interface ORMapSearchView () <UITableViewDataSource, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) NSArray *places;

@end

@implementation ORMapSearchView

static NSString *placeCell = @"placeCell";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.screenName = @"MapSearch";
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (IBAction)btnDone_TouchUpInside:(id)sender {
	[self close];
}

- (IBAction)view_TouchUpInside:(id)sender {
	[self close];
}

#pragma mark - Custom

- (void)close
{
	[self cleanUp];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORFinishedPlaceSearch" object:nil];
}

- (void)cleanUp
{
	self.btnDone.hidden = YES;
	self.txtSearch.text = @"";
	self.places = nil;
	[self.tableView reloadData];
	[self.view endEditing:YES];
}

- (void)performSearch
{
	if (!GoogleEngine)
		GoogleEngine = [[ORGoogleEngine alloc] initWithDelegate:nil];

	[GoogleEngine placesAutoComplete:self.txtSearch.text completion:^(NSError *error, ORGooglePlacesAutoCompleteResult *result) {
		if (error) {
			//
		} else {
			self.places = result.predictions;
			[self.tableView reloadData];
//			[self.view endEditing:YES];
		}
	}];
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.places.count == 0) {
		self.tableView.hidden = YES;
		return 0;
	} else {
		self.tableView.hidden = NO;
		return self.places.count + 1;
	}
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell	*cell = [tableView dequeueReusableCellWithIdentifier:placeCell];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:placeCell];
    
	if (indexPath.row == self.places.count) {
		cell.textLabel.text = @"";

		UIImageView *imv = [[UIImageView alloc]initWithFrame:CGRectMake(14, (cell.contentView.frame.size.height-16)/2, 104, 16)];
		imv.image = [UIImage imageNamed:@"powered-by-google-on-white-78x12"];
		[cell.contentView addSubview:imv];
	} else {
		for (UIView *v in cell.contentView.subviews)
			if ([v isKindOfClass:[UIImageView class]])
				[v removeFromSuperview];
		
		ORGooglePlacesAutoCompleteItem *place = self.places[indexPath.row];
		cell.textLabel.text = place.descriptionText;
		cell.textLabel.textColor = APP_COLOR_PRIMARY;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
	if (indexPath.row == self.places.count) {
		//nada
	} else {
		ORGooglePlacesAutoCompleteItem *place = self.places[indexPath.row];

		if (!GoogleEngine)
			GoogleEngine = [[ORGoogleEngine alloc] initWithDelegate:nil];

		[GoogleEngine getPlaceDetailsWithReference:place.reference completion:^(NSError *error, ORGooglePlaceDetails *details) {
			if (error) {
				//
			} else {
				[self cleanUp];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"ORGooglePlaceSelected" object:details];
			}
		}];
	}
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.btnDone.hidden = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartedPlaceSearch" object:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	[self performSearch];
	return YES;
}

@end
