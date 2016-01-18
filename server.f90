program server
  use, intrinsic :: iso_c_binding
  use posix
  use c_interface_module
  implicit none

  interface
    integer(c_int) function just_handle() bind(c, name='just_handle')
      use, intrinsic :: iso_c_binding
    end function just_handle

    integer(c_int) function sockaddr_storage_size() bind(c, name='sockaddr_storage_size')
      use, intrinsic :: iso_c_binding
    end function sockaddr_storage_size

    subroutine c_my_inet_ntop(their_addr, buff, buff_size) bind(c, name='my_inet_ntop')
      use, intrinsic :: iso_c_binding
      type(c_ptr), value :: their_addr, buff
      integer(c_int) :: buff_size
    end subroutine c_my_inet_ntop

    integer(c_int) function c_errno() bind(c, name='my_errno')
      use, intrinsic :: iso_c_binding
    end function c_errno
  end interface

  integer(c_int), parameter :: INET6_ADDRSTRLEN = 46 ! freebsd in6.h defines this value
  integer(c_int), parameter :: backlog = 10
  integer(c_int) :: sockfd, newfd
  type(c_sockaddr_storage), target :: their_addr
  integer(kind=c_int), target :: my_sockaddr_storage_size
  ! see http://man7.org/linux/man-pages/man2/accept.2.html
  ! this is normally defined as type socklen_t, which is/should usually be int
  integer(c_int) sent, closed
  integer pid
  integer(c_size_t) message_len
  type(c_sockaddr), pointer :: mysockaddr
  character(len=INET6_ADDRSTRLEN), target :: ipaddrstr
  character(len=20), target :: message
  character(len=7), target :: port
  type(c_addrinfo), target :: addrinfo_hints, servinfo
  type(c_addrinfo), pointer :: p
  type(C_void_ptr) :: n
  integer(c_int) :: rv, res
  integer(c_int), target :: yes = 1, optlen = 4
  type(c_ptr), target :: servinfo_ptr
  ! initialize addrinfo_hints to 0
  n = C_memset(c_loc(addrinfo_hints), 0, sizeof(addrinfo_hints))
  n = C_memset(c_loc(servinfo), 0, sizeof(servinfo))

  message = "hello, world"//C_NULL_char
  port = "3491"//C_NULL_CHAR

  my_sockaddr_storage_size = sockaddr_storage_size()

  addrinfo_hints%ai_family = AF_INET
  addrinfo_hints%ai_socktype = SOCK_STREAM
  addrinfo_hints%ai_flags = AI_PASSIVE ! fill in my IP address for me

  ! fill servinfo with getaddrinfo
  servinfo_ptr = c_loc(servinfo)
  rv = c_getaddrinfo(C_NULL_ptr, c_loc(port), c_loc(addrinfo_hints), c_loc(servinfo_ptr))
  if (rv == 1) then
    print *, 'failed to getaddrinfo'
    call exit(1)
  end if

  call c_f_pointer(servinfo_ptr, p)

  do
    if (c_associated(c_loc(p)) .eqv. .false.) then
      print *, 'could not establish socket on any interfaces'
      call exit(1)
    end if
    sockfd = c_socket(p%ai_family, p%ai_socktype, p%ai_protocol)
    if (sockfd == -1) then
      ! could not open socket
      call c_f_pointer(p%ai_next, p)
      cycle
    end if

    res = c_setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, c_loc(yes), c_loc(optlen))
    if (res == -1) then
      print *, 'could not set sockopts despite having created socket'
      call exit(1)
    end if

    res = c_bind(sockfd, p%ai_addr, p%ai_addrlen)
    if (res == -1) then
      print *, 'failed to bind'
      closed = c_close(sockfd)
      call c_f_pointer(p%ai_next, p)
      cycle
    else
      ! bound, we're done, can break out of loop
      exit
    end if
  end do

  res = c_listen(sockfd, backlog)

  if (res /= 0) then
    print *, 'failed to listen'
    res = c_errno()
    if (res == 9) then
      print *, 'socket is not a valid file descriptor', sockfd
    end if
    call exit(1)
  end if

  res = just_handle()
  if (res == 1) then
    print *, 'failed to handle'
    call exit(1)
  end if

  print *, 'waiting for connection on ', sockaddr_port(p%ai_addr)
  do
    newfd = c_accept(sockfd, c_loc(their_addr), c_loc(my_sockaddr_storage_size))

    call c_my_inet_ntop(c_loc(their_addr), c_loc(ipaddrstr), 46)
    call c_f_string(c_loc(ipaddrstr), ipaddrstr)
    print *, 'connection from ', ipaddrstr

    pid = c_fork() 
    if (pid < 0) stop 'fork error'
    if (pid > 0) then
      ! parent
      closed = c_close(newfd)
    else
      ! child
      closed = c_close(sockfd)
      message_len = 13
      sent = c_send(newfd, c_loc(message), message_len, 0)
      closed = c_close(newfd)
      call exit(0)
    endif
  end do

  contains

    integer(c_short) function sockaddr_port(sockaddr_ptr)
      type(c_ptr), value, intent(in) :: sockaddr_ptr
      type(c_sockaddr), pointer :: sa
      type(c_sockaddr_in), pointer :: sa_in
      type(c_sockaddr_in6), pointer :: sa_in6
      integer(c_short) :: port
      call c_f_pointer(sockaddr_ptr, sa)
      if (ichar(sa%sa_family) == AF_INET) then
        call c_f_pointer(sockaddr_ptr, sa_in)
        port = sa_in%sin_port
      else
        call c_f_pointer(sockaddr_ptr, sa_in6)
        port = sa_in6%sin6_port
      end if
      sockaddr_port = c_ntohs(port)
    end function sockaddr_port

end program server
