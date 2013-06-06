//
//  ProgressWatcher.m
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import "ProgressWatcher.h"

NSString * const ProgressWatcher_UpdateProgress = @"ProgressWatcher_UpdateProgress";
NSString * const ProgressWatcher_Progress = @"ProgressWatcher_Progress";

@implementation ProgressWatcher

@synthesize progressBar;

- (void)dealloc
{
	[progressBar release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[progressBar setHidden:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:ProgressWatcher_UpdateProgress object:nil];
}

- (void)updateProgress:(NSNotification *)notification
{
	NSDictionary *dictionary = [notification userInfo];
	
	NSNumber *progress = [dictionary objectForKey:ProgressWatcher_Progress];
	
	if([progress intValue] > 0 && [progress intValue] < 100) {
		[self showProgress];
		[progressBar setDoubleValue:[progress doubleValue]];
	} else {
		[self hideProgress];
	}
}

- (void)resetProgress
{
	[progressBar setDoubleValue:0.0];
}

- (void)showProgress
{
	[progressBar setHidden:NO];
	[progressBar startAnimation:nil];
}

- (void)hideProgress
{
	[progressBar setHidden:YES];
	[progressBar stopAnimation:nil];
}

@end
