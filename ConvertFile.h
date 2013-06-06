//
//  ConvertFile.h
//  SlowDown
//
//  Created by Alex P on 09/02/2010.
//  Copyright 2010 Correspondent Corp. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const ConvertFile_Done;
extern NSString * const ConvertFile_Error;
extern NSString * const ConvertFile_Progress;

@interface ConvertFile : NSOperation {
	NSString *inputPath;
	NSString *outputPath;
	BOOL transcodeFile;
	NSUInteger percentDone;
	
	BOOL executing;
	BOOL cancelled;
	BOOL finished;
}

@property (nonatomic, copy) NSString *inputPath;
@property (nonatomic, copy) NSString *outputPath;
@property (nonatomic, assign) BOOL transcodeFile;
@property (nonatomic, assign) NSUInteger percentDone;

- (BOOL)isExecuting;
- (BOOL)isCancelled;
- (BOOL)isFinished;
- (void)cancel;

// protected
- (void)error:(NSError *)error;

@end
