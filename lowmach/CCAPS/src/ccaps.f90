! CCAPS - Cell-centered approximate projection solver

program ccaps

  use shared_data
  use setup
  use advance_module
  use diagnostics
  use welcome

  implicit none 

  call welcome_msg

  call initial_setup

  next_dump = 0.0_num !dt_snapshot

  do
    step = step + 1
    if ((step > nsteps .and. nsteps >= 0) .or. (time >= t_end)) exit

    print *,'******************************************************************'
    print *,'Cycle: ', step, 'Time: ',time
    print *,'******************************************************************'

    call advance_dt
    if ( step ==0 ) call bootstrap 

    ! special diagnostics
    if (minion_test) call test_minion
    if (drivenlid_test) call test_steady
    if (use_vardens) print *, 'rho on grid',sum(rho(1:nx,1:ny)*dx*dy)

    ! periodic dumps 
    if ( (modulo(step,dumpfreq) == 0) .and. (dumpfreq > 0) ) call sln_plots
    if ( time >= next_dump) then
      call sln_plots  
      next_dump = next_dump + dt_snapshot
    endif 
  enddo 

  if (minion_test) then 
    call minion_plots
  else 
    call sln_plots
  endif


  print *, 'CCAPS Terminated Normally'
end program ccaps
