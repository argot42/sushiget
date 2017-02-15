//#include <stdio.h>
#include <string.h>

#include "openssl/ssl.h"
#include "openssl/bio.h"
#include "openssl/err.h"

char* receive(BIO *bio, int chunksize) {
    int  readbytes, count = 1;
    char tmp[chunksize], *buf = NULL;

    buf = (char *) malloc(chunksize * sizeof(char));
    buf[0] = '\0';
    while(1) {
        readbytes = BIO_read(bio, tmp, chunksize - 1); 
        if(readbytes <= 0) break;
        tmp[readbytes] = '\0';

        buf = (char *) realloc(buf, chunksize * sizeof(char) * count);

        strncat(buf, tmp, strlen(tmp));

        count++;
    }
    return buf;
}

int ssl_get(char *host, char *port, char *request, char **response, int datasize, int hostsize) {
    char host_port[hostsize];
    int host_size;

    /* ssl */
    BIO *bio;
    SSL *ssl;
    SSL_CTX *ctx;

    /* init ssl lib */
    SSL_library_init();
    ERR_load_BIO_strings();
    OpenSSL_add_all_algorithms();

    /* set up ssl context */
    ctx = SSL_CTX_new(SSLv23_client_method());

    /* set up connection */
    bio = BIO_new_ssl_connect(ctx);
    BIO_get_ssl(bio, &ssl);
    SSL_set_mode(ssl, SSL_MODE_AUTO_RETRY);

    /* create connection */
    /* host and port on the form of <host>:<port> */
    strncpy(host_port, host, strlen(host));
    host_size = strlen(host_port);
    host_port[host_size] = ':';
    host_port[host_size + 1] = '\0';
    strncat(host_port, port, strlen(port));
    

    BIO_set_conn_hostname(bio, host_port);
    
    if (BIO_do_connect(bio) <= 0) {
        //fprintf(stderr, "Error attempting to connect\n");
        //ERR_print_errors_fp(stderr);
        BIO_free_all(bio);
        SSL_CTX_free(ctx);
        return -2;
    }

    /* Send request */
    BIO_write(bio, request, strlen(request));

    /* read response */
    (*response) = receive(bio, datasize);
    

    BIO_free_all(bio);
    SSL_CTX_free(ctx);

    return 0;
}
