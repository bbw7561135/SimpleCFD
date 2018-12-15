module multigrid

  implicit none

  private
  public :: mg_interface

  ! will need own private constants and parameters since entirely modular
  integer, parameter :: num=selected_real_kind(p=15)

  integer :: ix, iy

  ! data object
  type grid
    integer :: level, nx, ny  
    real(num) :: dx, dy
    real(num),dimension(:,:), allocatable :: phi
    real(num),dimension(:,:), allocatable :: f
    real(num),dimension(:,:), allocatable :: residue
    type(grid), pointer :: next, prev
  end type grid

  type(grid), pointer :: head, tail

  ! boundary conditions. The program calling mg_interface
  ! is responsible for getting the integers correct
  integer :: bc_xmin , bc_xmax, bc_ymin, bc_ymax
  integer, parameter :: periodic = 0
  integer, parameter :: zero_gradient = 1
  integer, parameter :: no_slip = 2
  integer, parameter :: driven = 3

contains

  subroutine mg_interface(f, phi, tol, nx,ny,dx,dy, nlevels, &
        & bc_xmin, bc_xmax, bc_ymin, bc_ymax)
    real(num), dimension(:,:), intent(in) :: f
    real(num), dimension(:,:), allocatable, intent(inout) :: phi
    integer, intent(in) :: nx 
    integer, intent(in) :: ny
    integer, intent(inout) :: nlevels
    real(num), intent(in) :: dx, dy
    real(num), intent(in) :: tol
    integer, intent(in) :: bc_xmin, bc_xmax, bc_ymin, bc_ymax
    type(grid), pointer :: current 
    real(num) :: start, finish


    call sanity_checks(f=f, phi=phi, nx=nx,ny=ny,nlevels=nlevels,dx=dx,dy=dy) !*

    call initialise_grids(f=f, nx=nx,ny=ny,nlevels=nlevels,dx=dx,dy=dy) !*

    print *,'*** Multigrid called'
    print *,'****** nx = ',nx
    print *,'****** ny = ',ny
    print *,'****** nlevels ',nlevels
    print *,'****** tolerance = ',tol

    call cpu_time(start)
    call mg_solve(tol)
    call cpu_time(finish)
    print '(" ****** cpu_time: ",f20.3," seconds.")',finish-start

    ! set the inout(phi) = phi on finest grid to return to caller
    current => head
    phi = current%phi 

    print *,'*** Multigrid finished'

  end subroutine mg_interface

