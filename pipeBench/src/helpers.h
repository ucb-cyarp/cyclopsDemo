//
// Created by Christopher Yarp on 10/27/19.
//

#ifndef PIPEBENCH_HELPERS_H
#define PIPEBENCH_HELPERS_H

#include <stdbool.h>
#include <stdio.h>
#include <time.h>

bool isReadyForReading(FILE* file);

typedef struct timespec timespec_t;

double difftimespec(timespec_t* a, timespec_t* b);

#endif //PIPEBENCH_HELPERS_H
