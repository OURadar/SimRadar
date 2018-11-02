//
//  log.h
//  Radar Simulation Framework
//
//  Created by Boon Leng Cheong on 11/2/18.
//  Copyright (c) 2018 Boon Leng Cheong. All rights reserved.
//

#ifndef _rs_log
#define _rs_log

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <sys/time.h>
#include <math.h>

#include "rs_const.h"

#pragma mark -
#pragma mark Convenient functions

char *commaint(long long num);
char *commafloat(float num);
char *now(void);
char *nowlong(void);
char *nowlongoffset(const int offset);

void rsprint(const char *format, ...);

#endif
