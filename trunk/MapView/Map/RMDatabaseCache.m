//
//  RMDatabaseCache.m
//  RouteMe
//
//  Created by Joseph Gentle on 19/09/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RMDatabaseCache.h"
#import "RMTileCacheDAO.h"
#import "RMTileImage.h"
#import "RMTile.h"

@implementation RMDatabaseCache

+ (NSString*)dbPathForTileSource: (id<RMTileSource>) source
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) // Should only be one...
	{
		NSString *filename = [NSString stringWithFormat:@"Map%@.sqlite", [source description]];
		
		return [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
	}
	return nil;
}

-(id) initWithDatabase: (NSString*)path
{
	if (![super init])
		return nil;
	
	//	NSLog(@"%d items in DB", [[DAO sharedManager] count]);
	
	dao = [[RMTileCacheDAO alloc] initWithDatabase:path];

	if (dao == nil)
		return nil;
	
	return self;	
}

-(id) initWithTileSource: (id<RMTileSource>) source
{
	return [self initWithDatabase:[RMDatabaseCache dbPathForTileSource:source]];
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

-(void)addTile: (RMTile)tile WithImage: (RMTileImage*)image
{
	// The tile probably hasn't loaded any data yet... we must be patient.
	// However, if the image is already loaded we probably don't need to cache it.
	
	// This will be the case for any other web caches which are active.
	if (![image isLoaded])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(addImageData:)
													 name:RMMapImageLoadedNotification
												   object:image];
	}
}

-(void) addImageData: (NSNotification *)notification
{
	NSData *data = [[notification userInfo] objectForKey:@"data"];
	RMTileImage *image = (RMTileImage*)[notification object];
	[dao addData:data LastUsed:[image lastUsedTime] ForTile:RMTileHash([image tile])];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:RMMapImageLoadedNotification
												  object:image];
	
	
//	NSLog(@"%d items in DB", [dao count]);
}

-(RMTileImage*) cachedImage:(RMTile)tile
{
//	NSLog(@"Looking for cached image in DB");
	
	NSData *data = [dao dataForTile:RMTileHash(tile)];
	if (data == nil)
		return nil;
	
	RMTileImage *image = [RMTileImage imageWithTile:tile FromData:data];
//	NSLog(@"DB cache hit for tile %d %d %d", tile.x, tile.y, tile.zoom);
	return image;
}

@end
