//
// Created by Christopher Yarp on 10/27/19.
//

#include "helpers.h"
#include <stdio.h>
#include <sys/select.h>
#include <sys/time.h>
#include <stdlib.h>

double difftimespec(timespec_t* a, timespec_t* b){
    double a_double = a->tv_sec + (a->tv_nsec)*(0.000000001);
    double b_double = b->tv_sec + (b->tv_nsec)*(0.000000001);
    return a_double - b_double;
}