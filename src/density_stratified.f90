! $Id$
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: ldensity = .true.
! CPARAM logical, parameter :: lanelastic = .false.
! CPARAM logical, parameter :: lboussinesq = .false.
! CPARAM logical, parameter :: lstratified = .true.
!
! MVAR CONTRIBUTION 1
! MAUX CONTRIBUTION 0
!
! PENCILS PROVIDED rhos; rhos1
! PENCILS PROVIDED grhos(3); glnrhos(3); ugrhos
!
! PENCILS PROVIDED rho; rho1
! PENCILS PROVIDED grho(3); glnrho(3)
! PENCILS PROVIDED ekin
!
! PENCILS PROVIDED lnrho
! PENCILS PROVIDED ugrho; uglnrho
! PENCILS PROVIDED transprho
! PENCILS PROVIDED del2rho; del2lnrho; del6lnrho
! PENCILS PROVIDED hlnrho(3,3)
! PENCILS PROVIDED uij5glnrho(3); sglnrho(3)
!
!***************************************************************
module Density
!
  use Cparam
  use Cdata
  use EquationOfState, only: beta_glnrho_global
  use General, only: keep_compiler_quiet
  use Messages
!
  implicit none
!
  include 'density.h'
!
  public :: get_density_z
!
  character(len=labellen), dimension(ninit) :: initrho = 'nothing'
  real, dimension(ninit) :: amplrho = 0.0
  real, dimension(mz), target :: rho0z
  real, dimension(mz) :: dlnrho0dz
  character(len=8) :: zstrat = 'none'
  logical :: ldiff_shock = .false.
  logical :: ldiff_hyper3_mesh = .false.
  real :: nu_epicycle = 1.0
  real :: density_floor = 0.0
  real :: diffrho_shock = 0.0
  real :: diffrho_hyper3_mesh = 0.0
!
  namelist /density_init_pars/ zstrat, nu_epicycle, initrho, amplrho, beta_glnrho_global
!
  namelist /density_run_pars/ density_floor, diffrho_hyper3_mesh, diffrho_shock
!
!  Diagnostic Variables
!
  integer :: idiag_mass = 0     ! DIAG_DOC: $\int\rho\,d^3x$
  integer :: idiag_rhomin = 0   ! DIAG_DOC: $\min\left|\rho\right|$
  integer :: idiag_rhomax = 0   ! DIAG_DOC: $\max\left|\rho\right|$
  integer :: idiag_drhom = 0    ! DIAG_DOC: $\langle\Delta\rho/\rho_0\rangle$
  integer :: idiag_drho2m = 0   ! DIAG_DOC: $\langle\left(\Delta\rho/\rho_0\right)^2\rangle$
  integer :: idiag_drhorms = 0  ! DIAG_DOC: $\langle\Delta\rho/\rho_0\rangle_{rms}$
  integer :: idiag_drhomax = 0  ! DIAG_DOC: $\max\left|\Delta\rho/\rho_0\right|$
!
!  xy-averages
!
  integer :: idiag_drhomz = 0    ! XYAVG_DOC: $\langle\Delta\rho/\rho_0\rangle_{xy}$
  integer :: idiag_drho2mz = 0   ! XYAVG_DOC: $\langle\left(\Delta\rho/\rho_0\right)^2\rangle_{xy}$
  integer :: idiag_rux2mz = 0    ! YZAVG_DOC: $\langle\rho u_x^2\rangle_{xy}$
  integer :: idiag_ruy2mz = 0    ! YZAVG_DOC: $\langle\rho u_y^2\rangle_{xy}$
  integer :: idiag_ruz2mz = 0    ! YZAVG_DOC: $\langle\rho u_z^2\rangle_{xy}$
  integer :: idiag_ruxuymz = 0   ! YZAVG_DOC: $\langle\rho u_x u_y\rangle_{xy}$
  integer :: idiag_ruxuzmz = 0   ! YZAVG_DOC: $\langle\rho u_x u_z\rangle_{xy}$
  integer :: idiag_ruyuzmz = 0   ! YZAVG_DOC: $\langle\rho u_y u_z\rangle_{xy}$
!
!  xz-averages
!
  integer :: idiag_drhomy = 0    ! XZAVG_DOC: $\langle\Delta\rho/\rho_0\rangle_{xz}$
  integer :: idiag_drho2my = 0   ! XZAVG_DOC: $\langle\left(\Delta\rho/\rho_0\right)^2\rangle_{xz}$
