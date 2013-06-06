//
//  StatusWatcher.m
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import "StatusWatcher.h"

NSString * const StatusWatcher_UpdateStatus = @"StatusWatcher_UpdateStatus";
NSString * const StatusWatcher_Status = @"StatusWatcher_Status";

@implementation StatusWatcher

@synthesize statusField;

- (void)dealloc
{
	[statusField release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[self hideStatus];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatus:) name:StatusWatcher_UpdateStatus object:nil];
}

- (void)updateStatus:(NSNotification *)notification
{
	[self showStatus];
	
	NSDictionary *dictionary = [notification userInfo];
	
	NSString *status = [dictionary objectForKey:StatusWatcher_Status];
	statusField.stringValue = status;
}

- (void)showStatus
{
	[statusField setHidden:NO];
}

- (void)hideStatus
{
	[statusField setHidden:YES];
}

@end
