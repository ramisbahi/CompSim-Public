//
//  Scrambler.m
//  CompSim
//
//  Created by Rami Sbahi on 7/17/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Scrambler : NSObject
- (NSString *)getScrString:(int)idx;
+ (NSMutableArray *)imageString:(int)size scr:(NSString *)scr;
@end

#import "Cube222.h"
#import "stdlib.h"

@interface Scrambler()
@property (nonatomic, strong) Cube222 *cube2;
@end

@implementation Scrambler
@synthesize cube2;
int cubeSize;
int viewType;
NSMutableArray *scrPosit;
NSMutableArray *flat2posit;

- (id)init {
    if(self = [super init]) {
        srand((unsigned)time(0));
        //cubesuff = [[NSArray alloc] initWithObjects:@"", @"2", @"'", nil];
    }
    return self;
}

- (NSString *)scramble222: (int) type {
    if(!cube2)
        cube2 = [[Cube222 alloc] init];
    return [cube2 scramble];
}

@end
