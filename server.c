/*
** server.c -- a stream socket server demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>

#define BACKLOG 10     // how many pending connections queue will hold

void sigchld_handler(int s)
{
    // waitpid() might overwrite errno, so we save and restore it:
    int saved_errno = errno;

    while(waitpid(-1, NULL, WNOHANG) > 0);

    errno = saved_errno;
}

int my_errno() {
  return errno;
}

// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

// get port, IPv4 or IPv6:
void print_in_port(struct sockaddr *sa)
{
    in_port_t port;
    if (sa->sa_family == AF_INET) {
      printf("afint\n");
        port = (((struct sockaddr_in*)sa)->sin_port);
    }
    else {
      printf("afint6\n");
        port = (((struct sockaddr_in6*)sa)->sin6_port);
    }

    printf("port is %d\n",ntohs(port));
    return;
}

// We can't use normal inet_ntop because it involves structs with pointers, which
// are not interoperable between C and Fortran.
void my_inet_ntop(struct sockaddr_storage *their_addr, char *buff, int buf_size) {
  inet_ntop(their_addr->ss_family, get_in_addr((struct sockaddr *)their_addr), buff, buf_size);
  return;
}

int sockaddr_storage_size() {
  struct sockaddr_storage foo;
  return sizeof foo;
}

int just_handle() {
    struct sigaction sa;

    sa.sa_handler = sigchld_handler; // reap all dead processes
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction");
        return 1;
    }
    return 0;
}
