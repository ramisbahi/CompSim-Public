//
//  TwoPhaseScrambler.m
//  DCTimer scramble
//
//  Created by MeigenChou on 13-4-15.
//
//

#import "TwoPhaseScrambler.h"
#import "Search.h"
#import "Util.h"
#import "CoordCube.h"
#import "CubieCube.h"
#import "stdlib.h"
#import "time.h"
#import "Cross.h"


@implementation TwoPhaseScrambler

int STATE_RANDOM[] = {-2};
int STATE_SOLVED[] = {-3};

-(id) init {
    if (self = [super init]) {
        srand((unsigned)time(0));
    }
    return self;
}

- (int) resolveOri:(int[])arr len:(int)len base:(int)base {
    int sum = 0, idx = 0, lastUnknown = -1;
    for (int i=0; i<len; i++) {
        if (arr[i] == -1) {
            arr[i] = base<2?0:rand()%base;
            lastUnknown = i;
        }
        sum += arr[i];
    }
    if (sum % base != 0 && lastUnknown != -1) {
        arr[lastUnknown] = (30 + arr[lastUnknown] - sum) % base;
    }
    for (int i=0; i<len-1; i++) {
        idx *= base;
        idx += arr[i];
    }
    return idx;
}

- (int) countUnknown:(int[])arr len:(int)len {
    if (arr[0] == -3) {
        return 0;
    }
    int cnt = 0;
    for (int i=0; i<len; i++) {
        if (arr[i] == -1) {
            cnt++;
        }
    }
    return cnt;
}

-(int) resolvePerm:(int[]) arr len:(int)len cntU:(int)cntU parity:(int)parity {
    if (arr[0] == -3) {
        return 0;
    } else if (arr[0] == -2) {
        return parity == -1 ? rand()%2 : parity;
    }
    int val[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
    for (int i=0; i<len; i++) {
        if (arr[i] != -1) {
            val[arr[i]] = -1;
        }
    }
    int idx = 0;
    for (int i=0; i<len; i++) {
        if (val[i] != -1) {
            int j = rand()%(idx + 1);
            int temp = val[i];
            val[idx++] = val[j];
            val[j] = temp;
        }
    }
    int last = -1;
    for (idx=0; idx<len && cntU>0; idx++) {
        if (arr[idx] == -1) {
            if (cntU == 2) {
                last = idx;
            }
            arr[idx] = val[--cntU];
        }
    }
    int perm = [Util getNPerm:arr n:len];
    int p = [Util getNParity:perm n:len];
    if (p == 1-parity && last != -1) {
        int temp = arr[idx-1];
        arr[idx-1] = arr[last];
        arr[last] = temp;
    }
    return p;
}

- (NSString *)randomState:(int[])cp co:(int[])co ep:(int[])ep eo:(int[])eo {
    int parity;
    int cntUE = ep[0] == -2 ? 12 : [self countUnknown:ep len:12];
    int cntUC = cp[0] == -2 ? 8 : [self countUnknown:cp len:12];
    int cpVal, epVal;
    if (cntUE < 2) {    //ep != STATE_RANDOM
        if (ep[0] == -3) {
            epVal = parity = 0;
        } else {
            parity = [self resolvePerm:ep len:12 cntU:cntUE parity:-1];
            epVal = [Util getNPerm:ep n:12];
        }
        if (cp[0] == -3) {
            cpVal = 0;
        } else if (cp[0] == -2) {
            do {
                cpVal = rand()%40320;
            } while ([Util getNParity:cpVal n:8] != parity);
        } else {
            [self resolvePerm:cp len:8 cntU:cntUC parity:parity];
            cpVal = [Util getNPerm:cp n:8];
        }
    } else {    //ep != STATE_SOLVED
        if (cp[0] == -3) {
            cpVal = parity = 0;
        } else if (cp[0] == -2) {
            cpVal = rand()%40320;
            parity = [Util getNParity:cpVal n:8];
        } else {
            parity = [self resolvePerm:cp len:8 cntU:cntUC parity:-1];
            cpVal = [Util getNPerm:cp n:8];
        }
        if (ep[0] == -2) {
            do {
                epVal = rand()%479001600;
            } while ([Util getNParity:epVal n:12] != parity);
        } else {
            [self resolvePerm:ep len:12 cntU:cntUE parity:parity];
            epVal = [Util getNPerm:ep n:12];
        }
    }
    CubieCube *c = [[CubieCube allocWithZone:NULL] initCubie:cpVal twist:co[0] == -2 ? rand()%2187 : (co[0] == -3 ? 0 : [self resolveOri:co len:8 base:3]) eperm:epVal flip:eo[0] == -2 ? rand()%2048 : (eo[0] == -3 ? 0 : [self resolveOri:eo len:12 base:2])];
    return [Util toFaceCube:c];
}

- (NSString *)randomCube {
    return [self randomState:STATE_RANDOM co:STATE_RANDOM ep:STATE_RANDOM eo:STATE_RANDOM];
}

-(NSString*)scramble {
    static BOOL firstRun = YES;
    NSMutableString *sol = [NSMutableString string];
    if (firstRun) {
        [Util setupUtil];
        [CubieCube initMove];
        [CubieCube initSym];
        [CubieCube initFlipSym2Raw];
        [CubieCube initTwistSym2Raw];
        [CubieCube initPermSym2Raw];
        [CoordCube initFlipMove];
        [CoordCube initTwistMove];
        [CoordCube initUDSliceMoveConj];
        [CoordCube initCPermMove];
        [CoordCube initEPermMove];
        [CoordCube initMPermMoveConj];
        [CoordCube initSliceTwistPrun];
        [CoordCube initSliceFlipPrun];
        [CoordCube initMEPermPrun];
        [CoordCube initMCPermPrun];
        firstRun = NO;
    }
    NSString *cube;
    NSArray *sufx = [[NSArray alloc] initWithObjects:@"", @"x'", @"x2", @"x", nil];
    int sw=0;
    cube = [self randomCube]; // no need for checking type - just random
    
    //NSLog(@"%@", cube);
    Search *s = [[Search alloc] init];
    [sol appendFormat:@"%@", [s solutionForFacelets:cube md:21 nt:5000 tm:100 v:2]];
    //NSString *sol = [s solutionForFacelets:cube md:21 nt:5000 tm:100 v:2];
   
    //NSLog(@"%@", sol);
    return sol;
}
@end
