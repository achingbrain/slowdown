//
//  SlowDownApplicationDelegate.m
//  SlowDown
//
//  Created by Alex P on 14/02/2010.
//  Copyright 2010 Correspondent Corp. Ltd. All rights reserved.
//

#import "SlowDownApplicationDelegate.h"
#import "ConvertFiles.h"

@interface SlowDownApplicationDelegate (Private)

- (void)checkDirectoriesAreNotTheSame;
- (void)reallyStart;

@end

@implementation SlowDownApplicationDelegate

@synthesize window;
@synthesize progressWatcher;
@synthesize statusWatcher;
@synthesize actionButton;
@synthesize cancelled;
@synthesize convertFiles;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)awakeFromNib
{
	self.actionButton.title = @"Start";
	self.actionButton.action = @selector(start:);
}

- (void)dealloc
{
	[progressWatcher release];
	[statusWatcher release];
	[actionButton release];
	[convertFiles release];
	
	[super dealloc];
}

- (NSString *)windowNibName
{
	return @"MyDocument";
}

- (IBAction)chooseInputDirectory:(id)sender
{
	NSOpenPanel *attachmentPanel = [NSOpenPanel openPanel];
	
	//to allow multiple selection
	[attachmentPanel setAllowsMultipleSelection:NO];
	[attachmentPanel setCanChooseFiles:NO];
	[attachmentPanel setCanChooseDirectories:YES];
	[attachmentPanel setCanCreateDirectories:YES];
	[attachmentPanel beginSheetForDirectory:nil 
									   file:nil 
							 modalForWindow:self.window
							  modalDelegate:self 
							 didEndSelector:@selector(choseInputDirectory:returnCode:contextInfo:)  
								contextInfo:NULL]; 
}

- (void)choseInputDirectory:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton) {
		inputDirectory.stringValue = [sheet filename];
	}
}

- (IBAction)chooseOutputDirectory:(id)sender
{
	NSOpenPanel *attachmentPanel = [NSOpenPanel openPanel];
	
	//to allow multiple selection
	[attachmentPanel setAllowsMultipleSelection:NO];
	[attachmentPanel setCanChooseFiles:NO];
	[attachmentPanel setCanChooseDirectories:YES];
	[attachmentPanel setCanCreateDirectories:YES];
	[attachmentPanel beginSheetForDirectory:nil 
									   file:nil 
							 modalForWindow:self.window
							  modalDelegate:self 
							 didEndSelector:@selector(choseOutputDirectory:returnCode:contextInfo:)  
								contextInfo:NULL]; 
}

- (void)choseOutputDirectory:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton) {
		outputDirectory.stringValue = [sheet filename];
	}
}

- (void)checkDirectoriesAreNotTheSame
{
	if(inputDirectory.stringValue != nil && outputDirectory.stringValue != nil && [inputDirectory.stringValue isEqualToString:outputDirectory.stringValue]) {
		NSBeep();
		
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"I'm feeling destructive"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Input and output folders are the same"];
		[alert setInformativeText:@"Input files will be overwritten!"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == NSAlertFirstButtonReturn) {
		[self reallyStart];
	}
}

- (IBAction)start:(id)sender
{
	[self checkDirectoriesAreNotTheSame];
	[self reallyStart];
}

- (void)reallyStart
{
	cancelled = NO;
	
	[progressWatcher resetProgress];
	[progressWatcher showProgress];
	
	[chooseInputDirectory setEnabled:NO];
	[chooseOutputDirectory setEnabled:NO];
	[inputDirectory setEnabled:NO];
	[outputDirectory setEnabled:NO];
	
	self.actionButton.title = @"Cancel";
	self.actionButton.action = @selector(cancel:);
	
	ConvertFiles *converter = [[ConvertFiles alloc] init];
	converter.inputDirectory = inputDirectory.stringValue;
	converter.outputDirectory = outputDirectory.stringValue;
	converter.transcodeFiles = [shouldConvertToIntermediateCodec state] == NSOnState;
	
	self.convertFiles = converter;
	[converter release];
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finished:) name:ConvertFiles_Finished object:self.convertFiles];
	
	//[self.convertFiles main];
	[NSThread detachNewThreadSelector:@selector(main) toTarget:self.convertFiles withObject:nil];
}

- (IBAction)cancel:(id)sender
{
	cancelled = YES;
	
	[self.convertFiles cancel];
	
	self.actionButton.title = @"Start";
	self.actionButton.action = @selector(start:);
	
	[chooseInputDirectory setEnabled:YES];
	[chooseOutputDirectory setEnabled:YES];
	[inputDirectory setEnabled:YES];
	[outputDirectory setEnabled:YES];
	
	[progressWatcher hideProgress];
	[statusWatcher hideStatus];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ConvertFiles_Finished object:self.convertFiles];
}

- (void)finished:(NSNotification *)notification
{
	[chooseInputDirectory setEnabled:YES];
	[chooseOutputDirectory setEnabled:YES];
	[inputDirectory setEnabled:YES];
	[outputDirectory setEnabled:YES];
	
	self.actionButton.title = @"Start";
	self.actionButton.action = @selector(start:);
	
	[progressWatcher hideProgress];
	[statusWatcher hideStatus];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:ConvertFiles_Finished object:self.convertFiles];
}

@end
