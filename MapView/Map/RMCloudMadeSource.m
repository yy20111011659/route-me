//
//  RMCloudMade.m
//  YellowSpacesFree
//
//  Created by samurai on 2/11/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import "RMCloudMadeSource.h"

@implementation RMCloudMadeSource

- (NSString *)APIKey;
{
	return @"0";
}

-(NSString*) tileURL: (RMTile) tile
{
	return [NSString stringWithFormat:@"http://tile.cloudmade.com/%@/%@/%d/%d/%d/%d.png",[self APIKey],[self style],256, tile.zoom, tile.x, tile.y];
}

+(int)tileSideLength
{
	return 256;
}

- (NSString *)style;
{
	return nil;
}

@end

@implementation RMCloudMadeOriginalSource 

- (NSString *)style; {
	return @"1";
}//1
@end
@implementation RMCloudMadeFineLineSource 
- (NSString *)style; {
	return @"2";
}
@end
@implementation RMCloudMadeNoNameSource
- (NSString *)style; {
	return @"3";
}
@end
@implementation RMCloudMadeIVSource
- (NSString *)style; {
	return @"4";
}
@end
@implementation RMCloudMadeVSource 
- (NSString *)style; {
	return @"5";
}
@end
@implementation RMCloudMadeVISource 
- (NSString *)style; {
	return @"6";
}
@end
@implementation RMCloudMadeTouristSource
- (NSString *)style; {
	return @"7";
}
@end
@implementation RMCloudMadeVIIISource
- (NSString *)style; // 8
{
	return @"8";
}
@end

