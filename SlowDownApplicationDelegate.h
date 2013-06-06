//
//  SlowDownApplicationDelegate.h
//  SlowDown
//
//  Created by Alex P on 14/02/2010.
//  Copyright 2010 Correspondent Corp. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProgressWatcher.h"
#import "StatusWatcher.h"
@class ConvertFiles;

@interface SlowDownApplicationDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet NSWindow *window;
	IBOutlet ProgressWatcher *progressWatcher;
	IBOutlet StatusWatcher *statusWatcher;
	IBOutlet NSButton *actionButton;
	IBOutlet NSTextField *inputDirectory;
	IBOutlet NSTextField *outputDirectory;
	IBOutlet NSButton *chooseInputDirectory;
	IBOutlet NSButton *chooseOutputDirectory;
	IBOutlet NSButton *shouldConvertToIntermediateCodec;
	
	BOOL cancelled;
	ConvertFiles *convertFiles;
}

@property (assign) NSWindow *window;
@property (nonatomic, retain) ProgressWatcher *progressWatcher;
@property (nonatomic, retain) StatusWatcher *statusWatcher;
@property (nonatomic, retain) NSButton *actionButton;
@property (readonly) BOOL cancelled;
@property (readwrite, retain) ConvertFiles *convertFiles;

- (IBAction)chooseInputDirectory:(id)sender;
- (IBAction)chooseOutputDirectory:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)cancel:(id)sender;


@end
