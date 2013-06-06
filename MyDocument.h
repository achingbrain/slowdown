//
//  MyDocument.h
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProgressWatcher.h"
#import "StatusWatcher.h"
@class ConvertFiles;

@interface MyDocument : NSDocument {
	IBOutlet ProgressWatcher *progressWatcher;
	IBOutlet StatusWatcher *statusWatcher;
	IBOutlet NSButton *actionButton;
	IBOutlet NSTextField *inputDirectory;
	IBOutlet NSTextField *outputDirectory;
	IBOutlet NSButton *chooseInputDirectory;
	IBOutlet NSButton *chooseOutputDirectory;
	
	BOOL cancelled;
	ConvertFiles *convertFiles;
}

@property (nonatomic, retain) ProgressWatcher *progressWatcher;
@property (nonatomic, retain) StatusWatcher *statusWatcher;
@property (nonatomic, retain) NSButton *actionButton;
@property (readonly) BOOL cancelled;
@property (readwrite, retain) ConvertFiles *convertFiles;

- (IBAction)chooseInputDirectory:(id)sender;
- (IBAction)chooseOutputDirectory:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)finished:(NSNotification *)notification;

@end
