! $Id: ionization.f90,v 1.29 2003-04-09 13:22:50 brandenb Exp $

!  This modules contains the routines for simulation with
!  simple hydrogen ionization.

module Ionization

  use Cparam
  use Cdata
  use Density

  implicit none

  ! global array for yH (very useful to avoid double calculation and
  ! to allow output along with file), but could otherwise be avoided.
  real, dimension (mx,my,mz) :: yyH=0.5

  !  secondary parameters calculated in initialize
  real :: m_H
  real :: TT_ion,lnrho_ion,ss_ion,chiH
  real :: TT_ion_,lnrho_ion_,chiH_,kappa0

  !  lionization initialized to .true.
  !  it can be reset to .false. in namelist
  logical :: lionization=.true.,output_yH=.false.
  character (len=labellen) :: cionization='hydrogen'

  ! input parameters
  namelist /ionization_init_pars/ cionization,output_yH

  ! run parameters
  namelist /ionization_run_pars/  cionization,output_yH

  contains

!***********************************************************************
    subroutine register_ionization()
!
!   2-feb-03/axel: adapted from Interstellar module
!
      use Cdata
      use Mpicomm, only: stop_it
      use Sub
!
      logical, save :: first=.true.
!
      if (.not. first) call stop_it('register_ionization called twice')
      first = .false.
!
      if ((ip<=8) .and. lroot) then
        print*, 'Register_ionization'
      endif
!
!  identify version number
!
      if (lroot) call cvs_id( &
           "$Id: ionization.f90,v 1.29 2003-04-09 13:22:50 brandenb Exp $")
!
      if (nvar > mvar) then
        if (lroot) write(0,*) 'nvar = ', nvar, ', mvar = ', mvar
        call stop_it('Register_ionization: nvar > mvar')
      endif
!
    endsubroutine register_ionization

!***********************************************************************
    subroutine initialize_ionization()
!
!  Perform any post-parameter-read initialization, e.g. set derived 
!  parameters.
!
!   2-feb-03/axel: adapted from Interstellar module
!
      use Cdata
      use General
!
!  ionization parameters
!  since m_e and chiH, as well as hbar are all very small
!  it is better to divide m_e and chiH separately by hbar.
!
      m_H=m_p+m_e
      chiH=13.6*eV
      chiH_=0.75*eV
      TT_ion=chiH/k_B
      TT_ion_=chiH_/k_B
      lnrho_ion=1.5*log((m_e/hbar)*(chiH/hbar)/2./pi)+log(m_H)
      lnrho_ion_=1.5*log((m_e/hbar)*(chiH_/hbar)/2./pi)+log(m_H)
      ss_ion=k_B/m_H
      kappa0=sigmaH_/m_H
      if(lroot) then
        print*,'initialize_ionization: reference values for ionization'
        print*,'TT_ion',TT_ion
        print*,'lnrho_ion,exp(lnrho_ion)=',lnrho_ion,exp(lnrho_ion)
        print*,'ss_ion=',ss_ion
      endif

    endsubroutine initialize_ionization

!***********************************************************************
    subroutine ionfrac(f)
!
!  calculate degree of ionization
!
!   5-apr-03/axel: coded wrapper routine to set yyH array
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar), intent(in) :: f
      real :: lnrho,ss,yH
      integer :: l
!
      do n=n1,n2
      do m=m1,m2
      do l=l1,l2
         lnrho=f(l,m,n,ilnrho)
         ss=f(l,m,n,ient)
         yH=yyH(l,m,n)
         call rtsafe(lnrho,ss,yH)
         yyH(l,m,n)=yH
      enddo
      enddo
      enddo
!
    endsubroutine ionfrac

!***********************************************************************
    subroutine output_ionization(lun)
!
!  Optional output of derived quantities along with VAR-file
!  Called from wsnap
!
!   5-apr-03/axel: coded
!
      use Cdata
!
      integer, intent(in) :: lun
!
!  identifier
!
      if(lroot.and.headt) print*,'output_ionization',yyH(4,4,4)
      if(output_yH) write(lun) yyH
!
    endsubroutine output_ionization

!***********************************************************************
    subroutine thermodynamics(lnrho,ss,cs2,TT1,cp1tilde,Temperature)
