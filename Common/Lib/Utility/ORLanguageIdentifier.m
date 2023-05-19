//
//  ORLanguageIdentifier.m
//  OroosoLib
//
//  Created by Thomas Purnell-Fisher on 4/4/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORLanguageIdentifier.h"


@interface ORLanguageIdentifier()

@property (strong, nonatomic) NSArray *tagschemes;
@property (strong, nonatomic) NSLinguisticTagger *tagger;

@end

@implementation ORLanguageIdentifier

- (ORLanguageIdentifier*)init{
	self = [super init];
	self.tagschemes = [NSArray arrayWithObjects:NSLinguisticTagSchemeLanguage, nil];
	self.tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:self.tagschemes options:0];
	return self;
}

- (NSString*)languageOfString:(NSString*)textToAnalize
{
    if (!textToAnalize) return nil;
	[self.tagger setString:textToAnalize];
	return [self.tagger tagAtIndex:0 scheme:NSLinguisticTagSchemeLanguage tokenRange:NULL sentenceRange:NULL];
}

@end
