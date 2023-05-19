//
//  MBContactModel.h
//  MBContactPicker
//
//  Created by Matt Bowman on 12/13/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MBContactPickerModelProtocol <NSObject>

@required

@property (readonly, nonatomic, copy) NSString *contactTitle;
@property (readonly, nonatomic, copy) NSString *contactSubtitle;
@property (readonly, nonatomic, copy) NSString *contactImageURL;
@property (readonly, nonatomic) UIImage *contactImage;
@property (readonly, nonatomic) BOOL manuallyAdded;

@end

@interface MBContactModel : NSObject <MBContactPickerModelProtocol>

@property (nonatomic, copy) NSString *contactTitle;
@property (nonatomic, copy) NSString *contactSubtitle;
@property (nonatomic, copy) NSString *contactImageURL;
@property (nonatomic) UIImage *contactImage;
@property (nonatomic) BOOL manuallyAdded;

@end
