//
// Created by Christopher Yarp on 10/22/19.
//

#include "helpers.h"
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
    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;

    int selectStatus = select(maxFD, &fdSet, NULL, NULL, &timeout);
    if(selectStatus == -1){
        fprintf(stderr, "Error while checking if a file is ready for reading\n");
        perror(NULL);
        exit(1);
    }

    return FD_ISSET(fileFD, &fdSet);
}