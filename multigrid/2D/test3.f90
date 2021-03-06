program test3

  use multigrid

  implicit none

  integer, parameter :: num=selected_real_kind(p=15)
!  real(num) :: pi = 4.0_num * ATAN(1.0_num)

  integer :: nx, ny, ix, iy

  real(num) :: dx, dy, L2, x_min, x_max, y_min, y_max

  real(num), dimension(:), allocatable :: xc, yc
  real(num), dimension(:,:), allocatable :: f,analytic, phi, eta
  real(num), dimension(:), allocatable :: L2_arr, n_arr

  integer :: power, power_min, power_max

  type(mg_input) :: input

  ! setup a test problem 

  
  print *,'Test3: As test two but for D(eta G(phi)) = f with eta=1 uniformly'

  power_min = 3
  power_max = 10

  allocate(L2_arr(1:1+power_max-power_min))
  allocate(n_arr(1:1+power_max-power_min))
  L2_arr = 1e6_num
  n_arr = 0

  different_resolutions: do power= power_min, power_max

    nx = 2**power 
    ny = nx
    x_min = 0.0_num
    x_max = 1.0_num
    y_min = x_min
    y_max = x_max
  
    allocate(xc(-1:nx+2))
    allocate(yc(-1:ny+2))
  
    dx = (x_max - x_min) / real(nx,num)
    xc(-1) = x_min - 3.0_num * dx / 2.0_num 
    do ix = 0,nx+2
      xc(ix) = xc(ix-1) + dx
    enddo
  
    dy = (y_max - y_min) / real(ny,num)
    yc(-1) = y_min - 3.0_num * dy / 2.0_num 
    do iy = 0,ny+2
      yc(iy) = yc(iy-1) + dy
    enddo
  
    allocate(phi(-1:nx+2,-1:ny+2)) ! again, redundant ghosts but for comparison to CCAPS
    phi = 0.0_num 
  
    allocate(analytic(1:nx,1:ny)) ! again, redundant ghosts but for comparison to CCAPS
    analytic = 0.0_num 
  
  
    allocate(f(1:nx,1:ny))
   
    do iy = 1, ny
    do ix = 1, nx
      f(ix,iy) = -2.0_num * ((1.0_num-6.0_num*xc(ix)**2)*(yc(iy)**2)*(1.0_num-yc(iy)**2) &
        & + (1.0_num-6.0_num*yc(iy)**2)*(xc(ix)**2)*(1.0_num-xc(ix)**2))
    enddo
    enddo
  
    allocate(eta(1:nx,1:ny)) ! again, redundant ghosts but for comparison to CCAPS
    eta = 1.0_num 
  
    ! solve for phi


  input = mg_input(tol = 1e-12_num, nx=nx, ny = ny, dx=dx, dy=dy, f = f, phi = phi, &
            & bc_xmin = 'fixed', bc_ymin='fixed', bc_xmax='fixed', bc_ymax = 'fixed', &
            & deallocate_after = .true., &
            & eta = eta, eta_present = .true., & 
! as eta=1 uniformly, zero gradient is equivalent to dirichlet with eta=1
!            & eta_bc_xmin = 'zero_gradient', eta_bc_ymin='zero_gradient', &
!            & eta_bc_xmax='zero_gradient', eta_bc_ymax = 'zero_gradient')
! fixed shouldn't really work atm, since inhomo fixed eta not implemented
!its just because inside MG code eta_bc = fixed 
! actually defaults to zero_grad which is a BS hack thats came back to bite me 
! and needs fixed in general
             & eta_bc_xmin = 'fixed', eta_bc_ymin='fixed', &
             & eta_bc_xmax='fixed', eta_bc_ymax = 'fixed', &
             & etaval_bc_xmin = 1.0_num, etaval_bc_ymin = 1.0_num, &
             & etaval_bc_xmax = 1.0_num, etaval_bc_ymax = 1.0_num)

  call mg_interface(input)

  phi = input%phi

    ! test against analytical solution
     
    do iy = 1, ny
    do ix = 1, nx
      analytic(ix,iy) = (xc(ix)**2-xc(ix)**4) * (yc(iy)**4-yc(iy)**2)
    enddo
    enddo
  
    L2 = sqrt(sum(abs(analytic(1:nx,1:ny)-phi(1:nx,1:ny))**2) / real(nx*ny,num))
    
    print *,'L2',L2
 
    L2_arr(power-power_min+1) = L2
    n_arr(power-power_min+1) = real(nx,num)

 
    ! deallocate all so can do again
  
    deallocate(xc)
    deallocate(yc)
    deallocate(f)
    deallocate(phi)
    deallocate(analytic)
    deallocate(eta)

  enddo different_resolutions

  print *, 'L2 _arr',L2_arr
  print *, 'n _arr',n_arr

  call execute_command_line("rm -rf test3_l2.dat")
  call execute_command_line("rm -rf test3_nx.dat")

  open(10, file="test3_l2.dat", access="stream")
  write(10) L2_arr
  close(10)

  open(10, file="test3_nx.dat", access="stream")
  write(10) n_arr
  close(10)

  call execute_command_line("python test3_plots.py")
  call execute_command_line("rm test3_l2.dat")
  call execute_command_line("rm test3_nx.dat")


end program test3
