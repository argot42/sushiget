#!/usr/bin/bash

gcc -c -Wall -fpic get_ssl.c #-Werror -fpic get_ssl.c 
gcc -shared -llua -lssl -lcrypto -o sslrequest.so get_ssl.o
