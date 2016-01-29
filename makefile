ifeq ($(OS),Windows_NT)
    CCFLAGS += -D WIN32
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        CCFLAGS += -D LINUX
	POSIXFILE = linux-posix.f90
	DYLIB := server.so
    endif
    ifeq ($(UNAME_S),Darwin)
        CCFLAGS += -D OSX
	POSIXFILE = osx-posix.f90
	DYLIB := server.dylib
    endif
endif

server: $(DYLIB)
	gfortran $(CCFLAGS) -L. -g server.f90 $(POSIXFILE) c_interface_module.f90 server.so -o server

$(DYLIB):
ifeq ($(UNAME_S),Linux)
	gcc -fPIC -g -shared server.c -o $@
else
	gcc -g -dynamiclib server.c -o $@
endif

clean: 
	rm -f server.dylib server posix.mod c_interface_module.mod server.so
	rm -rf server.dylib.dSYM/
	rm -rf server.dSYM/
