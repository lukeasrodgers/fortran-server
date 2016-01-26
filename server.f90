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

    call my_inet_ntop(their_addr, ipaddrstr)
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

    subroutine my_inet_ntop(their_addr, buff)
      type(c_sockaddr_storage), target, intent(in) :: their_addr
      character(len=INET6_ADDRSTRLEN), target, intent(out) :: buff
      character(kind=c_char,len=1), target :: c_buff(INET6_ADDRSTRLEN)

      type(c_sockaddr), pointer :: sa
      type(c_sockaddr_in_resized), pointer :: sa_in
      type(c_sockaddr_in6), pointer :: sa_in6

      type(C_void_ptr) :: res

      call c_f_pointer(c_loc(their_addr), sa)
      if (ichar(sa%sa_family) == AF_INET) then
        call c_f_pointer(c_loc(their_addr), sa_in)
        res = c_inet_ntop(ichar(their_addr%ss_family), c_loc(sa_in%sin_addr), c_loc(c_buff), INET6_ADDRSTRLEN)
      else
        call c_f_pointer(c_loc(their_addr), sa_in6)
        res = c_inet_ntop(ichar(their_addr%ss_family), c_loc(sa_in6%sin6_addr), c_loc(c_buff), INET6_ADDRSTRLEN)
      end if

      call c_f_string(c_buff, buff)
    end subroutine my_inet_ntop

end program server
