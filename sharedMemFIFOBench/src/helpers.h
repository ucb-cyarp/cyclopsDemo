//
// Created by Christopher Yarp on 10/27/19.
//

#ifndef SHAREDMEMFIFOBENCH_HELPERS_H
#define SHAREDMEMFIFOBENCH_HELPERS_H

#include <stdbool.h>
#include <stdio.h>
#include <time.h>

typedef struct timespec timespec_t;

double difftimespec(timespec_t* a, timespec_t* b);

#endif //SHAREDMEMFIFOBENCH_HELPERS_H
