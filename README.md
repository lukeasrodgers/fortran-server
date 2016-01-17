This repo contains experimental code porting some simple C server code from [Beej's Guide to Network Programming](http://beej.us/guide/bgnet/output/html/singlepage/bgnet.html)
to Fortran.

Running `./server_fortran` will bind to port 3491, send "hello world" to clients that connect, with `nc localhost 3491` for example, and print the connecting IP address.

It should work on OSX, and hopefully, eventually, other platforms as well.

It uses some modern Fortran 2003 features, like `c_f_pointer` and `c_loc`, as well as some utility methods from Joseph Krahn's [c\_interface\_module](http://fortranwiki.org/fortran/show/c_interface_module).

Some functionality is still currently implemented in C, e.g.:
* `errno` is a macro on OSX
* `inet_ntop` involves structs containing pointers, which I don't believe will be interoperable with C in this case

Some quirks/deficiences:

* `posix.f90` isn't really properly named, since not all of the interfaces in there are strictly POSIX, I think, and some of the BSD stuff isn't strictly POSIX compliant.
* More of the code could probably be moved out of server.c into server.f90.
* `man 2 getaddrinfo`, and other documentation, describe `addrinfo` structs as having `ai_canonname` **after** `ai_addr` but inspection in LLDB shows it coming before, and that layout is
the only way to get this code to work.

## Running the code

Passes `-g` flag to compilers for debugging aid.

Run `make` to compile, then `./server_fortran`.
