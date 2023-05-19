//
//  ORMapDateRangeSelectorView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/26/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORMapDateRangeSelectorView.h"

@interface ORMapDateRangeSelectorView ()

@property (strong, nonatomic) NSMutableArray *ranges;

@end

@implementation ORMapDateRangeSelectorView

static NSString *rangeCell = @"rangeCell";

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
    // Do any additional setup after loading the view from its nib.
	
	self.ranges = [NSMutableArray arrayWithCapacity:12];
	[self.ranges addObject:@"10 min"];
	[self.ranges addObject:@"30 min"];
	[self.ranges addObject:@"1 hour"];
	[self.ranges addObject:@"6 hours"];
	[self.ranges addObject:@"12 hours"];
	[self.ranges addObject:@"24 hours"];
	[self.ranges addObject:@"2 days"];
	[self.ranges addObject:@"1 week"];
	[self.ranges addObject:@"2 weeks"];
	[self.ranges addObject:@"1 month"];
	[self.ranges addObject:@"6 months"];
	[self.ranges addObject:@"1 year"];
//	[self.ranges addObject:@"Custom"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.ranges.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell	*cell = [tableView dequeueReusableCellWithIdentifier:rangeCell];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rangeCell];
    
	cell.textLabel.text = self.ranges[indexPath.row];
	cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	DLog(@"%@", self.ranges[indexPath.row]);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORMapDateRangeSelected" object:self.ranges[indexPath.row]];
}

@end
