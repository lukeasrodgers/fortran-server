server: server.dylib
	gfortran -g posix.f90 c_interface_module.f90 server.dylib server.f90 -o server

server.dylib:
	gcc -g -dynamiclib server.c -o server.dylib

clean: 
	rm -f server.dylib server posix.mod c_interface_module.mod
	rm -rf server.dylib.dSYM/
	rm -rf server.dSYM/
