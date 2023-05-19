//
//  ORSecretSettingsView.m
//  Veezy
//
//  Created by Rodrigo Sieiro on 13/11/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <AsperaMobile/AsperaMobile.h>
#import "ORSecretSettingsView.h"

@interface ORSecretSettingsView ()

@end

@implementation ORSecretSettingsView

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Internal";
}

- (void)btnFaspLogs_TouchUpInside:(id)sender
{
    [ASLogMailer sendLogsWithSubject:[NSString stringWithFormat:@"FASP Logs - %@", [NSDate date]]
                        toRecipients:@"support@cloudcam.co"
                 usingViewController:self];
}

@end
