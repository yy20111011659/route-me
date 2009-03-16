//
//  Sample2AppDelegate.m
//  SampleMap : Diagnostic map
//

#import "SampleMapAppDelegate.h"
#import "RootViewController.h"

@implementation SampleMapAppDelegate


@synthesize window;
@synthesize rootViewController;
@synthesize mapContents;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    NSLog(@"mapView in applicationDidFinishLaunching: %@", [rootViewController view]);
	[window addSubview:[rootViewController view]];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    self.mapContents = nil;
    [rootViewController release];
    [window release];
    [super dealloc];
}

@end
