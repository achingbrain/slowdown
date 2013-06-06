//
//  ConvertFiles.m
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import "ConvertFiles.h"
#import <QTKit/QTKit.h>
#import "ProgressWatcher.h"
#import "StatusWatcher.h"
#import "ConvertFile.h"
#import "TranscodeFile.h"

NSString * const ConvertFiles_Finished = @"ConvertFiles_Finished";

// used for preferences
NSString * const SlowDown_inputDirectory = @"SlowDown_inputDirectory";
NSString * const SlowDown_outputDirectory = @"SlowDown_outputDirectory";

@interface ConvertFiles (Private)

- (void)parseDirectory:(NSString *)directoryPath outputPath:(NSString *)outputPath;
- (void)progress:(NSNotification *)notification;
- (void)postProgress:(NSUInteger)progress total:(NSUInteger)total;
- (float)findFPS:(QTMovie *)movie;

@end

@implementation ConvertFiles

@synthesize inputDirectory;
@synthesize outputDirectory;
@synthesize transcodeFiles;
@synthesize operationQueue;

- (id)init
{
	if(self = [super init]) {
		NSLog(@"Convert files initted");
		
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];
		queue.maxConcurrentOperationCount = 4;
		
		self.operationQueue = queue;
		
		[queue release];
		
		cancelled = NO;
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[inputDirectory release];
	[outputDirectory release];
	[operationQueue release];
	[jobs release];
	
	[super dealloc];
}

- (void)main
{
	NSLog(@"converting files");
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// update preferences with chosen directories
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	[defaults setObject:inputDirectory forKey:SlowDown_inputDirectory];
	[defaults setObject:outputDirectory forKey:SlowDown_outputDirectory];
	
	// init our stuff
	totalJobs = 0;
	jobs = [[NSMutableArray alloc] init];
	
	// start processing
	[self parseDirectory:inputDirectory outputPath:outputDirectory];
	
	if(cancelled || [jobs count] == 0) {
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ConvertFiles_Finished object:self]];
	} else {
		[self postProgress:0 total:[jobs count]];
		
		NSLog(@"starting jobs");
		
		for(ConvertFile *convertFile in jobs) {
			[operationQueue addOperation:convertFile];
		}
	}
	
	[pool release];
}

- (void)parseDirectory:(NSString *)directoryPath outputPath:(NSString *)outputPath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSLog(@"looking at %@", directoryPath);
	
	NSArray *contents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
	
	for(NSUInteger i = 0; i < [contents count]; i++) {
		if(cancelled) {
			break;
		}
		
		NSString *input = [contents objectAtIndex:i];
		NSString *output = [NSString stringWithFormat:@"%@/%@", outputPath, [input lastPathComponent]];
		
		BOOL isDirectory;
		
		NSString *filePath = [NSString stringWithFormat:@"%@/%@", directoryPath, input];
		
		NSLog(@"looking at file %@", filePath);
		
		if([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
			if(isDirectory) {
				NSLog(@"is directory %@", filePath);
				
				// make output directory
				[fileManager createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:nil];
				
				// parse files in directory
				[self parseDirectory:filePath outputPath:output];
			} else if([QTMovie canInitWithFile:filePath]) {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@", input] forKey:StatusWatcher_Status];
				
				[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:StatusWatcher_UpdateStatus object:self userInfo:userInfo]];
				
				NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
				
				NSError *error;
				QTMovie *movie = [QTMovie movieWithFile:filePath error:&error];
				
				if(error) {
					NSLog(@"Error: %@", error);
					[pool release];
					continue;
				}
				
				float fps = [self findFPS:movie];
				
				[pool release];
				
				ConvertFile *convertFile = nil;
				
				if(fps < 30) {
					NSLog(@"skipping %@ as fps is %0.2f", input, fps);
					
					convertFile = [[TranscodeFile alloc] init];
					convertFile.inputPath = filePath;
					convertFile.outputPath = output;
					convertFile.transcodeFile = self.transcodeFiles;
				} else {
					NSLog(@"adding to queue: %@", input);
					
					convertFile = [[ConvertFile alloc] init];
					convertFile.inputPath = filePath;
					convertFile.outputPath = output;
					convertFile.transcodeFile = self.transcodeFiles;
				}
				
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(done:) 
															 name:ConvertFile_Done 
														   object:convertFile];
				
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(error:) 
															 name:ConvertFile_Error 
														   object:convertFile];
				
				[[NSNotificationCenter defaultCenter] addObserver:self 
														 selector:@selector(progress:) 
															 name:ConvertFile_Progress 
														   object:convertFile];
				
				totalJobs++;
				[jobs addObject:convertFile];
				
				[convertFile release];
			} else {
				NSLog(@"could not make movie from %@", filePath);
			}
		} else {
			NSLog(@"file %@ does not exist", filePath);
		}
	}
}

- (void)done:(NSNotification *)notification
{
	ConvertFile *convertFile = [notification object];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:convertFile];
	
	[jobs removeObject:convertFile];
	
	if([jobs count] == 0) {
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ConvertFiles_Finished object:self]];
	}
	
	[self progress:nil];
}

- (void)error:(NSNotification *)notification
{
	ConvertFile *convertFile = [notification object];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:convertFile];
	
	[jobs removeObject:convertFile];
	
	if([jobs count] == 0) {
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ConvertFiles_Finished object:self]];
	}
}

- (void)progress:(NSNotification *)notification
{
	float progress = 0.0;
	
	for(NSUInteger i = 0; i < [jobs count]; i++) {
		progress += [[jobs objectAtIndex:i] percentDone];
	}
	
	// correct for jobs that have already been done and removed from the list
	if([jobs count] < totalJobs) {
		progress += ((totalJobs - [jobs count]) * 100);
	}
	
	progress /= totalJobs;
	
	[self postProgress:progress total:[jobs count]];
}

- (void)postProgress:(NSUInteger)progress total:(NSUInteger)total
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:progress] forKey:ProgressWatcher_Progress];
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ProgressWatcher_UpdateProgress object:self userInfo:userInfo]];
	
	userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d remaining", total] forKey:StatusWatcher_Status];
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:StatusWatcher_UpdateStatus object:self userInfo:userInfo]];
}

- (void)cancel
{
	cancelled = YES;
	
	for(ConvertFile *convertFile in jobs) {
		[convertFile cancel];
	}
}

- (float)findFPS:(QTMovie *)movie
{
	NSArray *videoTracks = [movie tracksOfMediaType:QTMediaTypeVideo];
	QTTrack *videoTrack = [videoTracks objectAtIndex:0];
	QTMedia *media = [videoTrack media];
	NSNumber *sampleCount = [media attributeForKey:QTMediaSampleCountAttribute];
	NSNumber *timeScale = [media attributeForKey:QTMediaTimeScaleAttribute];
	QTTime duration = [[media attributeForKey:QTMediaDurationAttribute] QTTimeValue];
	
	return ([sampleCount longValue] * [timeScale longValue]) / (0.0 + duration.timeValue);
}

@end
