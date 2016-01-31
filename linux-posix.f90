!
! Fortran POSIX interfaces
!
module posix
  use, intrinsic :: ISO_C_BINDING
  implicit none

  ! these constants should all be the same on linux and BSD
  integer, parameter :: AF_UNSPEC = 0
  integer, parameter :: AF_UNIX = 1
  integer, parameter :: AF_INET = 2
  integer, parameter :: AF_INET6 = 10

  integer, parameter :: SOCK_STREAM = 1
  integer, parameter :: SOCK_DGRAM = 2
  integer, parameter :: SOCK_RAW = 3
  integer, parameter :: SOCK_SEQPACKET = 5

  ! sys/socket.h
  integer, parameter :: SOL_SOCKET = 1
  integer, parameter :: SO_REUSEADDR = 2

  ! netdb.h
  integer, parameter :: AI_PASSIVE = 1

  integer(kind=c_long), parameter :: SS_MAXSIZE = 128
  ! better way to define this?
  ! in C: _SS_ALIGNSIZE (sizeof(int64_t))
  integer(kind=c_long), parameter :: SS_ALIGNSIZE = 8
  ! type: sa_family_t: c_int
  ! in C, 4 is, instead, sizeof(sa_family_t)
  integer(kind=c_int), parameter :: SS_PAD1SIZE = (SS_ALIGNSIZE - 4)
  integer(kind=c_int), parameter :: SS_PAD2SIZE = (SS_MAXSIZE - 4 + SS_PAD1SIZE + SS_ALIGNSIZE)

  type :: c_streampointer
    type (c_ptr) :: handle = c_null_ptr
  end type c_streampointer

  ! this is correct for posix/linux, but not (post 1998) BSD
  ! type, bind(C) :: c_sockaddr
    ! integer(c_short) :: sa_family
    ! character(kind=c_char,len=1) :: sa_data ! in C, len 14
  ! end type c_sockaddr

  type, bind(C) :: c_sockaddr
    character(c_char) :: sa_family ! in C, sa_family_t
    character(kind=c_char,len=1) :: sa_data ! in C, len 14
  end type c_sockaddr

  type, bind(C) :: c_in_addr
    integer(c_long) :: s_addr
  end type c_in_addr

  type, bind(C) :: c_in6_addr
    character(c_char) :: s6_addr
  end type c_in6_addr

  ! this may be cast to a C sockaddr struct
  type, bind(C) :: c_sockaddr_in
    character(c_char) :: sin_family
    integer(c_short) :: sin_port
    type(c_in_addr) :: sin_addr
    character(kind=c_char) :: sin_zero
  end type c_sockaddr_in

  ! HACK:
  ! Derived types with embedded derived types are not fully c-compatible.
  ! Specifically, calling `c_loc` intrinsic on an embedded derived type will
  ! not return the correct value (in the case of c_sockaddr_in, it was 4 bytes
  ! past where it should be. To compensate, we can use an intentionally incorrectly
  ! laid-out derived type, where calling `c_loc` on `sin_addr` will work
  ! correctly.
  ! This is probably *highly* non-interoperable across compilers and/or platforms.
  type, bind(C) :: c_sockaddr_in_resized
    character(c_char) :: sin_family
    integer(c_short) :: sin_port ! osx is in_port_t, aka __uint16_t
    character(c_char) :: sin_addr
    character(kind=c_char) :: sin_zero
  end type c_sockaddr_in_resized

  ! this may be cast to a C sockaddr struct
  type, bind(C) :: c_sockaddr_in6
    integer(c_short) :: sin6_family
    integer(c_short) :: sin6_port
    integer(c_long) :: sin6_flowinfo
    type(c_in6_addr) :: sin6_addr
    integer(c_long) :: sin6_scope_id
  end type c_sockaddr_in6

  ! Some functions, e.g. `accept(2)` require the size of this struct to be passed in, so 
  ! we have to make a separate C call to get that value
  type, bind(C) :: c_sockaddr_storage
    character(c_char) :: ss_family
    character(kind=c_char,len=1) :: ss_pad1
    integer(kind=c_long) :: ss_align
    character(kind=c_char,len=1) :: ss_pad2
  end type c_sockaddr_storage

  type, bind(C) :: c_addrinfo
    integer(c_int) :: ai_flags
    integer(c_int) :: ai_family
    integer(c_int) :: ai_socktype
    integer(c_int) :: ai_protocol
    integer(c_size_t) :: ai_addrlen
    type(c_ptr) :: ai_addr
    type(c_ptr) :: ai_canonname
    type(c_ptr) :: ai_next
  end type c_addrinfo

  interface
    type (c_ptr) function c_popen(command, mode) bind(C, name='popen')
      use, intrinsic :: ISO_C_BINDING
      character(kind=c_char), dimension(*) :: command, mode
    end function

    type (c_ptr) function c_fgets(str, siz, stream) bind(C, name='fgets')
      use, intrinsic :: ISO_C_BINDING
      ! assumed size, or any shape works here, but not assume shape...?
      character(kind=c_char), dimension(*) :: str
      integer(kind=c_int), value :: siz
      type (c_ptr), value :: stream
    end function

    integer(c_int) function c_pclose(handle) bind(C, name='pclose')
    use, intrinsic :: ISO_C_BINDING
    type (c_ptr), value :: handle
    end function

    integer(c_int) function c_socket(domain, type, protocol) bind(C, name='socket')
      use, intrinsic :: iso_c_binding
      integer(kind=c_int), value :: domain, type, protocol
    end function c_socket

    integer(c_int) function c_setsockopt(socket, level, option_name, option_value, option_len) bind(c, name='setsockopt')
      use, intrinsic :: iso_c_binding
      integer(c_int), value :: socket, level, option_name, option_len
      type(c_ptr), value :: option_value
    end function c_setsockopt

    integer(c_int) function c_bind(sockfd, sockaddr, addrlen) bind(C, name='bind')
      use, intrinsic :: iso_c_binding
      type(c_ptr), value :: sockaddr
      integer(kind=c_int), value :: sockfd
      integer(c_size_t), value :: addrlen
    end function c_bind

    integer(c_short) function c_htons(hostshort) bind(C, name='htons')
      use, intrinsic :: iso_c_binding
      integer(kind=c_short), value :: hostshort
    end function c_htons

    integer(c_int) function c_inet_addr(cp) bind(C, name='inet_addr')
      use, intrinsic :: iso_c_binding
      character(kind=c_char), dimension(*) :: cp
    end function c_inet_addr

    ! getaddrinfo
    ! this is not completely portable, since hints is a pointer to an `addrinfo` struct, which
    ! itself contains pointers, and this type of data structure is not completely interoperable
    integer(c_int) function c_getaddrinfo(hostname, servname, hints, res) bind(C, name='getaddrinfo')
      use, intrinsic :: iso_c_binding
      type(c_ptr), value :: hostname, servname, hints, res
    end function c_getaddrinfo

    type(c_ptr) function c_inet_ntop(af, src, dst, dst_size) bind(C, name='inet_ntop')
      use, intrinsic :: iso_c_binding
      integer(c_int), value :: af, dst_size
      type(c_ptr), value :: src
      type(c_ptr), value :: dst
    end function c_inet_ntop

    integer(c_int) function c_listen(sockfd, backlog) bind(C, name='listen')
      use, intrinsic :: iso_c_binding
      integer(kind=c_int), value :: sockfd, backlog
    end function c_listen

    integer(c_size_t) function c_send(sockfd, buffer, length, flags) bind(c, name='send')
      use, intrinsic :: iso_c_binding
      integer(c_int), value :: sockfd
      integer(c_size_t), value :: length
      integer(c_int), value :: flags
      character(kind=c_char), dimension(*) :: buffer
    end function c_send

    integer(c_int) function c_fork() bind(C, name='fork')
      use, intrinsic :: iso_c_binding
    end function c_fork

    integer(c_int) function c_accept(socket, address, address_len) bind(c, name='accept')
      use, intrinsic :: iso_c_binding
      integer(c_int), value :: socket
      type(c_ptr), value :: address, address_len
    end function c_accept

    integer(c_int) function c_close(fd) bind(c, name='close')
      use, intrinsic :: iso_c_binding
      integer(c_int), value :: fd
    end function c_close

    integer(c_short) function c_ntohs(netshort) bind(c, name='ntohs')
      use, intrinsic :: iso_c_binding
      integer(c_short), value :: netshort
    end function c_ntohs
  end interface

end module posix
