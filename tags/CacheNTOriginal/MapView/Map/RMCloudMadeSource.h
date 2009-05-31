//
//  RMCloudMade.h
//  YellowSpacesFree
//
//  Created by samurai on 2/11/09.
//  Copyright 2009 quarrelso.me. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RMAbstractMecatorWebSource.h"

@interface RMCloudMadeSource : RMAbstractMecatorWebSource <RMAbstractMecatorWebSource>
{
	
}

+(int)tileSideLength;
- (NSString*) tileURL: (RMTile) tile;

// override this in subclasses
- (NSString *)style;

// override this in a category to return an API key
- (NSString *)APIKey;

@end

@interface RMCloudMadeOriginalSource : RMCloudMadeSource {}
- (NSString *)style; //1
@end
@interface RMCloudMadeFineLineSource : RMCloudMadeSource {}
- (NSString *)style; //2
@end
@interface RMCloudMadeNoNameSource : RMCloudMadeSource {}
- (NSString *)style; //3
@end
@interface RMCloudMadeIVSource : RMCloudMadeSource {}
- (NSString *)style; //4
@end
@interface RMCloudMadeVSource : RMCloudMadeSource {}
- (NSString *)style; //5
@end
@interface RMCloudMadeVISource : RMCloudMadeSource {}
- (NSString *)style; //6 
@end
@interface RMCloudMadeTouristSource : RMCloudMadeSource {}
- (NSString *)style; //7
@end
@interface RMCloudMadeVIIISource : RMCloudMadeSource {}
- (NSString *)style; // 8
@end