!
!  Calculate thermodynamical quantities, cs2, 1/T, and cp1tilde
!  cs2=(dp/drho)_s is the adiabatic sound speed
!  TT1=1/T is the inverse temperature
!  neutral gas: cp1tilde=ss_ion/cp=0.4 ("nabla_ad" maybe better name)
!  in general: cp1tilde=dlnPdS/dlnPdlnrho
!
!   2-feb-03/axel: simple example coded
!
      use Cdata
      use General
      use Sub
!
      logical, save :: first=.true.
      real, dimension (nx), intent(out), optional :: Temperature
      real, dimension (nx) :: lnrho,ss,cs2,TT1,cp1tilde
      real, dimension (nx) :: dlnPdlnrho,dlnPdss,yH,TT,rho,ee,lnTT
      real :: ss0=-5.5542
!
!  calculate cs2, 1/T, and cp1tilde
!
      if(cionization=='hydrogen') then
        if(headtt.and.first) print*,'thermodynamics based on hydrogen ionization'
        yH=yyH(l1:l2,m,n)
        call ioncalc(lnrho,ss,yH,dlnPdlnrho=dlnPdlnrho, &
                                 dlnPdss=dlnPdss, &
                                 TT=TT)
        TT1=1./TT
        cs2=(1.+yH)*ss_ion*TT*dlnPdlnrho
        cp1tilde=dlnPdss/dlnPdlnrho
        if (ldiagnos.and.i_eth/=0) then
          rho=exp(lnrho)
          ee=1.5*(1.+yH)*ss_ion*TT+yH*ss_ion*TT_ion
          call sum_mn_name(rho*ee,i_eth)
        endif
!
!  neutral gas case: cp-cv=1*kB/mp, ie cp=2.5*kB/mp
!
      elseif(cionization=='neutral') then
        if(headtt.and.first) print*,'thermodynamics: assume cp-cv=1 and cp=2.5'
        dlnPdlnrho=gamma
        dlnPdss=gamma1
        !lnTT=gamma1*(lnrho+ss/ss_ion-ss0)
        lnTT=gamma1*(lnrho+ss-ss0)
        TT=exp(lnTT); TT1=1./TT
        cs2=ss_ion*TT*dlnPdlnrho
        cp1tilde=dlnPdss/dlnPdlnrho
        if(headtt) print*,'thermodynamics: gamma1,lnTT,cs2=',gamma1,lnTT,cs2
        if (ldiagnos.and.i_eth/=0) then
          rho=exp(lnrho)
          ee=cs2/(gamma*gamma1)
          call sum_mn_name(rho*ee,i_eth)
        endif
      endif
      if(present(Temperature)) Temperature=TT
!
      first = .false.
    endsubroutine thermodynamics
!***********************************************************************
    subroutine ioncalc(lnrho,ss,yH,dlnPdlnrho,dlnPdss,TT,kappa)
