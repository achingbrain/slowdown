//
//  StatusWatcher.h
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const StatusWatcher_UpdateStatus;
extern NSString * const StatusWatcher_Status;

@interface StatusWatcher : NSObject {
	IBOutlet NSTextField *statusField;
}

@property (nonatomic, retain) NSTextField *statusField;

- (void)showStatus;
- (void)hideStatus;

@end