!
!  yz-averages
!
  integer :: idiag_drhomx = 0    ! YZAVG_DOC: $\langle\Delta\rho/\rho_0\rangle_{yz}$
  integer :: idiag_drho2mx = 0   ! YZAVG_DOC: $\langle\left(\Delta\rho/\rho_0\right)^2\rangle_{yz}$
  integer :: idiag_rux2mx = 0    ! YZAVG_DOC: $\langle\rho u_x^2\rangle_{yz}$
  integer :: idiag_ruy2mx = 0    ! YZAVG_DOC: $\langle\rho u_y^2\rangle_{yz}$
  integer :: idiag_ruz2mx = 0    ! YZAVG_DOC: $\langle\rho u_z^2\rangle_{yz}$
  integer :: idiag_ruxuymx = 0   ! YZAVG_DOC: $\langle\rho u_x u_y\rangle_{yz}$
  integer :: idiag_ruxuzmx = 0   ! YZAVG_DOC: $\langle\rho u_x u_z\rangle_{yz}$
  integer :: idiag_ruyuzmx = 0   ! YZAVG_DOC: $\langle\rho u_y u_z\rangle_{yz}$
!
!  y-averages
!
  integer :: idiag_drhomxz = 0   ! YAVG_DOC: $\langle\Delta\rho/\rho_0\rangle_y$
  integer :: idiag_drho2mxz = 0  ! YAVG_DOC: $\langle\left(\Delta\rho/\rho_0\right)^2\rangle_y$
!
!  z-averages
!
  integer :: idiag_drhomxy = 0   ! ZAVG_DOC: $\langle\Delta\rho/\rho_0\rangle_z$
  integer :: idiag_drho2mxy = 0  ! ZAVG_DOC: $\langle\left(\Delta\rho/\rho_0\right)^2\rangle_z$
  integer :: idiag_sigma = 0     ! ZAVG_DOC; $\Sigma\equiv\int\rho\,\mathrm{d}z$
!
!  Dummy Variables
!
  real, dimension(nz) :: glnrhomz = 0.0
  logical :: lcalc_glnrhomean = .false.
  logical :: lupw_lnrho = .false.
!
  contains
!***********************************************************************
    subroutine register_density()
!
!  Register Density module.
!
!  28-feb-13/ccyang: coded.
!
      use FArrayManager, only: farray_register_pde
!
!  Register relative density as dynamical variable rho.
!
      call farray_register_pde('rho', irho)
!
!  This module conflicts with Gravity module.
!
      if (lgrav) call fatal_error('register_density', 'conflicting with Gravity module. ')
!
!  This module does not consider logarithmic density.
!
      ldensity_nolog = .true.
!
!  Identify version number.
!
      if (lroot) call svn_id("$Id$")
!
    endsubroutine register_density
!***********************************************************************
    subroutine initialize_density(f, lstarting)
!
!  Perform any post-parameter-read initialization i.e. calculate derived
!  parameters.
!
!  20-may-13/ccyang: coded.
!
      use EquationOfState, only: select_eos_variable
      use SharedVariables, only: put_shared_variable
!
      real, dimension(mx,my,mz,mfarray), intent(inout) :: f
      logical, intent(in) :: lstarting
!
      integer :: ierr
!
!  Tell the equation of state that we're here and what f variable we use.
!
      call select_eos_variable('rho', irho)
!
!  Set the density stratification.
!
      call set_stratification()
      call put_shared_variable('rho0z', rho0z, ierr)
      if (ierr /= 0) call fatal_error('initialize_density', 'cannot share variable rho0z. ')
!
!  Disable the force-free considerations.
!
      call put_shared_variable('lffree', .false., ierr)
      if (ierr /= 0) call fatal_error('initialize_density', 'cannot share variable lffree. ')
!
!  Check the switches.
!
      shock: if (diffrho_shock > 0.0) then
        ldiff_shock = .true.
        if (lroot) print *, 'initialize_density: shock mass diffusion; diffrho_shock = ', diffrho_shock
      endif shock
!
      hyper3_mesh: if (diffrho_hyper3_mesh > 0.0) then
        ldiff_hyper3_mesh = .true.
        if (lroot) print *, 'initialize_density: mesh hyper-diffusion; diffrho_hyper3_mesh = ', diffrho_hyper3_mesh
      endif hyper3_mesh
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(lstarting)
!
    endsubroutine initialize_density
!***********************************************************************
    subroutine init_lnrho(f)
!
!  Initializes the density field.
!
!  27-feb-13/ccyang: coded.
!
      use Initcond, only: gaunoise
!
      real, dimension(mx,my,mz,mfarray), intent(inout) :: f
!
      integer :: j
!
      init: do j = 1, ninit
        if (initrho(j) == 'nothing') cycle init
!
        init_cond: select case (initrho(j))
!
        case ('zero') init_cond
          f(:,:,:,irho) = 0.0
!
        case ('const') init_cond
          f(:,:,:,irho) = amplrho(j)
!
        case ('noise', 'gaussian') init_cond
          call gaunoise(amplrho(j), f, irho, irho)
