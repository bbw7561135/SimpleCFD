module boundary_conditions

  use shared_data

  implicit none

  private

  public :: velocity_bcs, phi_bcs

  contains

  subroutine velocity_bcs
    ! Currently hard-coded as doubly-periodic
    ! (this is suitable for the test problem)

    u(0,:) = u(nx,:)
    u(-1,:) = u(nx-1,:)
    u(nx+1,:) = u(1,:)
    u(nx+1,:) = u(2,:)
    u(:,0) = u(:,ny)
    u(:,-1) = u(:,ny-1)
    u(:,ny) = u(:,1)
    u(:,ny+1) = u(:,2)

    v(0,:) = v(nx,:)
    v(-1,:) = v(nx-1,:)
    v(nx+1,:) = v(1,:)
    v(nx+1,:) = v(2,:)
    v(:,0) = v(:,ny)
    v(:,-1) = v(:,ny-1)
    v(:,ny) = v(:,1)
    v(:,ny+1) = v(:,2)

  end subroutine velocity_bcs

  subroutine phi_bcs
    ! the relaxation only needs 1 ghost
    phi(0,:) = phi(nx,:)
    phi(nx+1,:) = phi(1,:)
    phi(:,0) = phi(:,ny)
    phi(:,ny+1) = phi(:,1)   

  end subroutine phi_bcs


end module boundary_conditions

