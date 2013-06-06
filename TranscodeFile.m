//
//  TranscodeFile.m
//  SlowDown
//
//  Created by Alex Potsides on 06/03/2011.
//  Copyright 2011 Correspondent Corp. Ltd. All rights reserved.
//

#import "TranscodeFile.h"
#import <QTKit/QTKit.h>

@implementation TranscodeFile

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
			
			// save slowed movie file
			[movieFromFile writeToFile:self.outputPath withAttributes:outputFileAttributes error:&error];
		} else {
			// movie doesn't need slowing down, copy input file to output location
			NSFileManager *fileManager = [NSFileManager defaultManager];
			
			if(![fileManager fileExistsAtPath:self.outputPath]) {
				[fileManager copyItemAtPath:self.inputPath toPath:self.outputPath error:&error];
				
				if(error) {
					NSLog(@"Error: %@", error);
				}
			}
		}
		
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

@end
