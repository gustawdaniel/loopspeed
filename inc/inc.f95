PROGRAM loop_argument_times
  INTEGER(16) :: i, range
  CHARACTER(len=32) :: arg

  CALL get_command_argument(1, arg)
  read( arg, '(i16)' ) range

  do  i = 1, range
  ! WRITE (*,*) i
  end do

END PROGRAM