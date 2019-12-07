//
//  CHTScrambler.m
//  ChaoTimer
//
//  Created by Jichao Li on 10/6/13.
//  Copyright (c) 2013 Jichao Li. All rights reserved.
//

#import "BigCubeScrambler.h"
//#import "LatchCube.h"
//#import "Floppy.h"
//#import "RTower.h"
//#import "EOLine.h"
#import "stdlib.h"
#import "time.h"

@interface BigCubeScrambler()

@end

@implementation BigCubeScrambler

- (id)init {
    if(self = [super init]) {
        srand((unsigned)time(0));
        //cubesuff = [[NSArray alloc] initWithObjects:@"", @"2", @"'", nil];
    }
    return self;
}

- (NSString *)megascramble: (NSArray *)turns len:(int)len suf:(NSArray *)suff sql:(int)sql {
    int donemoves[10];
    int lastaxis = -1, len2 = turns.count / len, slen = suff.count;
    //NSLog(@"%d %d", len2, slen);
    NSMutableString *s = [NSMutableString string];
    for (int j=0; j<sql; j++) {
        int done = 0;
        do {
            int first = rand()%len;
            int second = rand()%len2;
            if(first!=lastaxis || donemoves[second]!=1) {
                if(first!=lastaxis) {
                    for(int k=0; k<10; k++)donemoves[k]=0;
                    lastaxis = first;
                }
                donemoves[second] = 1;
                [s appendFormat:@"%@%@ ", [turns objectAtIndex:first*len2+second], [suff objectAtIndex:(rand()%slen)]];
                done = 1;
            }
        } while (done==0);
    }
    return s;
}

- (NSString *)megascramble:(NSArray *)turns suf:(NSArray *)suff sql:(int)len ia:(BOOL)isArray {
    int donemoves[10];
    int lastaxis = -1, slen = suff.count;
    //NSLog(@"%d %d", len2, slen);
    NSMutableString *s = [NSMutableString string];
    for (int j=0; j<len; j++) {
        int done = 0;
        do {
            int first = rand()%turns.count;
            int second = rand()%([[turns objectAtIndex:first] count]);
            if(first!=lastaxis) {
                for(int k=0; k<10; k++)donemoves[k]=0;
                lastaxis = first;
            }
            if(donemoves[second]!=1) {
                donemoves[second] = 1;
                if(isArray)
                    [s appendFormat:@"%@%@ ", [[[turns objectAtIndex:first] objectAtIndex:second] objectAtIndex:rand()%[[[turns objectAtIndex:first] objectAtIndex:second] count]], [suff objectAtIndex:(rand()%slen)]];
                else [s appendFormat:@"%@%@ ", [[turns objectAtIndex:first] objectAtIndex:second], [suff objectAtIndex:(rand()%slen)]];
                done = 1;
            }
        } while (done==0);
    }
    return s;
}

- (NSString *)getScrStringByType:(int)type {
    NSString *scr = @"";
    NSArray *turn, *cubesuff = [[NSArray alloc] initWithObjects:@"", @"2", @"'", nil];
    switch (type) {
        case 4: // 4x4
            NSLog(@"4x4");
            turn = [[NSArray alloc] initWithObjects:@"U", @"Uw", @"D", @"L", @"Rw", @"R", @"F", @"Fw", @"B", nil];
            scr = [self megascramble:turn len:3 suf:cubesuff sql:40];
            break;
        case 5: // 5x5
            NSLog(@"5x5");
            turn = [[NSArray alloc] initWithObjects:@"U", @"Uw", @"Dw", @"D", @"L", @"Lw", @"Rw", @"R", @"F", @"Fw", @"Bw", @"B", nil];
            scr = [self megascramble:turn len:3 suf:cubesuff sql:60];
            break;
        case 6: // 6x6
            NSLog(@"6x6");
            turn = [[NSArray alloc] initWithObjects:@"U", @"2U", @"3U", @"2D", @"D", @"L", @"2L", @"3R", @"2R", @"R", @"F", @"2F", @"3F", @"2B", @"B", nil];
            scr = [self megascramble:turn len:3 suf:cubesuff sql:80];
            break;
        case 7: // 7x7
            NSLog(@"7x7");
            turn = [[NSArray alloc] initWithObjects:@"U", @"2U", @"3U", @"3D", @"2D", @"D", @"L", @"2L", @"3L", @"3R", @"2R", @"R", @"F", @"2F", @"3F", @"3B", @"2B", @"B", nil];
            scr = [self megascramble:turn len:3 suf:cubesuff sql:100];
            break;
    }
    NSLog(@"New Scramble: %@", scr);
    return scr;
}

@end
