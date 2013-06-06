//
//  ConvertFile.m
//  SlowDown
//
//  Created by Alex P on 09/02/2010.
//  Copyright 2010 Correspondent Corp. Ltd. All rights reserved.
//

#import "ConvertFile.h"
#import <QTKit/QTKit.h>

NSString * const ConvertFile_Done = @"ConvertFile_Done";
NSString * const ConvertFile_Error = @"ConvertFile_Error";
NSString * const ConvertFile_Progress = @"ConvertFile_Progress";

@interface ConvertFile (Private)

- (NSString *)slowAudio:(QTMovie *)inMovie;
- (NSString *)getUUID;

@end

@implementation ConvertFile

@synthesize inputPath;
@synthesize outputPath;
@synthesize transcodeFile;
@synthesize percentDone;

- (void)dealloc
{
	[inputPath release];
	[outputPath release];
	
	[super dealloc];
}

- (BOOL)isExecuting
{
	return executing;
}

- (BOOL)isCancelled
{
	return cancelled;
}

- (BOOL)isFinished
{
	return finished;
}

- (void)cancel
{
	cancelled = YES;
}

- (void)main
{
	executing = YES;
	finished = NO;
	
	NSError *error;
	
	QTMovie *movieFromFile = [QTMovie movieWithFile:self.inputPath error:&error];
	
	if(error) {
		[self error:error];
		return;
	}
	
	if([self isCancelled]) {
		return;
	}
	
	[movieFromFile setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	[movieFromFile setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieRateChangesPreservePitchAttribute];
	
	if(movieFromFile) {
		NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		
		QTMovie *newMovie = [QTMovie movieWithAttributes:attributes error:&error];
		
		if(error) {
			[self error:error];
			return;
		}
		
		[newMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
		[newMovie setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieRateChangesPreservePitchAttribute];
		
		QTTimeRange insertRange = QTMakeTimeRange(QTZeroTime, [movieFromFile duration]);
		[newMovie insertSegmentOfMovie:movieFromFile timeRange:insertRange atTime:QTZeroTime];
		
		// make movie twice as long as file
		QTTimeRange range = QTMakeTimeRange(QTZeroTime, [movieFromFile duration]);
		QTTime duration = QTMakeTime([movieFromFile duration].timeValue*2, [movieFromFile duration].timeScale);
		[newMovie scaleSegment:range newDuration:duration];
		
		// update tracks
		for(QTTrack *track in [newMovie tracks]) {
			if([[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:QTMediaTypeSound]) {
				// remove sound tracks
				[newMovie removeTrack:track];
			} else if([[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:QTMediaTypeVideo]) {
				// adjust time scale so fps is reported correctly
				QTMedia *media = [track media];
				NSNumber *timeScale = [media attributeForKey:QTMediaTimeScaleAttribute];
				[media setAttribute:[NSNumber numberWithLong:([timeScale longValue]/2)] forKey:QTMediaTimeScaleAttribute];
			}
		}
		
		if([self isCancelled]) {
			return;
		}
		
		// add pre-slowed audio track from passed movie
		NSString *audioFilePath = [self slowAudio:movieFromFile];
		
		if(!audioFilePath) {
			return;
		}
		
		// create movie from audio file
		QTMovie *audio = [QTMovie movieWithFile:audioFilePath error:&error];
		
		if(error) {
			[self error:error];
			return;
		}
		
		// add the audio track to the new movie
		insertRange = QTMakeTimeRange(QTZeroTime, [newMovie duration]);
		
		for(QTTrack *track in [audio tracksOfMediaType:QTMediaTypeSound]) {
			[newMovie insertSegmentOfTrack:track timeRange:insertRange atTime:QTZeroTime];
		}
		
		if([self isCancelled]) {
			return;
		}
		
		NSMutableDictionary *outputFileAttributes = [NSMutableDictionary dictionary];
		
		if(self.transcodeFile) {
			NSLog(@"Transcoding file to intermediate codec");
			NSString *plistError;
			NSPropertyListFormat format;
			NSString *path = [[NSBundle mainBundle] pathForResource:@"export_settings" ofType:@"plist"];
			
			NSData *plist = [NSData dataWithContentsOfFile:path];
			NSData *exportSettings = [NSPropertyListSerialization propertyListFromData:plist 
																	  mutabilityOption:NSPropertyListImmutable 
																				format:&format 
																	  errorDescription:&plistError
									  ];
			
			if(plistError) {
				NSLog(@"Could not read export settings file - %@", plistError);
			} else {
				[outputFileAttributes setObject:[NSNumber numberWithBool:YES] forKey:QTMovieExport];
				[outputFileAttributes setObject:[NSNumber numberWithLong:kQTFileTypeMovie] forKey:QTMovieExportType];
				[outputFileAttributes setObject:exportSettings forKey:QTMovieExportSettings];
			}
		} else {
			[outputFileAttributes setObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten];
		}
		
		// save slowed movie file
		[newMovie writeToFile:self.outputPath withAttributes:outputFileAttributes error:&error];
		
		if(error) {
			[self error:error];
			return;
		}
		
		// remove temp file
		[[NSFileManager defaultManager] removeItemAtPath:audioFilePath error:&error];
		
		if(error) {
			[self error:error];
			return;
		}
	}
	
	executing = NO;
	finished = YES;
	self.percentDone = 100;
	
	NSLog(@"All done with %@", self.inputPath);
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ConvertFile_Done object:self]];
}

- (NSString *)slowAudio:(QTMovie *)inMovie
{
	NSError *error;
	
	// create a new movie
	NSMutableDictionary *attributes = [[inMovie movieAttributes] mutableCopy];
	[attributes setObject:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	[attributes setObject:[NSNumber numberWithBool:NO] forKey:QTMovieRateChangesPreservePitchAttribute];
	
	QTMovie *newMovie = [QTMovie movieWithAttributes:attributes error:&error];
	
	if(error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	
	// add audio tracks from passed file to new movie
	for(QTTrack *track in [inMovie tracksOfMediaType:QTMediaTypeSound]) {
		QTTime trackDuration = [[track attributeForKey:QTMovieDurationAttribute] QTTimeValue];
		[newMovie insertSegmentOfTrack:track timeRange:QTMakeTimeRange(QTZeroTime, trackDuration) atTime:QTZeroTime];
	}
	
	for(QTTrack *track in [newMovie tracks]) {
		if([[track attributeForKey:QTTrackMediaTypeAttribute] isEqualToString:QTMediaTypeVideo]) {
			[newMovie removeTrack:track];
		}
	}
	
	// double length of movie
	QTTimeRange range = QTMakeTimeRange(QTZeroTime, [newMovie duration]);
	[newMovie scaleSegment:range newDuration:QTMakeTime(([newMovie duration].timeValue*2), [newMovie duration].timeScale)];
	
	// write out file to temporary path
	NSString *filePath;
	
	// find a valid temporary file name
	while(YES) {
		filePath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), [self getUUID]];
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			break;
		}
	}
	
	NSLog(@"Writing out temp file at %@", filePath);
	
	NSMutableDictionary *exportAttributes = [NSMutableDictionary dictionary];
	[exportAttributes setObject:[NSNumber numberWithBool:YES] forKey:QTMovieExport];
	[exportAttributes setObject:[NSNumber numberWithLong:kQTFileTypeMP4] forKey:QTMovieExportType];
	
	[newMovie writeToFile:filePath withAttributes:exportAttributes error:&error];
	
	if(error) {
		[self error:error];
		
		return nil;
	}
	
	return filePath;
}

- (void)error:(NSError *)error
{
	NSLog(@"Error slowing file %@\r\n%@", self.inputPath, error);
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ConvertFile_Error object:self]];
	
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
}

- (NSString *)getUUID
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	return [uuidString autorelease];
}

@end
