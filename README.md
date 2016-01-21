This repo contains experimental code porting some simple C server code from [Beej's Guide to Network Programming](http://beej.us/guide/bgnet/output/html/singlepage/bgnet.html)
to Fortran.

It should work on OSX, and hopefully, eventually, other platforms as well.

## Why would anyone...?

I'm learning Fortran, and this seemed like an interesting challenge. I don't think any sane person would ever want to actually try to write a production web service in Fortran.

## Running the code

Run `make` to compile, then `./server`.  This will bind to port 3491, send "hello world" to clients that connect, with `nc localhost 3491` for example, and print the connecting IP address.

The makefile passes the `-g` flag to compilers for debugging aid.

## Notes on the code

It uses some modern Fortran 2003 features, like `c_f_pointer` and `c_loc`, as well as some utility methods from Joseph Krahn's [c\_interface\_module](http://fortranwiki.org/fortran/show/c_interface_module).

Some functionality is still currently implemented in C, e.g.:
* `errno` is a macro on OSX, so we can't just create a Fortran interface for it
* haven't got around to implementing the signal handling in Fortran, mostly because I don't understand enough about how it works, or how to verify it is working as intended.

### Some quirks/deficiences:

* `posix.f90` isn't really properly named, since not all of the interfaces in there are strictly POSIX, I think, and some of the BSD/XNU stuff isn't strictly POSIX compliant.
* More of the code could probably be moved out of server.c into server.f90.
* `man 3 getaddrinfo`, and other documentation, describe `addrinfo` structs as having `ai_canonname` *after* `ai_addr` but inspection in LLDB shows it coming before, and that layout is
the only way to get this code to work.
* the Fortran code that prepares the call to `inet_ntop` has to use some ugly workarounds for the fact that calling `c_loc` on nested derived types is not fully c-interoperable. Also, this 
code is probably broken for ipv6.
