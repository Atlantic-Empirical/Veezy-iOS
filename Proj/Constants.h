//
//  Constants.h
//  Epic
//
//  Created by Rodrigo Sieiro on 29/10/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#pragma once

// App Delegate Constants
#define APP_NAME_FOR_CAPTION @"VeezyApp" // Can be a Twitter handle
#define APP_NAME @"Veezy"
#define APP_CODE @"V"
#define APP_URL_SCHEME @"veezy"
#define GA_TRACKING_ID @"UA-37199973-7"
#define GA_CONVERSION_ID @"985924671"
#define GA_CONVERSION_LABEL @"XHK3CNnshhAQv4iQ1gM"
#define CRASHLYTICS_KEY @"5a11c8640615cf918918506da693d71a374cc45b"
#define MIXPANEL_TOKEN @"bdab0a0d2e30ae1f2e703e121bb6489b"
#define GOOGLE_MAPS_KEY @"AIzaSyAv_Khqib06Ih_JNN9tVO8e2jQKpnPW2eE"
#define TWITTER_KEY @"iNfEZwDMHTFFPmTAY5au16N5u"
#define TWITTER_SECRET @"mYkCJeKPaMi3zc30503wu3KQnFXFsC75VE2XfzS6519KElfE4F"
#define PUSH_ENABLED YES
#define CAPTURE_ENABLED YES
#define IAP_1MO @"1mo"
#define IAP_1YR @"1yr"
#define TWITTER_MAX_CHARS 116

// API ENDPOINT

// Local Dev
#define LOCAL_ENDPOINT @"devapi.orooso.com"
#define LOCAL_PORT 2511
#define LOCAL_USE_SSL NO

// Test
#define TEST_ENDPOINT @"testapi.orooso.com"
#define TEST_PORT 80
#define TEST_USE_SSL YES

// Production
#define PROD_ENDPOINT @"api.orooso.com"
#define PROD_PORT 80
#define PROD_USE_SSL YES

// SERVICE
#define SERVICE_URL @"http://www.veezy.co"
#define PLAYER_URL SERVICE_URL@"/p"
#define APP_DOMAIN @"veezy.co"

// KEYCHAIN
#define KEYCHAIN_SERVICE @"CloudcamAccount"
#define KEYCHAIN_GROUP @"V9QA6L6849.cloudcam"

// GLOBAL VARS
#define AppDelegate ((ORAppDelegate *)[UIApplication sharedApplication].delegate)
#define RVC AppDelegate.viewController
#define CurrentUser AppDelegate.currentUser
#define ApiEngine AppDelegate.apiEngine
#define GoogleEngine AppDelegate.ge
#define isOnline AppDelegate.hasInternetConnection

// COLORS
#define APP_COLOR_PRIMARY_ALPHA(_alpha_) [UIColor colorWithRed:255.0f/255.0f green:211.0f/255.0f blue:28.0f/255.0f alpha:_alpha_]
//#define APP_COLOR_PRIMARY_ALPHA(_alpha_) [UIColor colorWithRed:238.0f/255.0f green:52.0f/255.0f blue:36.0f/255.0f alpha:_alpha_] // Netflix Red
//#define APP_COLOR_PRIMARY_ALPHA(_alpha_) [UIColor colorWithRed:46.0f/255.0f green:90.0f/255.0f blue:170.0f/255.0f alpha:_alpha_] // Dodger Blue

#define APP_COLOR_PRIMARY APP_COLOR_PRIMARY_ALPHA(1.0f)

//#define APP_COLOR_PRIMARY [UIColor colorWithRed:30.0f/255.0f green:144.0f/255.0f blue:1 alpha:1]
#define APP_COLOR_SECONDARY [UIColor colorWithRed:46.0f/255.0f green:90.0f/255.0f blue:170.0f/255.0f alpha:1.0f]

#define APP_COLOR_LIGHT_GREY [UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f]
#define APP_COLOR_LIGHTER_GREY [UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:247.0f/255.0f alpha:1.0f]
#define APP_COLOR_DARK_GREY [UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:204.0f/255.0f alpha:1.0f]

#define APP_COLOR_LIGHT_PURPLE [UIColor colorWithRed:170.0f/255.0f green:165.0f/255.0f blue:250.0f/255.0f alpha:1.0f]
#define APP_COLOR_PURPLE [UIColor colorWithRed:130.0f/255.0f green:146.0f/255.0f blue:200.0f/255.0f alpha:1.0f]

#define APP_COLOR_LIGHT_GREEN [UIColor colorWithRed:240.0f/255.0f green:1.0f blue:240.0f/255.0f alpha:1.0f]
#define APP_COLOR_LIGHTER_GREEN [UIColor colorWithRed:247.0f/255.0f green:1.0f blue:247.0f/255.0f alpha:1.0f]

#define APP_COLOR_LIGHT_RED [UIColor colorWithRed:1.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f]

