//
//  RESTOperationsAppDelegate.m
//  RESTOperations
//
//  Created by Stefan Herold on 9/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RESTOperationsAppDelegate.h"

@implementation RESTOperationsAppDelegate

@synthesize window = _window;

- (void)PCLRestCommandDidFinish:(PCLRestCommand*)command {

	NSAssert([NSThread isMainThread], @"Current Thread expected to be the main thread");
	NSLog(@"PCLRestCommandDidFinish (%@)", command.identifier);
	
	
	// DEBUG
	
//	CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) [command.URLResponse textEncodingName]);
//	NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
//	NSString * string = [[NSString alloc] initWithData:command.result encoding:encoding];
//	NSLog(@"%@", string);
//	[string release];
}

- (void)PCLRestCommandDidFail:(PCLRestCommand*)command withError:(NSError*)anError {
	NSAssert([NSThread isMainThread], @"Current Thread expected to be the main thread");
	NSLog(@"PCLRestCommandDidFailWithError (%@): %@", command.identifier, anError);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{	
	NSString * urlString = @"https://www.google.com/";
	
	for( int i=0; i<50; i++ ) {	
		NSString * identifier = [[NSString alloc] initWithFormat:@"CMD: %d", i];
		
		PCLRestCommand * command = [[PCLRestCommand alloc] 
				initWithRootURLString:urlString 
				path:nil 
				getParameters:nil 
				identifier:identifier
				authenticationRequired:NO];
				
		command.delegate = self;
		
		[command executeInBackground];
		[command release];
		[identifier release];
	}

	// Override point for customization after application launch.
	[self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

- (void)dealloc
{
	[_window release];
    [super dealloc];
}

@end
