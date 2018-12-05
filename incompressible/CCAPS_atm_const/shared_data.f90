module shared_data

  implicit none

  !intrinsics 

  integer :: out_unit = 10
  integer, parameter :: num=selected_real_kind(p=15) 

  ! test setups 

  logical :: use_minmod = .false. 
  logical :: shear_test = .false.
  logical :: minion_test = .false.
  logical :: vardens_adv_test = .false.
  logical :: rti1_test = .false.
  logical :: blob1_test = .false.

  ! core solver

  integer :: nx, ny
  integer :: ix, iy
  integer :: step, nsteps
  integer :: dumpfreq


  real(num) :: time = 0.0_num, t_end, dt
  real(num) :: dt_snapshot = 1e14_num, next_dump
  real(num) :: CFL
  real(num) :: x_min, x_max
  real(num) :: y_min, y_max
  real(num) :: dx, dy


  real(num), dimension(:), allocatable :: xc, xb, yc, yb

  real(num), dimension(:,:), allocatable :: u, v, p
  real(num), dimension(:,:), allocatable :: uhxl, uhxr, vhxl, vhxr
  real(num), dimension(:,:), allocatable :: uhyl, uhyr, vhyl, vhyr

  real(num), dimension(:,:), allocatable :: uha, vha
  real(num), dimension(:,:), allocatable :: uhx, vhx, uhy, vhy


  real(num), dimension(:,:), allocatable :: uxl, uxr, vxl, vxr
  real(num), dimension(:,:), allocatable :: uyl, uyr, vyl, vyr

  real(num), dimension(:,:), allocatable :: ua, va
  real(num), dimension(:,:), allocatable :: macu, macv

  real(num), dimension(:,:), allocatable :: ux, vx, uy, vy !u on x face, v on x face..
  real(num), dimension(:,:), allocatable :: divu ! divergence of MAC, cc

  real(num), dimension(:,:), allocatable :: phi !cc 

  real(num), parameter :: pi = 4.0_num * ATAN(1.0_num)

  real(num), dimension(:,:), allocatable :: ustar, vstar


  real(num), dimension(:,:), allocatable :: gradp_x, gradp_y ! pressure gradient, cc

  ! variable density

  real(num), dimension(:,:), allocatable :: rho, rho_old
  real(num), dimension(:,:), allocatable :: rhohxl, rhohxr !rho-hat-x-left / right
  real(num), dimension(:,:), allocatable :: rhohyl, rhohyr
  real(num), dimension(:,:), allocatable :: rhohx, rhohy ! upwinded rhohats on x and y face
  real(num), dimension(:,:), allocatable :: rhoxl, rhoxr ! full states on left and right
  real(num), dimension(:,:), allocatable :: rhoyl, rhoyr ! full states on left and right
  real(num), dimension(:,:), allocatable :: rhox, rhoy !resolved full states on faces

  real(num) :: grav_y = 0.0_num

  ! fixed background state 

  real(num), dimension(:), allocatable :: rho0
  real(num), dimension(:), allocatable :: p0

  real(num), dimension(:,:), allocatable :: eta_arr

  real(num) :: gamma

  ! boundary conditions 

  integer :: bc_xmin , bc_xmax, bc_ymin, bc_ymax

  integer, parameter :: periodic = 0
  integer, parameter :: zero_gradient = 1
  integer, parameter :: no_slip = 2
  integer, parameter :: dirichlet = 3

end module shared_data