!
!   calculates thermodynamic quantities under partial ionization
!
!   28-mar-03/tobi: added kappa
!
      real, dimension(nx),intent(in)   :: lnrho,ss,yH
      real, dimension(nx), optional    :: dlnPdlnrho,dlnPdss,TT,kappa
                           intent(out) :: dlnPdlnrho,dlnPdss,TT,kappa
      real, dimension(nx)              :: lnTT_,f  ! lnTT_=log(TT/TT_ion)
      real, dimension(nx)              :: dlnTT_dy,dlnTT_dlnrho,dlnTT_dss
      real, dimension(nx)              :: dfdy,dfdlnrho,dfdss
      real, dimension(nx)              :: dydlnrho,dydss

      if (present(dlnPdlnrho).or.present(dlnPdss) &
           .or.present(TT).or.present(kappa)) then
         lnTT_=gamma1*((ss/ss_ion-1.5*(1.-yH)*log(m_H/m_e) &
                        -1.5*yH*log(m_p/m_e)+(1.-yH)*log(1.-yH) &
                        +2.*yH*log(yH))/(1.+yH)+lnrho-lnrho_ion-2.5)
      endif
      if (present(dlnPdlnrho).or.present(dlnPdss)) then
         f=lnrho_ion-lnrho+1.5*lnTT_-exp(-lnTT_)+log(1.-yH)-2.*log(yH)
         dlnTT_dy=(log(m_H/m_p)-gamma1*(f+exp(-lnTT_))-1.)/(1.+yH)
         dfdy=dlnTT_dy*(1.5+exp(-lnTT_))-1./(1.-yH)-2./yH
      endif

      if (present(dlnPdlnrho)) then
         dlnTT_dlnrho=gamma1
         dfdlnrho=gamma1*exp(-lnTT_)
         dydlnrho=-dfdlnrho/dfdy
         dlnPdlnrho=1.+dydlnrho/(1.+yH)+dlnTT_dy*dydlnrho+dlnTT_dlnrho
      endif

      if (present(dlnPdss)) then
         dlnTT_dss=gamma1/((1.+yH)*ss_ion)
         dfdss=(1.+dfdlnrho)/((1.+yH)*ss_ion)
         dydss=-dfdss/dfdy
         dlnPdss=dydss/(1.+yH)+dlnTT_dy*dydss+dlnTT_dss
      endif

      if (present(TT).or.present(kappa)) TT=exp(lnTT_)*TT_ion

      if (present(kappa)) then
         kappa=.25*exp(lnrho-lnrho_ion_)*(TT_ion_/TT)**1.5 &
               *exp(TT_ion_/TT)*yH*(1.-yH)*kappa0
      endif
    endsubroutine ioncalc
!***********************************************************************
    subroutine rtsafe(lnrho,ss,yH)
!
!   safe newton raphson algorithm (adapted from NR)
!
!   09-apr-03/tobi: changed to subroutine
!
      real, intent (in)    :: lnrho,ss
      real, intent (inout) :: yH
      real                 :: yH0,yH1,dyHold,dyH,fl,fh,f,df,temp
      real, parameter      :: yHacc=1e-5
      integer              :: i
      integer, parameter   :: maxit=100

      yH1=1.-yHacc
      yH0=yHacc
      dyHold=1.-2.*yHacc
      dyH=dyHold
!
!  return if y is too close to 0 or 1
!
      call saha(yH0,lnrho,ss,fh,df)
      if (fh.le.0.) then
         yH=yH0
         return
      endif
      call saha(yH1,lnrho,ss,fl,df)
      if (fl.ge.0.) then
         yH=yH1
         return
      endif
!
!  otherwise find root
!
      call saha(yH,lnrho,ss,f,df)
      do i=1,maxit
         if (((yH-yH0)*df-f)*((yH-yH1)*df-f).gt.0. &
              .or.abs(2.*f).gt.abs(dyHold*df)) then
            dyHold=dyH
            dyH=.5*(yH0-yH1)
            yH=yH1+dyH
            if (yH1.eq.yH) return
         else
            dyHold=dyH
            dyH=f/df
            temp=yH
            yH=yH-dyH
            if (temp.eq.yH) return
         endif
         if (abs(dyH).lt.yHacc) return
         call saha(yH,lnrho,ss,f,df)
         if (f.lt.0.) then
            yH1=yH
         else
            yH0=yH
         endif
      enddo
      print *,'rtsafe: exceeded maximum iterations',f
    endsubroutine rtsafe

!***********************************************************************
    subroutine saha(yH,lnrho,ss,f,df)
!
!   we want to find the root of f
!
!   23-feb-03/tobi: errors fixed
!
      real, intent(in)  :: yH,lnrho,ss
      real, intent(out) :: f,df
      real              :: lnTT_,dlnTT_     ! lnTT_=log(TT/TT_ion)

      lnTT_=gamma1*((ss/ss_ion-1.5*(1.-yH)*log(m_H/m_e) &
                        -1.5*yH*log(m_p/m_e)+(1.-yH)*log(1.-yH) &
                        +2.*yH*log(yH))/(1.+yH)+lnrho-lnrho_ion-2.5)
      f=lnrho_ion-lnrho+1.5*lnTT_-exp(-lnTT_)+log(1.-yH)-2.*log(yH)
      dlnTT_=(log(m_H/m_p)-gamma1*(f+exp(-lnTT_))-1.)/(1.+yH)
      df=dlnTT_*(1.5+exp(-lnTT_))-1./(1.-yH)-2./yH
    endsubroutine saha

endmodule ionization
