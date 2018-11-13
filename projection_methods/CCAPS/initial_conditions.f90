module initial_conditions

  use shared_data
  
  implicit none

  contains

  subroutine set_ic ! NB: nx, t_end etc is set in control.f90

    u = 0.0_num
    v = 0.0_num

  end subroutine set_ic

  subroutine shear_test_ic

    real(num) :: x,y, rho_s, delta_s

    rho_s = 42.0_num
    delta_s = 0.05_num

    do iy = -1,ny+1
    do ix = -1,nx+1
      x = xc(ix)
      y = yc(iy)
      if (y <= 0.5_num) then
        u(ix,iy) =  tanh(rho_s * (y-0.25_num))
      else
        u(ix,iy) = tanh(rho_s * (0.75_num -y))
      endif 
      v(ix,iy) = delta_s * sin(2.0_num * pi * x)
    enddo
    enddo

  end subroutine shear_test_ic

  subroutine minion_test_ic

    real(num) :: x,y

    do iy = -1,ny+1
    do ix = -1,nx+1
      x = xc(ix)
      y = yc(iy)
      u(ix,iy) = 1.0_num - 2.0_num * cos(2.0_num*pi*x)*sin(2.0_num*pi*y)
      v(ix,iy) = 1.0_num + 2.0_num * sin(2.0_num*pi*x)*cos(2.0_num*pi*y)
    enddo
    enddo


    do iy = 1, ny
    do ix = 1, nx
      divu(ix,iy) = (u(ix+1,iy) - u(ix-1,iy))/dx/2.0_num &
        & + (v(ix,iy+1) - v(ix,iy-1))/dy/2.0_num
    enddo
    enddo

    print *,'max numerical divu in ICs',maxval(abs(divu))

  end subroutine minion_test_ic

  subroutine vortex1_test_ic

    real(num) :: x,y, r, theta, x0, y0
    real(num) :: vortex_strength, vortex_rad
    real(num) :: vel_theta
 
    x0 = 0.5_num !use to translate the centering of the vortex
    y0 = 0.5_num 

    vortex_strength = 0.2_num 
    vortex_rad = 0.25_num

    do iy = -1,ny+1
    do ix = -1,nx+1
      x = xc(ix) - x0
      y = yc(iy) - y0
      r = sqrt(x**2 + y**2) 
      theta = atan2(y,x) 
      if (r < vortex_rad) then
        vel_theta = vortex_strength * ( 0.5_num * r - 4.0_num * r**3)
      else
        vel_theta = vortex_strength * ( vortex_rad/r * &
          & (0.5_num * vortex_rad - 4.0_num * vortex_rad**3) )
      endif

      u(ix,iy) = -sin(theta) * vel_theta
      v(ix,iy) =  cos(theta) * vel_theta

    enddo
    enddo

    do iy = 1, ny
    do ix = 1, nx
      divu(ix,iy) = (u(ix+1,iy) - u(ix-1,iy))/dx/2.0_num &
        & + (v(ix,iy+1) - v(ix,iy-1))/dy/2.0_num
    enddo
    enddo

    print *,'max numerical divu in ICs',maxval(abs(divu))

  end subroutine vortex1_test_ic
  ! Helper subroutines may go here! 

end module initial_conditions