!
        case default init_cond
          call fatal_error('init_lnrho', 'unknown initial condition ' // trim(initrho(j)))
!
        endselect init_cond
!
      enddo init
!
    endsubroutine init_lnrho
!***********************************************************************
    subroutine calc_ldensity_pars(f)
!
      real, dimension (mx,my,mz,mfarray) :: f
!
      call keep_compiler_quiet(f)
!
  endsubroutine calc_ldensity_pars
!***********************************************************************
    subroutine pencil_criteria_density()
!
!  All pencils that the Density module depends on are specified here.
!
!  02-nov-13/ccyang: coded.
!
      lpenc_requested(i_rhos) = .true.
      lpenc_requested(i_uu) = .true.
      lpenc_requested(i_divu) = .true.
      lpenc_requested(i_ugrhos) = .true.
!
      shock: if (ldiff_shock) then
        lpenc_requested(i_shock) = .true.
        lpenc_requested(i_gshock) = .true.
        lpenc_requested(i_grhos) = .true.
      endif shock
!
!  Diagnostic Pencils
!
      if (idiag_mass /= 0 .or. idiag_rhomin /= 0 .or. idiag_rhomax /= 0) lpenc_diagnos(i_rho) = .true.
      if (idiag_sigma /= 0) lpenc_diagnos(i_rho) = .true.
!
    endsubroutine pencil_criteria_density
!***********************************************************************
    subroutine pencil_interdep_density(lpencil_in)
!
!  Interdependency among pencils from the Density module is specified here.
!
!  02-nov-13/ccyang: coded.
!
      logical, dimension(npencils) :: lpencil_in
!
      if (lpencil_in(i_rhos1)) lpencil_in(i_rhos) = .true.
!
      glnrhos: if (lpencil_in(i_glnrhos)) then
        lpencil_in(i_rhos1) = .true.
        lpencil_in(i_grhos) = .true.
      endif glnrhos
!
      ugrhos: if (lpencil_in(i_ugrhos)) then
        lpencil_in(i_grhos) = .true.
        lpencil_in(i_uu) = .true.
      endif ugrhos
!
      if (lpencil_in(i_rho)) lpencil_in(i_rhos) = .true.
!
      if (lpencil_in(i_rho1)) lpencil_in(i_rho) = .true.
!
      grho: if (lpencil_in(i_grho)) then
        lpencil_in(i_rho) = .true.
        lpencil_in(i_grhos) = .true.
      endif grho
!
      glnrho: if (lpencil_in(i_glnrho)) then
        lpencil_in(i_rho1) = .true.
        lpencil_in(i_grho) = .true.
      endif glnrho
!
      ekin: if (lpencil_in(i_ekin)) then
        lpencil_in(i_rho)=.true.
        lpencil_in(i_u2)=.true.
      endif ekin
!
!  xy-average related
!
      ruumz: if (idiag_rux2mz /= 0 .or. idiag_ruy2mz /= 0 .or. idiag_ruz2mz /= 0 .or. &
                 idiag_ruxuymz /= 0 .or. idiag_ruxuzmz /= 0 .or. idiag_ruyuzmz /= 0) then 
        lpenc_diagnos(i_rho) = .true.
        lpenc_diagnos(i_uu) = .true.
      endif ruumz
!
!  yz-average related
!
      ruumx: if (idiag_rux2mx /= 0 .or. idiag_ruy2mx /= 0 .or. idiag_ruz2mx /= 0 .or. &
                 idiag_ruxuymx /= 0 .or. idiag_ruxuzmx /= 0 .or. idiag_ruyuzmx /= 0) then 
        lpenc_diagnos(i_rho) = .true.
        lpenc_diagnos(i_uu) = .true.
      endif ruumx
!
    endsubroutine pencil_interdep_density
!***********************************************************************
    subroutine calc_pencils_density(f, p)
!
!  Calculate Density pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!  02-nov-13/ccyang: coded.
!
      use Sub, only: grad, u_dot_grad
      use EquationOfState, only: cs20
!
      real, dimension(mx,my,mz,mfarray), intent(in) :: f
      type(pencil_case), intent(inout) :: p
!
! rhos: density scaled by stratification
!
      if (lpencil(i_rhos)) p%rhos = 1.0 + f(l1:l2,m,n,irho)
!
! rhos1
!
      if (lpencil(i_rhos1)) p%rhos1 = 1.0 / p%rhos
!
! grhos
!
      if (lpencil(i_grhos)) call grad(f, irho, p%grhos)
!
! glnrhos
!
      if (lpencil(i_glnrhos)) p%glnrhos = spread(p%rhos1,2,3) * p%grhos
!
! ugrhos
!
      if (lpencil(i_ugrhos)) call u_dot_grad(f, irho, p%grhos, p%uu, p%ugrhos)
!
! rho
!
      if (lpencil(i_rho)) p%rho = rho0z(n) * p%rhos
!
! rho1
!
      if (lpencil(i_rho1)) p%rho1 = 1.0 / p%rho
!
! grho
!
      grho: if (lpencil(i_grho)) then
        p%grho = rho0z(n) * p%grhos
        p%grho(:,3) = p%grho(:,3) + dlnrho0dz(n) * p%rho
      endif grho
!
! glnrho
!
      if (lpencil(i_glnrho)) p%glnrho = spread(p%rho1,2,3) * p%grho
!
! ekin
!
      if (lpencil(i_ekin)) p%ekin = 0.5 * p%rho * p%u2
!
!  Currently not required pencils.
!
      lnrho: if (lpencil(i_lnrho)) then
        call fatal_error('calc_pencils_density', 'lnrho is not available. ')
        p%lnrho = 0.0
      endif lnrho
!
      ugrho: if (lpencil(i_ugrho)) then
        call fatal_error('calc_pencils_density', 'ugrho is not available. ')
        p%ugrho = 0.0
      endif ugrho
!
      uglnrho: if (lpencil(i_uglnrho)) then
        call fatal_error('calc_pencils_density', 'uglnrho is not available. ')
        p%uglnrho = 0.0
      endif uglnrho
!
      transprho: if (lpencil(i_transprho)) then
        call fatal_error('calc_pencils_density', 'transprho is not available. ')
        p%transprho = 0.0
      endif transprho
!
      del2rho: if (lpencil(i_del2rho)) then
        call fatal_error('calc_pencils_density', 'del2rho is not available. ')
        p%del2rho = 0.0
      endif del2rho
!
      del2lnrho: if (lpencil(i_del2lnrho)) then
        call fatal_error('calc_pencils_density', 'del2lnrho is not available. ')
        p%del2lnrho = 0.0
      endif del2lnrho
!
      del6lnrho: if (lpencil(i_del6lnrho)) then
        call fatal_error('calc_pencils_density', 'del6lnrho is not available. ')
        p%del6lnrho = 0.0
      endif del6lnrho
!
      hlnrho: if (lpencil(i_hlnrho)) then
        call fatal_error('calc_pencils_density', 'hlnrho is not available. ')
        p%hlnrho = 0.0
      endif hlnrho
!
      uij5glnrho: if (lpencil(i_uij5glnrho)) then
        call fatal_error('calc_pencils_density', 'uij5glnrho is not available. ')
        p%uij5glnrho = 0.0
      endif uij5glnrho
!
      sglnrho: if (lpencil(i_sglnrho)) then
        call fatal_error('calc_pencils_density', 'sglnrho is not available. ')
        p%sglnrho = 0.0
      endif sglnrho
!
    endsubroutine calc_pencils_density
!***********************************************************************
    subroutine density_before_boundary(f)
!
      real, dimension (mx,my,mz,mfarray), intent(inout) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine density_before_boundary
!***********************************************************************
    subroutine dlnrho_dt(f,df,p)
!
!  Continuity equation.
!
!  02-nov-13/ccyang: coded.
!
      use Sub, only: identify_bcs, dot_mn, del2
      use Deriv, only: der6
      use Special, only: special_calc_density
      use Diagnostics
!
      real, dimension(mx,my,mz,mfarray), intent(in) :: f
      real, dimension(mx,my,mz,mvar), intent(inout) :: df
      type(pencil_case), intent(in) :: p
!
      real, dimension(nx) :: del2rhos, penc
      integer :: j
!
!  Start the clock for this procedure.
!
      call timing('dlnrho_dt', 'entered', mnloop=.true.)
!
!  Identify module and boundary conditions.
!
      if (headtt .or. ldebug) print *, 'dlnrho_dt: SOLVE the continuity equation. '
      if (headtt) call identify_bcs('rho', irho)
!
!  Find the rate of change.
!
      df(l1:l2,m,n,irho) = df(l1:l2,m,n,irho) - p%ugrhos - p%rhos * (p%divu + p%uu(:,3) * dlnrho0dz(n))
!
!  Shock mass diffusion
!
      shock: if (ldiff_shock) then
        call del2(f, irho, del2rhos)
        call dot_mn(p%gshock, p%grhos, penc)
        df(l1:l2,m,n,irho) = df(l1:l2,m,n,irho) + diffrho_shock * (p%shock * del2rhos + penc)
        if (lfirst .and. ldt) diffus_diffrho = diffus_diffrho + diffrho_shock * dxyz_2 * p%shock
      endif shock
!
!  Mesh hyper-diffusion
!
      hyper3: if (ldiff_hyper3_mesh) then
        dir: do j = 1, 3
          call der6(f, irho, penc, j, ignoredx=.true.)
          df(l1:l2,m,n,irho) = df(l1:l2,m,n,irho) + diffrho_hyper3_mesh * penc * dline_1(:,j)
        enddo dir
        if (lfirst .and. ldt) diffus_diffrho3 = diffus_diffrho3 &
                                              + diffrho_hyper3_mesh * (abs(dline_1(:,1)) + abs(dline_1(:,2)) + abs(dline_1(:,3)))
      endif hyper3
!
!  Call optional user-defined calculations.
!
      if (lspecial) call special_calc_density(f, df, p)
!
!  2D averages
!
      avg_2d: if (l2davgfirst) then
        penc = f(l1:l2,m,n,irho)
        if (idiag_drhomxz /= 0) call ysum_mn_name_xz(penc, idiag_drhomxz)
        if (idiag_drho2mxz /= 0) call ysum_mn_name_xz(penc**2, idiag_drho2mxz)
        if (idiag_drhomxy /= 0) call zsum_mn_name_xy(penc, idiag_drhomxy)
        if (idiag_drho2mxy /= 0) call zsum_mn_name_xy(penc**2, idiag_drho2mxy)
        if (idiag_sigma /= 0) call zsum_mn_name_xy(p%rho, idiag_sigma, lint=.true.)
      endif avg_2d
!
!  1D averages
!
      avg_1d: if (l1davgfirst) then
        penc = f(l1:l2,m,n,irho)
!       xy-averages
        if (idiag_drhomz /= 0) call xysum_mn_name_z(penc, idiag_drhomz)
        if (idiag_drho2mz /= 0) call xysum_mn_name_z(penc**2, idiag_drho2mz)
        if (idiag_rux2mz /= 0) call xysum_mn_name_z(p%rho * p%uu(:,1)**2, idiag_rux2mz)
        if (idiag_ruy2mz /= 0) call xysum_mn_name_z(p%rho * p%uu(:,2)**2, idiag_ruy2mz)
        if (idiag_ruz2mz /= 0) call xysum_mn_name_z(p%rho * p%uu(:,3)**2, idiag_ruz2mz)
        if (idiag_ruxuymz /= 0) call xysum_mn_name_z(p%rho * p%uu(:,1) * p%uu(:,2), idiag_ruxuymz)
        if (idiag_ruxuzmz /= 0) call xysum_mn_name_z(p%rho * p%uu(:,1) * p%uu(:,3), idiag_ruxuzmz)
        if (idiag_ruyuzmz /= 0) call xysum_mn_name_z(p%rho * p%uu(:,2) * p%uu(:,3), idiag_ruyuzmz)
!       xz-averages
        if (idiag_drhomy /= 0) call xzsum_mn_name_y(penc, idiag_drhomy)
        if (idiag_drho2my /= 0) call xzsum_mn_name_y(penc**2, idiag_drho2my)
!       yz-averages
        if (idiag_drhomx /= 0) call yzsum_mn_name_x(penc, idiag_drhomx)
        if (idiag_drho2mx /= 0) call yzsum_mn_name_x(penc**2, idiag_drho2mx)
        if (idiag_rux2mx /= 0) call yzsum_mn_name_x(p%rho * p%uu(:,1)**2, idiag_rux2mx)
        if (idiag_ruy2mx /= 0) call yzsum_mn_name_x(p%rho * p%uu(:,2)**2, idiag_ruy2mx)
        if (idiag_ruz2mx /= 0) call yzsum_mn_name_x(p%rho * p%uu(:,3)**2, idiag_ruz2mx)
        if (idiag_ruxuymx /= 0) call yzsum_mn_name_x(p%rho * p%uu(:,1) * p%uu(:,2), idiag_ruxuymx)
        if (idiag_ruxuzmx /= 0) call yzsum_mn_name_x(p%rho * p%uu(:,1) * p%uu(:,3), idiag_ruxuzmx)
        if (idiag_ruyuzmx /= 0) call yzsum_mn_name_x(p%rho * p%uu(:,2) * p%uu(:,3), idiag_ruyuzmx)
      endif avg_1d
!
!  Diagnostics
!
      diagnos: if (ldiagnos) then
!
        rho: if (idiag_mass /= 0 .or. idiag_rhomin /= 0 .or. idiag_rhomax /= 0) then
          penc = p%rho
          if (idiag_mass /= 0) call integrate_mn_name(penc, idiag_mass)
          if (idiag_rhomin /= 0) call max_mn_name(-penc, idiag_rhomin, lneg=.true.)
          if (idiag_rhomax /= 0) call max_mn_name(penc, idiag_rhomax)
        endif rho
!
        drho: if (idiag_drhom /= 0 .or. idiag_drho2m /= 0 .or. idiag_drhorms /= 0 .or. idiag_drhomax /= 0) then
          penc = f(l1:l2,m,n,irho)
          if (idiag_drhom /= 0) call sum_mn_name(penc, idiag_drhom)
          if (idiag_drho2m /= 0) call sum_mn_name(penc**2, idiag_drho2m)
          if (idiag_drhorms /= 0) call sum_mn_name(penc**2, idiag_drhorms, lsqrt=.true.)
          if (idiag_drhomax /= 0) call max_mn_name(abs(penc), idiag_drhomax)
        endif drho
!
      endif diagnos
!
!  Stop the clock.
!
      call timing('dlnrho_dt', 'finished', mnloop=.true.)
!
    endsubroutine dlnrho_dt
!***********************************************************************
    subroutine impose_density_floor(f)
!
!  Check negative density or impose a density floor.
!
!  27-feb-13/ccyang: coded.
!
      real, dimension(mx,my,mz,mfarray), intent(inout) :: f
!
      integer :: i, j, k
      real :: drhos_min
!
!  Impose density floor or
!
      dens_floor: if (density_floor > 0.0) then
        scan1: do k = n1, n2
          drhos_min = (density_floor - rho0z(k)) / rho0z(k)
          where(f(l1:l2,m1:m2,k,irho) < drhos_min) f(l1:l2,m1:m2,k,irho) = drhos_min
        enddo scan1
!
!  Trap any negative density.
!
      else dens_floor
        neg_dens: if (any(f(l1:l2,m1:m2,n1:n2,irho) <= -1.0)) then
          scan2z: do k = n1, n2
            scan2y: do j = m1, m2
              scan2x: do i = l1, l2
                if (f(i,j,k,irho) <= -1.0) print 10, rho0z(k) * (1.0 + f(i,j,k,irho)), x(i), y(j), z(k)
                10 format (1x, 'Negative density ', es13.6, ' is detected at x = ', es10.3, ', y = ', es10.3, ', and z = ', es10.3)
              enddo scan2x
            enddo scan2y
          enddo scan2z
          call fatal_error_local('impose_density_floor', 'detected negative density. ')
        endif neg_dens
!
      endif dens_floor
!
    endsubroutine impose_density_floor
!***********************************************************************
    subroutine read_density_init_pars(unit, iostat)
!
!  Read the namelist density_init_pars.
!
!  26-feb-13/ccyang: coded.
!
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
!
      character(len=256) :: msg
      integer :: ios
!
!  Read the namelist.
!
!      read(unit, nml=density_init_pars, iostat=ios, iomsg=msg)
      read(unit, nml=density_init_pars, iostat=ios)
!
!  Handle any error.
!
      error: if (present(iostat)) then
        iostat = ios
      elseif (ios /= 0) then error
!        call fatal_error('read_density_init_pars', 'unable to read the namelist; ' // trim(msg))
        call fatal_error('read_density_init_pars', 'unable to read the namelist. ')
      endif error
!
    endsubroutine read_density_init_pars
!***********************************************************************
    subroutine write_density_init_pars(unit)
!
!  Write the namelist density_init_pars.
!
!  26-feb-13/ccyang: coded.
!
      integer, intent(in) :: unit
!
      character(len=256) :: msg
      integer :: ios
!
!  Write the namelist.
!
!      write(unit, nml=density_init_pars, iostat=ios, iomsg=msg)
      write(unit, nml=density_init_pars, iostat=ios)
!
!  Handle any error.
!
!      if (ios /= 0) call fatal_error('write_density_init_pars', 'unable to write the namelist; ' // trim(msg))
      if (ios /= 0) call fatal_error('write_density_init_pars', 'unable to write the namelist. ')
!
    endsubroutine write_density_init_pars
!***********************************************************************
    subroutine read_density_run_pars(unit, iostat)
!
!  Read the namelist density_run_pars.
!
!  26-feb-13/ccyang: coded.
!
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
!
      character(len=256) :: msg
      integer :: ios
!
!  Read the namelist.
!
!      read(unit, nml=density_run_pars, iostat=ios, iomsg=msg)
      read(unit, nml=density_run_pars, iostat=ios)
!
!  Handle any error.
!
      error: if (present(iostat)) then
        iostat = ios
      elseif (ios /= 0) then error
!        call fatal_error('read_density_run_pars', 'unable to read the namelist; ' // trim(msg))
        call fatal_error('read_density_run_pars', 'unable to read the namelist. ')
      endif error
!
    endsubroutine read_density_run_pars
!***********************************************************************
    subroutine write_density_run_pars(unit)
!
!  Write the namelist density_run_pars.
!
!  26-feb-13/ccyang: coded.
!
      integer, intent(in) :: unit
!
      character(len=256) :: msg
      integer :: ios
!
!  Write the namelist.
!
!      write(unit, nml=density_run_pars, iostat=ios, iomsg=msg)
      write(unit, nml=density_run_pars, iostat=ios)
!
!  Handle any error.
!
!      if (ios /= 0) call fatal_error('write_density_run_pars', 'unable to write the namelist; ' // trim(msg))
      if (ios /= 0) call fatal_error('write_density_run_pars', 'unable to write the namelist. ')
!
    endsubroutine write_density_run_pars
!***********************************************************************
    subroutine rprint_density(lreset, lwrite)
!
!  Reads and registers print parameters relevant for continuity equation.
!
!  27-feb-13/ccyang: coded.
!
      use Diagnostics, only: parse_name
!
      logical, intent(in) :: lreset
      logical, intent(in), optional :: lwrite
!
      logical :: lwr
      integer :: iname
!
      lwr = .false.
      if (present(lwrite)) lwr = lwrite
!
!  Reset everything in case of reset.
!
      reset: if (lreset) then
!       Diagnostics
        idiag_mass = 0
        idiag_rhomin = 0
        idiag_rhomax = 0
        idiag_drhom = 0
        idiag_drho2m = 0
        idiag_drhorms = 0
        idiag_drhomax = 0
!       xy-averages
        idiag_drhomz = 0
        idiag_drho2mz = 0
        idiag_rux2mz = 0
        idiag_ruy2mz = 0
        idiag_ruz2mz = 0
        idiag_ruxuymz = 0
        idiag_ruxuzmz = 0
        idiag_ruyuzmz = 0
!       xz-averages
        idiag_drhomy = 0
        idiag_drho2my = 0
!       yz-averages
        idiag_drhomx = 0
        idiag_drho2mx = 0
        idiag_rux2mx = 0
        idiag_ruy2mx = 0
        idiag_ruz2mx = 0
        idiag_ruxuymx = 0
        idiag_ruxuzmx = 0
        idiag_ruyuzmx = 0
!       y-averages
        idiag_drhomxz = 0
        idiag_drho2mxz = 0
!       z-averages
        idiag_sigma = 0
        idiag_drhomxy = 0
        idiag_drho2mxy = 0
      endif reset
!
!  Check for diagnostic variables listed in print.in.
!
      whole: do iname = 1, nname
        call parse_name(iname, cname(iname), cform(iname), 'mass', idiag_mass)
        call parse_name(iname, cname(iname), cform(iname), 'rhomin', idiag_rhomin)
        call parse_name(iname, cname(iname), cform(iname), 'rhomax', idiag_rhomax)
        call parse_name(iname, cname(iname), cform(iname), 'drhom', idiag_drhom)
        call parse_name(iname, cname(iname), cform(iname), 'drho2m', idiag_drho2m)
        call parse_name(iname, cname(iname), cform(iname), 'drhorms', idiag_drhorms)
        call parse_name(iname, cname(iname), cform(iname), 'drhomax', idiag_drhomax)
      enddo whole
!
!  Check for xy-averages listed in xyaver.in.
!
      xyaver: do iname = 1, nnamez
        call parse_name(iname, cnamez(iname), cformz(iname), 'drhomz', idiag_drhomz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'drho2mz', idiag_drho2mz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'rux2mz', idiag_rux2mz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'ruy2mz', idiag_ruy2mz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'ruz2mz', idiag_ruz2mz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'ruxuymz', idiag_ruxuymz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'ruxuzmz', idiag_ruxuzmz)
        call parse_name(iname, cnamez(iname), cformz(iname), 'ruyuzmz', idiag_ruyuzmz)
      enddo xyaver
!
!  Check for xz-averages listed in xzaver.in.
!
      xzaver: do iname = 1, nnamey
        call parse_name(iname, cnamey(iname), cformy(iname), 'drhomy', idiag_drhomy)
        call parse_name(iname, cnamey(iname), cformy(iname), 'drho2my', idiag_drho2my)
      enddo xzaver
!
!  Check for yz-averages listed in yzaver.in.
!
      yzaver: do iname = 1, nnamex
        call parse_name(iname, cnamex(iname), cformx(iname), 'drhomx', idiag_drhomx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'drho2mx', idiag_drho2mx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'rux2mx', idiag_rux2mx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'ruy2mx', idiag_ruy2mx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'ruz2mx', idiag_ruz2mx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'ruxuymx', idiag_ruxuymx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'ruxuzmx', idiag_ruxuzmx)
        call parse_name(iname, cnamex(iname), cformx(iname), 'ruyuzmx', idiag_ruyuzmx)
      enddo yzaver
!
!  Check for y-averages listed in yaver.in.
!
      yaver: do iname = 1, nnamexz
        call parse_name(iname, cnamexz(iname), cformxz(iname), 'drhomxz', idiag_drhomxz)
        call parse_name(iname, cnamexz(iname), cformxz(iname), 'drho2mxz', idiag_drho2mxz)
      enddo yaver
!
!  Check for z-averages listed in zaver.in.
!
      zaver: do iname = 1, nnamexy
        call parse_name(iname, cnamexy(iname), cformxy(iname), 'drhomxy', idiag_drhomxy)
        call parse_name(iname, cnamexy(iname), cformxy(iname), 'drho2mxy', idiag_drho2mxy)
        call parse_name(iname, cnamexy(iname), cformxy(iname), 'sigma', idiag_sigma)
      enddo zaver
!
!  Write column where which density variable is stored.
!
      indices: if (lwr) then
        write(3,*) 'nname = ', nname
        write(3,*) 'ilnrho = 0'
        write(3,*) 'irho = ', irho
      endif indices
!
    endsubroutine rprint_density
!***********************************************************************
    subroutine get_slices_density(f,slices)
!
!  Write slices for animation of Density variables.
!
!  27-feb-13/ccyang: coded.
!
      real, dimension(mx,my,mz,mfarray), intent(in) :: f
      type(slice_data), intent(inout) :: slices
!
      var: select case (trim(slices%name))
!
      case ('drho') var
        slices%yz = f(ix_loc, m1:m2, n1:n2, irho)
        slices%xz = f(l1:l2, iy_loc, n1:n2, irho)
        slices%xy = f(l1:l2, m1:m2, iz_loc, irho)
        slices%xy2 = f(l1:l2, m1:m2, iz2_loc, irho)
        if (lwrite_slice_xy3) slices%xy3 = f(l1:l2, m1:m2, iz3_loc, irho)
        if (lwrite_slice_xy4) slices%xy4 = f(l1:l2, m1:m2, iz4_loc, irho)
        slices%ready = .true.
!
      case ('rho') var
        slices%yz = (1.0 + f(ix_loc, m1:m2, n1:n2, irho)) * spread(rho0z(n1:n2), 1, ny)
        slices%xz = (1.0 + f(l1:l2, iy_loc, n1:n2, irho)) * spread(rho0z(n1:n2), 1, nx)
        slices%xy = (1.0 + f(l1:l2, m1:m2, iz_loc, irho)) * rho0z(iz_loc)
        slices%xy2 = (1.0 + f(l1:l2, m1:m2, iz2_loc, irho)) * rho0z(iz2_loc)
        if (lwrite_slice_xy3) slices%xy3 = (1.0 + f(l1:l2, m1:m2, iz3_loc, irho)) * rho0z(iz3_loc)
        if (lwrite_slice_xy4) slices%xy4 = (1.0 + f(l1:l2, m1:m2, iz4_loc, irho)) * rho0z(iz4_loc)
        slices%ready = .true.
!
      endselect var
!
    endsubroutine get_slices_density
!***********************************************************************
    subroutine get_slices_pressure(f,slices)
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (slice_data) :: slices
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(slices%ready)
!
    endsubroutine get_slices_pressure
!***********************************************************************
    subroutine get_init_average_density(f,init_average_density)
!
!  10-dec-09/piyali: added to pass initial average density
!
    real, dimension (mx,my,mz,mfarray):: f
    real:: init_average_density
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(init_average_density)
!
    endsubroutine get_init_average_density
!***********************************************************************
    subroutine anelastic_after_mn(f, p, df, mass_per_proc)
!
!  Dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension(1) :: mass_per_proc
      type (pencil_case) :: p
!
      call keep_compiler_quiet(f,df)
      call keep_compiler_quiet(p)
      call keep_compiler_quiet(mass_per_proc)
!
    endsubroutine anelastic_after_mn
!***********************************************************************
    subroutine dynamical_diffusion(umax)
!
!  Dynamically set mass diffusion coefficient given fixed mesh Reynolds number.
!
!  28-feb-13/ccyang: coded
!
      real, intent(in) :: umax
!
!  Hyper-diffusion coefficient
!
      if (ldiff_hyper3_mesh) diffrho_hyper3_mesh = pi5_1 * umax / re_mesh / sqrt(3.0)
!
    endsubroutine dynamical_diffusion
!***********************************************************************
    subroutine boussinesq(f)
!
!  23-mar-2012/dintrans: coded
!  dummy routine for the Boussinesq approximation
!  
      real, dimension (mx,my,mz,mfarray) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine boussinesq
!***********************************************************************
    subroutine get_density_z(z, rho0z, dlnrho0dz)
!
!  Calculates equilibrium density rho0z and/or its derivative dlnrho0dz
!  at height z.
!
!  28-feb-13/ccyang: coded.
!
      use EquationOfState, only: rho0, cs0
!
      real, intent(in) :: z
      real, intent(out), optional :: rho0z, dlnrho0dz
!
      real :: h
!
      strat_type: select case (zstrat)
!
      case ('none') strat_type
        if (present(rho0z)) rho0z = rho0
        if (present(dlnrho0dz)) dlnrho0dz = 0.0
!
      case ('gaussian') strat_type
        if (cs0 <= 0.0) call fatal_error('get_density_z', 'cs0 <= 0. ')
        if (nu_epicycle <= 0.0) call fatal_error('get_density_z', 'nu_epicycle <= 0. ')
!
        h = cs0 / nu_epicycle
        if (present(rho0z)) rho0z = rho0 * exp(-0.5 * (z / h)**2)
        if (present(dlnrho0dz)) dlnrho0dz = -z / h**2
!
      case default strat_type
        call fatal_error('get_density_z', 'unknown type of density stratification. ')
!
      endselect strat_type
!
    endsubroutine get_density_z
!***********************************************************************
    subroutine set_stratification()
!
!  Initializes and saves the density stratification
!
!  28-feb-13/ccyang: coded.
!
      integer :: k
!
      scanz: do k = 1, mz
        call get_density_z(z(k), rho0z(k), dlnrho0dz(k))
      enddo scanz
!
    endsubroutine set_stratification
!***********************************************************************
endmodule Density