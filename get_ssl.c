#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "openssl/ssl.h"
#include "openssl/bio.h"
#include "openssl/err.h"

#include "lua.h"
#include "lauxlib.h"

static void print_stringu (const char *string, size_t size) {
    if (string) {
        for(int i=0; i < size; i++) printf("%c", string[i]);
        printf("\n");
    }
    else printf("");
}

static char* concat(const char *dest, const char *src, size_t dest_size, size_t src_size) {
    char *new = (char *) malloc(dest_size + src_size);

    if (!dest && !src) return NULL;

    if (!new) return NULL;

    if (!dest) for (int i=0; i < src_size; i++) new[i] = src[i];
    else if (!src) for (int i=0; i < dest_size; i++) new[i] = dest[i];
    else {
        for (int i=0; i< dest_size; i++) new[i] = dest[i];
        for (int i=dest_size, j=0; j < src_size ; i++, j++) new[i] = src[j];
    }

    return new;
}

static char* receive(BIO *bio, int chunksize, int *total_size) {
    int bytes_read, total_bytes = 0;
    char tmp[chunksize], *buf = NULL;

    while(1) {
        bytes_read = BIO_read(bio, tmp, chunksize);
        if(bytes_read <= 0) break;

        buf = concat(buf, tmp, total_bytes, bytes_read);
        total_bytes += bytes_read;
    }

    *total_size = total_bytes;
    return buf;
}

static int ssl_get(const char *host, const char *port, const char *request, char **response, const int datasize, const int hostsize) {
    char host_port[hostsize];
    int host_size, total_size = 0;

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
    host_size = strlen(host);
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
    (*response) = receive(bio, datasize, &total_size);

    BIO_free_all(bio);
    SSL_CTX_free(ctx);

    return total_size;
}

/* lua wrapper */
static int l_ssl_get (lua_State *L) {
    const char *host, *port, *request;
    char *response;
    int datasize, hostsize, isnumber_datasize, isnumber_hostsize, total_size;
    int arguments = lua_gettop(L);

    /* check number of arguments */
    if(arguments != 5){
        lua_pushnil(L);
        lua_pushstring(L, "Incorrect number of arguments");
        return 2;
    }

    /* get arguments */
    host = lua_tostring(L, 1);
    port = lua_tostring(L, 2);
    request = lua_tostring(L, 3);
    datasize = lua_tointegerx(L, 4, &isnumber_datasize);  
    hostsize = lua_tointegerx(L, 5, &isnumber_hostsize);

    /* return error if wrong argument type */
    if (!host) {
        lua_pushnil(L);
        lua_pushstring(L, "Argument 1 needs to be a string");
        return 2;
    }
    if (!port) {
        lua_pushnil(L);
        lua_pushstring(L, "Argument 2 needs to a string");
        return 2;
    }
    if (!request) {
        lua_pushnil(L);
        lua_pushstring(L, "Argument 3 needs to a string");
    }
    if (!isnumber_datasize) {
        lua_pushnil(L);
        lua_pushstring(L, "Argument 4 needs to be an integer");
        return 2;
    }
    if (!isnumber_hostsize) {
        lua_pushnil(L);
        lua_pushstring(L, "Argument 5 needs to be an integer");
        return 2;
    }

    /* call function */
    total_size = ssl_get(host, port, request, &response, datasize, hostsize);

    if(total_size == -2) {
        lua_pushnil(L);
        lua_pushstring(L, "Error attempting to connect");
        return 2;
    }

    lua_pushlstring(L, response, total_size);
    return 1;
}

static const struct luaL_Reg sslrequest [] = {
    {"ssl_get", l_ssl_get},
    {NULL, NULL}
};

int luaopen_sslrequest (lua_State *L) {
    luaL_newlib(L, sslrequest);
    return 1;
}
