//
//  ProgressWatcher.h
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const ProgressWatcher_UpdateProgress;
extern NSString * const ProgressWatcher_Progress;

@interface ProgressWatcher : NSObject {
	IBOutlet NSProgressIndicator *progressBar;
}

@property (nonatomic, retain) NSProgressIndicator *progressBar;

- (void)showProgress;
- (void)hideProgress;
- (void)resetProgress;

@end
