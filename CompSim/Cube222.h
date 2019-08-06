//
//  Cube222.h
//  CompSim
//
//  Created by Rami Sbahi on 7/17/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

//
//  Cube222.h
//  DCTimer Solvers
//
//  Created by MeigenChou on 12-11-2.
//  Copyright (c) 2012年 MeigenChou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cube222 : NSObject {
    int state[2][8];
    char perm[5040];
    char twist[729];
    short permmv[5040][3];
    short twstmv[729][3];
}

-(NSString *) scramble;

@end
