//
//  ConvertFiles.h
//  Watermarker
//
//  Created by Alex P on 02/10/2009.
//  Copyright 2009 Correspondent Corp. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const ConvertFiles_Finished;

@interface ConvertFiles : NSOperation {
	NSString *inputDirectory;
	NSString *outputDirectory;
	BOOL transcodeFiles;
	NSOperationQueue *operationQueue;
	
	NSMutableArray *jobs;
	NSUInteger percentDone;
	NSUInteger totalJobs;
	
	BOOL cancelled;
}

@property (readwrite, copy) NSString *inputDirectory;
@property (readwrite, copy) NSString *outputDirectory;
@property (readwrite, assign) BOOL transcodeFiles;
@property (readwrite, retain) NSOperationQueue *operationQueue;

- (void)cancel;

@end
