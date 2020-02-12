//
//  XBFilteredVideoView.h
//  XBImageFilters
//
//  Created by xissburg on 5/19/13.
//
//

#import "XBFilteredView.h"

@interface XBFilteredVideoView : XBFilteredView

@property (nonatomic, copy) NSURL *videoURL;
@property (nonatomic, assign) BOOL replay;

- (void)play;
- (void)stop;
- (void)saveFilteredVideoToURL:(NSURL *)URL completion:(void (^)(BOOL success, NSError *error))completion;

@end
