This repo contains experimental code porting some simple C server code from [Beej's Guide to Network Programming](http://beej.us/guide/bgnet/output/html/singlepage/bgnet.html)
to Fortran.

It binds to port 3491, sends "hello world" to clients that connect, with `nc localhost 3491` for example, and prints the connecting IP address.

It should work on OSX, and hopefully, eventually, other platforms as well.

It uses some modern Fortran 2003 features, like `c_f_pointer` and `c_loc`, as well as some utility methods from Joseph Krahn's [c\_interface\_module](http://fortranwiki.org/fortran/show/c_interface_module).

Some functionality is still currently implemented in C, e.g.:
* `errno` is a macro on OSX
* `inet_ntop` involves structs containing pointers, which are not (in this case) interoperable

Some quirks/deficiences:

* `posix.f90` isn't really properly named, since not all of the interfaces in there are strictly POSIX, I think, and some of the BSD stuff isn't strictly POSIX compliant.
* More of the code could probably be moved out of server.c into server.f90.
* `man 2 getaddrinfo`, and other documentation, lists `ai_canonname` as coming **after** `ai_addr` but inspection in LLDB shows it coming before, and that structure is
the only way to get this code to work.

## Running the code

Passes `-g` flag to compilers for debugging aid.

Run `make` to compile, then `./server_fortran`.