#define APP_COLOR_FACEBOOK [UIColor colorWithRed:59.0f/255.0f green:90.0f/255.0f blue:154.0f/255.0f alpha:1.0f]
#define APP_COLOR_TWITTER [UIColor colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f]

// VIDEO
#define DEFAULT_VIDEO_WIDTH_HIG 960
#define DEFAULT_VIDEO_WIDTH_MED 640
#define DEFAULT_VIDEO_WIDTH_LOW 320
#define DEFAULT_VIDEO_HEIGHT_HIG 540
#define DEFAULT_VIDEO_HEIGHT_MED 360
#define DEFAULT_VIDEO_HEIGHT_LOW 180
#define DEFAULT_MAX_VIDEO_BITRATE_HIG 1000000
#define DEFAULT_MAX_VIDEO_BITRATE_MED 500000
#define DEFAULT_MAX_VIDEO_BITRATE_LOW 250000
#define DEFAULT_MIN_VIDEO_BITRATE 100000
#define DEFAULT_AUDIO_BITRATE 64000
#define DEFAULT_KEYFRAME_INTERVAL 200
#define SEGMENT_DURATION 3
#define VIDEO_HQ_PREFIX @"hq"
#define VIDEO_PLAYLIST_FILE @"playlist.m3u8"
#define VIDEO_THUMBNAIL_FORMAT @"thumb-%d.jpg"
#define VIDEO_THUMBNAIL_FILE @"thumb.jpg"
#define DEFAULT_THUMB_WIDTH 640.0f
#define DEFAULT_THUMB_HEIGHT 360.0f
#define THUMBNAIL_INTERVAL 1
#define THUMBNAIL_INDEX 3
#define THUMBNAIL_QUALITY 0.5f //compressionQuality: The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality).
#define FK @"DDjGiLEVHFEgDP2jHnRmJhVJkv0lF5jVcjn39aMJXsE"

// iOS Version
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// iOS MISSING SHIT
#define ISIPAD  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define ORStringFromBOOL(aBOOL)    aBOOL? @"YES" : @"NO"

// LOCATION & PLACES
#define PLACE_SEARCH_RADIUS 100

// Cached Engine
#define FEED_LIMIT 20
#define CACHE_MAX_AGE_MIN 1440

// Ads
#define ADS_ARE_ON 0

// Pairing messages
#define PAIRING_MESSAGE_TW_UNABLE_TO_USE_SELECTED_ACCOUNT @"Unable to use the selected Twitter account. You may have changed your Twitter password. Leave Veezy, go to iOS Settings > Twitter and tap on your Twitter account."
#define PAIRING_MESSAGE_FB_UNABLE_TO_USE_SELECTED_ACCOUNT @"Unable to use the selected Facebook account. You may have changed your Facebook password. Leave Veezy, go to iOS Settings > Facebook and tap on your Facebook account."
#define PAIRING_MESSAGE_GO_UNABLE_TO_USE_SELECTED_ACCOUNT @"Unable to use the selected Google account. You may have changed your Google password. Please try again."

#define PAIRING_MESSAGE_TWACCOUNT_PAIRED_TO_OTHER_CCACCOUNT @"This Twitter account is already connected with another Veezy account. You'll need to disconnect it from the other account or delete the other account before you're able to pair it with this Veezy account."
#define PAIRING_MESSAGE_FBACCOUNT_PAIRED_TO_OTHER_CCACCOUNT @"This Facebook account is already connected with another Veezy account. You'll need to disconnect it from the other account or delete the other account before you're able to pair it with this Veezy account."
#define PAIRING_MESSAGE_GOACCOUNT_PAIRED_TO_OTHER_CCACCOUNT @"This Google account is already connected with another Veezy account. You'll need to disconnect it from the other account or delete the other account before you're able to pair it with this Veezy account."

// Permission Strings

#define PERMISSION_MICROPHONE @"Videos need sound! and Veezy needs your permission to access the microphone otherwise it won't work."
#define PERMISSION_MICROPHONE_SOFT_DENIED @"You won't be able to shoot videos! Are you sure you want to deny access?"
#define PERMISSION_MICROPHONE_OS_DENIED @"You've denied access to the microphone! Now Veezy's camera will not work. If this was a mistake go to the iOS Settings App > Privacy > Microphone and grant permission to Veezy."

#define PERMISSION_LOCATION @"Veezy helps you tag your videos with place names like \"The Grand Canyon\" or \"The Eiffel Tower\". Cool?"
#define PERMISSION_LOCATION_OS_DENIED @"You've denied access to your location. If this was a mistake go to the iOS Settings App > Privacy > Location and grant permission to Veezy."

#define PERMISSION_AB @"Find your friends and send videos directly to them by connecting your address book."
#define PERMISSION_AB_OS_DENIED @"You've denied access to your contacts. If this was a mistake go to the iOS Settings App > Privacy > Contacts and grant permission to Veezy."