!* in  practice, in CCAPS / multistep hydro codes might want to "first
!  call" this only to keep
!  them all allocated throughout .. not sure yet how that will work so
!  keep this comment till it pans out

  ! main solver

  subroutine mg_solve(tol)
    real(num), intent(in) :: tol
    type(grid), pointer :: current

    real(num) :: L2, L2_old
    
    integer :: nsteps
    integer :: c
    integer :: num_sweeps_down = 3
    integer :: num_sweeps_up = 3

    L2_old = 1e6_num
    current => head

    nsteps = 0

    mainloop: do
      nsteps = nsteps +1

      downcycle: do
        if (current%level == tail%level) exit downcycle

        if (current%level /= 1) current%phi = 0.0_num ! important

        do c = 1, num_sweeps_down
          call relax(current) 
        enddo

        if (current%level == 1) then
          call residual(current) 
          L2 = sqrt(sum(abs(current%residue)**2)/real(current%nx*current%ny,num))
          if (abs(L2-L2_old) <= tol) exit mainloop
          L2_old = L2
        endif
        call residual(current)
        call restrict(current) 
        current=>current%next

      enddo downcycle

      bottom_solve: do

        current%phi = 0.0_num

        do c = 1, 50 !**
          call relax(current)
          if (modulo(c-1,5)==0) then          
            call residual(current)
            L2 = sqrt(sum(abs(current%residue)**2)/real(current%nx*current%ny,num))
            if (L2 < tol) exit
          endif
        enddo
        call inject(current)
        current => current%prev
        exit bottom_solve !not really a loop / readability. Possible performance hit?

      enddo bottom_solve

      upcycle: do
        if (current%level == 1) exit upcycle
        do c = 1, num_sweeps_up
          call relax(current)
        enddo
        call inject(current)
        current => current%prev
      enddo upcycle

    enddo mainloop
    
    print '(" ****** Finished in: ",i3.3," V cycles")',nsteps
    print '(" ****** Fine grid residual: ",e20.8," (L2)")',L2 

    !** if not refining to ideal case (nx=ny=1 + ghosts) this wont automagically
    ! be solved exactly (discretely). If so, do an arbitary amount of
    ! relaxations, checking the residual, up to a max of 50. Perhaps in some
    ! problems, if you can't refine very much because of a large Lx/=Ly asoect
    ! ratio, this could cause an issue
  end subroutine mg_solve

  subroutine gs_solve ! for comparison

    type(grid), pointer :: current
                        
    real(num) :: L2, L2_old

    integer :: nsteps 
                        
    L2_old = 1e6_num 
    current => head  
    nsteps = 0                        
    do        
      nsteps = nsteps + 1       
      call relax(current) 
      call residual(current)
                        
      L2 = sqrt(sum(abs(current%residue)**2)/real(current%nx*current%ny,num))
      if (abs(L2-L2_old) < 1e-12_num) exit ! should replace with user chosen tol eventually
      L2_old = L2       
    enddo               
                    
    print *,'nsteps',nsteps
  end subroutine gs_solve

  subroutine mg_2level_solve(tol) ! for debugging, dont call with more than 2 levels
    real(num), intent(in) :: tol
    type(grid), pointer :: current

    real(num) :: L2, L2_old
    
    integer :: nsteps
    integer :: c
    integer :: num_sweeps_down = 3

    L2_old = 1e6_num
    current => head

    nsteps = 0

    mainloop: do
      nsteps = nsteps +1

      downcycle: do
        if (current%level == tail%level) exit

        do c = 1, num_sweeps_down
          call relax(current) 
        enddo

        if (current%level == 1) then
          call residual(current) 
          L2 = sqrt(sum(abs(current%residue)**2)/real(current%nx*current%ny,num))
          if (abs(L2-L2_old) <= tol) exit mainloop
          L2_old = L2
        endif
        call residual(current)
        call restrict(current) 
        current=>current%next

      enddo downcycle


      ! bottom solve
      do c = 1, 50 ! for now only 
        call relax(current)
      enddo
      call inject(current)
      current => current%prev

      ! upcycle goes here , currently unnecessary as two level

    enddo mainloop

  print *,'nsteps',nsteps

  end subroutine mg_2level_solve

  ! methods used in the main solver

  subroutine restrict(this)
    ! restrict the residual at level "this" (this%residue)
    ! to be the rhs of the next level (next%f) 

    type(grid), pointer :: this
    type(grid), pointer :: next
    integer :: ixc, iyc

    next => this%next

    iy=  1
    do iyc = 1, next%ny 
    ix = 1
    do ixc = 1, next%nx
      next%f(ixc,iyc) = 0.25_num * (this%residue(ix,iy) + this%residue(ix+1,iy) &
        & + this%residue(ix,iy+1) + this%residue(ix+1,iy+1) ) 
      ix = ix + 2 
    enddo
    iy = iy + 2 
    enddo

  end subroutine restrict

  subroutine inject(this)

    type(grid), pointer :: this
    type(grid), pointer :: prev
    integer :: ixc, iyc
    prev => this%prev

    iy=  1                   
    do iyc = 1, this%ny         
    ix = 1                
    do ixc = 1, this%nx         
      prev%phi(ix,iy) = prev%phi(ix,iy) - this%phi(ixc,iyc)
      prev%phi(ix+1,iy) = prev%phi(ix+1,iy) - this%phi(ixc,iyc)
      prev%phi(ix,iy+1) = prev%phi(ix,iy+1) - this%phi(ixc,iyc)
      prev%phi(ix+1,iy+1) = prev%phi(ix+1,iy+1) - this%phi(ixc,iyc)
      ix = ix + 2            
    enddo                    
    iy = iy + 2              
    enddo  

  end subroutine inject


  subroutine relax(this)

    type(grid), pointer :: this
    integer :: odd_then_even

    call bcs(this)

    ! redblack / odd

    red_blk: do odd_then_even = 1, 0, -1 
      do iy = 1, this%ny  
      do ix = 1, this%nx  
        if (modulo(ix+iy,2) == odd_then_even) then
          this%phi(ix,iy) = 0.25_num * ( & 
            & this%phi(ix+1,iy) + this%phi(ix-1,iy) + this%phi(ix,iy+1) + this%phi(ix,iy-1) &
            - this%dx**2 * this%f(ix,iy) ) 
        endif
      end do
      end do 
    enddo red_blk

  end subroutine relax

  subroutine residual(this)

    type(grid), pointer :: this 

    real(num) :: Lap ! 5 point discrete laplacian at a cell center 

    call bcs(this)

    do iy = 1, this%ny   
    do ix = 1, this%nx   
      Lap = (this%phi(ix+1,iy) - 2.0_num*this%phi(ix,iy) + this%phi(ix-1,iy)) / this%dx**2 + & 
          & (this%phi(ix,iy+1) - 2.0_num*this%phi(ix,iy) + this%phi(ix,iy-1)) / this%dy**2 
      this%residue(ix,iy) = Lap - this%f(ix,iy)
    enddo              
    enddo        


  end subroutine residual

  subroutine bcs(this)

    type(grid), pointer :: this

    ! some logic for if level 1 vs others for homo vs inhomo bc etc will be needed 
    ! eventually

    if (bc_xmin == periodic) then
      this%phi(0,:) = this%phi(this%nx,:)
    endif
    if (bc_xmax == periodic) then
      this%phi(this%nx+1,:) = this%phi(1,:)
    endif
    if (bc_xmin == periodic) then
      this%phi(:,0) = this%phi(:,this%ny)
    endif
    if (bc_xmax == periodic) then
      this%phi(:,this%ny+1) = this%phi(:,1)
    endif

    if (bc_xmin == zero_gradient) then
      this%phi(0,:) = this%phi(1,:)
    endif
    if (bc_xmax == zero_gradient) then
      this%phi(this%nx+1,:) = this%phi(this%nx,:)
    endif
    if (bc_ymin == zero_gradient) then
      this%phi(:,0) = this%phi(:,1)
    endif
    if (bc_ymax == zero_gradient) then
      this%phi(:,this%ny+1) = this%phi(:,this%ny)
    endif

    if (bc_xmin == no_slip) then
      this%phi(0,:) = this%phi(1,:)
    endif
    if (bc_xmax == no_slip) then
      this%phi(this%nx+1,:) = this%phi(this%nx,:)
    endif
    if (bc_ymin == no_slip) then
      this%phi(:,0) = this%phi(:,1)
    endif
    if ((bc_ymax == no_slip) .or. (bc_ymax == driven)) then
      this%phi(:,this%ny+1) = this%phi(:,this%ny)
    endif


  end subroutine bcs


  ! check everything passed to the interface is as assumed

  subroutine sanity_checks(f,phi, nx,ny,dx,dy,nlevels)
    integer, intent(in) :: nx
    integer, intent(in) :: ny
    real(num), dimension(:,:), intent(in) :: f
    real(num), dimension(:,:), allocatable, intent(inout) :: phi
    integer, intent(in) :: nlevels
    real(num), intent(in) :: dx, dy

    if (dx /= dy) then
      print *,'multigrid: dx =/ dy, terminating'
      stop
    endif

    if (size(f,1) /= nx) then 
      print *, 'wrong size on f input'
      print *,'size(f,1)=',size(f,1)
      stop
    endif 

    if (size(f,2) /= ny) then 
      print *, 'wrong size on f input'
      print *,'size(f,2)=',size(f,2)
      stop
    endif 

    if (lbound(f,1) /= 1) then 
      print *, 'wrong lbound on allocatable f input to MG'
      print *,'lbound(f,1)=',lbound(f,1)
      stop
    endif 

    if (lbound(f,2) /= 1) then 
      print *, 'wrong lbound on allocatable f input to MG'
      print *,'lbound(f,2)=',lbound(f,2)
      stop
    endif 

    if (ubound(f,1) /= nx) then 
      print *, 'wrong ubound on allocatable f input to MG'
      print *,'ubound(f,1)=',ubound(f,1)
      stop
    endif 

    if (ubound(f,2) /= ny) then 
      print *, 'wrong ubound on allocatable f input to MG'
      print *,'ubound(f,2)=',ubound(f,2)
      stop
    endif 

    if (lbound(phi,1) /= -1) then 
      print *, 'wrong lbound on allocatable phi input to MG'
      print *,'lbound(phi,1)=',lbound(phi,1)
      stop
    endif 

    if (lbound(phi,2) /= -1) then 
      print *, 'wrong lbound on allocatable phi input to MG'
      print *,'lbound(phi,2)=',lbound(phi,2)
      stop
    endif 

    if (ubound(phi,1) /= nx+2) then 
      print *, 'wrong ubound on allocatable phi input to MG'
      print *,'ubound(phi,1)=',ubound(phi,1)
      stop
    endif 

    if (ubound(phi,2) /= ny+2) then 
      print *, 'wrong ubound on allocatable phi input to MG'
      print *,'ubound(phi,2)=',ubound(phi,2)
      stop
    endif 

  end subroutine sanity_checks

  ! Methods relating to the grid heirarchy and setup below jere

  subroutine create_grid(new_grid)
    type(grid), pointer :: new_grid
    allocate(new_grid)
    nullify(new_grid%next)
    nullify(new_grid%prev)
    new_grid%level = -1
    new_grid%nx = -1
    new_grid%ny = -1
    new_grid%dx = -1.0_num
    new_grid%dy = -1.0_num
  end subroutine create_grid

  subroutine add_grid(new_grid)
    ! add grid to a list / create a new list if 1st one
    type(grid), pointer :: new_grid
    if (.not. associated(head)) then
      head=>new_grid
      tail=>new_grid
      return
    endif
    tail%next=>new_grid
    new_grid%prev=>tail
    tail=>new_grid
  end subroutine add_grid

  subroutine allocate_arrays(new_grid)
    type(grid), pointer :: new_grid
    allocate(new_grid%phi(0:new_grid%nx+1,0:new_grid%ny+1))
    allocate(new_grid%f(1:new_grid%nx,1:new_grid%ny))
    allocate(new_grid%residue(1:new_grid%nx,1:new_grid%ny))
    new_grid%phi = 0.0_num
    new_grid%f = 0.0_num
    new_grid%residue = 0.0_num
  end subroutine allocate_arrays

  subroutine grid_report(this)
    type(grid), pointer :: this
      print *,'******'
      print *,'level',this%level
      print *,'nx',this%nx
      print *,'ny',this%ny
      print *,'dx',this%dx
      print *,'dy',this%dy
      print *,'lbound phi',lbound(this%phi)
      print *,'ubound phi',ubound(this%phi)
      print *,'lbound f',lbound(this%f)
      print *,'ubound f',ubound(this%f)
      print *,'******'
  end subroutine grid_report

  subroutine initialise_grids(f,nx,ny,dx,dy, nlevels)

    real(num), dimension(:,:), intent(in) :: f
    integer, intent(in) :: nx
    integer, intent(in) :: ny
    integer, intent(inout) :: nlevels
    real(num), intent(in) :: dx, dy
    integer :: lev

    type(grid), pointer :: new
    type(grid), pointer :: current
    nullify(new)
    nullify(current)
    nullify(head)
    nullify(tail)

    if (nlevels == -1) nlevels = set_nlevels(nx,ny)

    ! create a linked list of grids with blank / unallocated data
    do lev = 1, nlevels
      call create_grid(new)
      call add_grid(new)
    enddo

    ! go through the list and set up the arrays 
    current =>head
    lev = 0
    do while(associated(current))
      lev = lev + 1
      current%level = lev 
      current%nx = nx / (2**(lev-1)) 
      current%ny = ny / (2**(lev-1)) 
      current%dx = dx * real(2**(lev-1),num) 
      current%dy = dy * real(2**(lev-1),num)
      call allocate_arrays(current)
      current=>current%next
    enddo

! add to a debug / verbose option
!    ! cycle through the list for a report to check all is set up good
!    current => head
!    do while(associated(current))
!      call grid_report(current)
!      current=>current%next
!    enddo 

    ! set phi and f on the level-1 (finest) grid 
    current => head
    current%f = f
    current%phi = 0.0_num 

  end subroutine initialise_grids

  integer function set_nlevels(nx,ny)
    integer, intent(in) :: nx, ny

    if (nx <= ny) then
      set_nlevels = log2_int(nx) + 1 
    else
      set_nlevels = log2_int(nx) + 1
    endif

  end function set_nlevels

  real(num) function log2_int(x)
    implicit none
    integer, intent(in) :: x

    log2_int = int( log(real(x,num)) / log(2.0_num))

  end function log2_int


end module multigrid

