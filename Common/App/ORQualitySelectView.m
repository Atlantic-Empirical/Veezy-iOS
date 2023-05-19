//
//  ORQualitySelectView.m
//  Veezy
//
//  Created by Rodrigo Sieiro on 20/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORQualitySelectView.h"

@interface ORQualitySelectView ()

@end

@implementation ORQualitySelectView

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	
	cell.textLabel.textColor = [UIColor blackColor];
	cell.detailTextLabel.textColor = [UIColor darkGrayColor];

    switch (indexPath.row) {
        case 1:
            cell.textLabel.text = @"Medium";
			cell.detailTextLabel.text = @"Size: 640x360 Bitrate: 500Kbps";
            break;
        case 2:
            cell.textLabel.text = @"Low";
			cell.detailTextLabel.text = @"Size: 320x180 Bitrate: 250Kbps";
            break;
        default:
            cell.textLabel.text = @"High";
			cell.detailTextLabel.text = @"Size: 960x540 Bitrate: 1000Kbps";
            break;
    }
    
    cell.accessoryType = (indexPath.row == CurrentUser.settings.videoQuality) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    CurrentUser.settings.videoQuality = indexPath.row;
    [CurrentUser saveLocalUser];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSettingsUpdated" object:nil];
    
    [ApiEngine saveUserSettings:CurrentUser.settings cb:^(NSError *error, BOOL result) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"User settings saved.");
        }
    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
