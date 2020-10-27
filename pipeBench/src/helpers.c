//
// Created by Christopher Yarp on 10/27/19.
//

#include "helpers.h"
#include <stdio.h>
#include <sys/select.h>
#include <sys/time.h>
#include <stdlib.h>

bool isReadyForReading(FILE* file){
    //See http://man7.org/linux/man-pages/man2/select.2.html for info on using select
    //See https://stackoverflow.com/questions/3167298/how-can-i-convert-a-file-pointer-file-fp-to-a-file-descriptor-int-fd for getting a fd from a FILE*

    int fileFD = fileno(file);
    fd_set fdSet;
    FD_ZERO(&fdSet);
    FD_SET(fileFD, &fdSet);
    int maxFD = fileFD;

    //Timeout quickly
    struct timespec timeout;
    timeout.tv_sec = 0;
    timeout.tv_nsec = 0;

    int selectStatus = pselect(maxFD+1, &fdSet, NULL, NULL, &timeout, NULL);
    if(selectStatus == -1){
        fprintf(stderr, "Error while checking if a file is ready for reading\n");
        perror(NULL);
        exit(1);
    }
    return FD_ISSET(fileFD, &fdSet);
}

double difftimespec(timespec_t* a, timespec_t* b){
    double a_double = a->tv_sec + (a->tv_nsec)*(0.000000001);
    double b_double = b->tv_sec + (b->tv_nsec)*(0.000000001);
    return a_double - b_double;
}