ifeq ($(OS),Windows_NT)
    CCFLAGS += -D WIN32
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        CCFLAGS += -D LINUX
				POSIXFILE = linux-posix.f90
    endif
    ifeq ($(UNAME_S),Darwin)
        CCFLAGS += -D OSX
				POSIXFILE = osx-posix.f90
    endif
endif

server: server.dylib
	gfortran $(CCFLAGS) -g $(POSIXFILE) c_interface_module.f90 server.dylib -cpp server.f90 -o server

server.dylib:
	gcc -g -dynamiclib server.c -o server.dylib

clean: 
	rm -f server.dylib server posix.mod c_interface_module.mod
	rm -rf server.dylib.dSYM/
	rm -rf server.dSYM/
