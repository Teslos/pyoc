!
! Part of iso-C bining for OC TQlib from Teslos
! modified by Matthias Stratmann and Bo Sundman
!
MODULE cstr
! convert characters from Fortran to C and vice versa
contains
  function c_to_f_string(s) result(str)
    use iso_c_binding
    implicit none
    character(kind=c_char,len=1), intent(in) :: s(*)
    character(len=:), allocatable :: str
    integer i, nchars
    i = 1
    do
       if (s(i) == c_null_char) exit
       i = i + 1
    end do
    nchars = i - 1  ! Exclude null character from Fortran string
    allocate(character(len=nchars) :: str)
    str = transfer(s(1:nchars), str)
  end function c_to_f_string

  subroutine f_to_c_string(fstring, cstr)
    use iso_c_binding
    implicit none
    character(len=24) :: fstring
    character(kind=c_char, len=1), intent(out) :: cstr(*)
    integer i
    do i = 1, len(fstring)
       cstr(i) = fstring(i:i)
       cstr(i+1) = c_null_char
    end do
  end subroutine f_to_c_string
  
end module cstr

module liboctqisoc
! 
! OCTQlib with iso-C binding
!
  use iso_c_binding
  use cstr
  use liboctq
!  use general_thermodynamic_package
  implicit none

  integer(c_int), bind(c) :: c_nel
  integer(c_int), bind(c) :: c_maxc=20, c_maxp=100
  type(c_ptr), bind(c), dimension(maxc) :: c_cnam
  character(len=25), dimension(maxc), target :: cnames
  integer(c_int), bind(c) :: c_ntup
   
  TYPE, bind(c) :: c_gtp_equilibrium_data 
!
! NOTE THIS MUST BE UPDATED TO BE IDENTICAL TO GTP_EQUILIBRIUM_DATA
! in the OC source code models/gtp3.F90 (or whatever new versions)
!
! 160829 Updated Bo Sundman
! 151229 First version Matthis Stratmann
!
!  TYPE gtp_equilibrium_data
! this contains all data specific to an equilibrium like conditions,
! status, constitution and calculated values of all phases etc
! Several equilibria may be calculated simultaneously in parallell threads
! so each equilibrium must be independent 
! NOTE: the error code must be local to each equilibria!!!!
! During step and map each equilibrium record with results is saved
! values of T and P, conditions etc.
! Values here are normally set by external conditions or calculated from model
! local list of components, phase_varres with amounts and constitution
! lists of element, species, phases and thermodynamic parameters are global
! status: not used yet?
! multiuse: used for various things like direction in start equilibria
! eqno: sequential number assigned when created
! next: index of next equilibrium in a sequence during step/map calculation.
! eqname: name of equilibrium
! comment: a free text, for example reference for experimental data.
! tpval(1) is T, tpval(2) is P, rgas is R, rtn is R*T
! rtn: value of R*T
! weight: weight value for this experiment, default unity
     integer(c_int) :: status,multiuse,eqno,next
     character(kind=c_char,len=1) :: eqname(24),comment(72)
     real(c_double) :: tpval(2),rtn,weight
! svfunres: the values of state variable functions valid for this equilibrium
     real(c_double) :: svfunres
! the experiments are used in assessments and stored like conditions 
! lastcondition: link to condition list
! lastexperiment: link to experiment list
     TYPE(c_ptr) :: lastcondition,lastexperiment
! components and conversion matrix from components to elements
! complist: array with components (species index or location)??
! compstoi: stoichiometric matrix of compoents relative to elements
! invcompstoi: inverted stoichiometric matrix
     TYPE(c_ptr) :: complist
     real(c_double) :: compstoi
     real(c_double) :: invcompstoi
! one record for each phase+composition set that can be calculated
! phase_varres: here all calculated data for the phases are stored
     TYPE(c_ptr) :: phase_varres
! index to the tpfun_parres array is the same as in the global array tpres 
! eq_tpres: here local calculated values of TP functions are stored
! should be allocatable, not a pointer
     TYPE(c_ptr) :: eq_tpres
! current values of chemical potentials stored in component record but
! duplicated here for easy acces by application software
     real(c_double) :: cmuval
! xconc: convergence criteria for constituent fractions and other things
     real(c_double) :: xconv
! delta-G value for merging gridpoints in grid minimizer
! smaller value creates problem for test step3.OCM, MC and austenite merged
     real(c_double) :: gmindif=-5.0D-2
! maxiter: maximum number of iterations allowed
     integer(c_int) :: maxiter
! This is to store additional things not really invented yet ...
! It may be used in ENTER MANY_EQUIL for things to calculate and list
     character(kind=c_char,len=1) :: eqextra(80)
! this is to save a copy of the last calculated system matrix, needed ??
! to calculate dot derivatives, initiate to zero
     integer(c_int) :: sysmatdim=0,nfixmu=0,nfixph=0
     integer(c_int) :: fixmu
     integer(c_int) :: fixph
     real(c_double) :: savesysmat
!  END TYPE gtp_equilibrium_data
!
  END TYPE c_gtp_equilibrium_data

contains

! functions
  integer function c_noofcs(iph) bind(c, name='c_noofcs')
    integer(c_int), value :: iph
    c_noofcs = noofcs(iph)
    return 
  end function c_noofcs

  subroutine examine_gtp_equilibrium_data(c_ceq) &
       bind(c, name='examine_gtp_equilibrium_data')
    type(c_ptr), intent(in), value :: c_ceq
    type(gtp_equilibrium_data), pointer :: ceq
    integer :: i,j
    call c_f_pointer(c_ceq, ceq)
    write(*,10) ceq%status, ceq%multiuse, ceq%eqno
10  format(/'gtp_equilibrium_data: status, multiuse, eqno, next'/, 3i4)
    write(*,20) ceq%eqname
20  format(/'Name of equilibrium'/,a)
    write(*,30) ceq%tpval, ceq%rtn
30  format(/'Value of T and P'/, 2f8.3, /'R*T'/, f8.4)
    do i = 1, size(ceq%compstoi,1)
       write(*,*) (ceq%compstoi(i,j), j=1,size(ceq%compstoi,2))
    end do
    write(*,*) ceq%cmuval
    write(*,*) ceq%xconv
    write(*,*) ceq%gmindif
    write(*,*) ceq%maxiter
    write(*,*) ceq%sysmatdim, ceq%nfixmu, ceq%nfixph
    write(*,*) ceq%fixmu, ceq%fixph, ceq%savesysmat
  end subroutine examine_gtp_equilibrium_data

!\begin{verbatim}
  subroutine c_tqini(n, c_ceq) bind(c, name='c_tqini')
    integer(c_int), intent(in) :: n
    type(c_ptr), intent(out) :: c_ceq
!\end{verbatim}  
    type(gtp_equilibrium_data), pointer :: ceq
    integer :: i1,i2
    
    call tqini(n, ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqini

!\begin{verbatim}
  subroutine c_tqrfil(filename,c_ceq) bind(c, name='c_tqrfil')
    character(kind=c_char,len=1), intent(in) :: filename(*)
    character(len=:), allocatable :: fstring
    type(gtp_equilibrium_data), pointer :: ceq
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    integer :: i,j,l
    character(kind=c_char, len=1),dimension(24), target :: f_pointers
! convert type(c_ptr) to fptr
    call c_f_pointer(c_ceq, ceq)
    fstring = c_to_f_string(filename)
    write(*,*) 'tqrfil: Filename01:', fstring
    call tqrfil(fstring, ceq)
    write(*,*) 'finish the tqrfil function'
! after tqrfil ntup variable is defined
    c_ntup = ntup
    c_nel = nel
    do i = 1, nel
       cnames(i) = trim(cnam(i)) // c_null_char
       c_cnam(i) = c_loc(cnames(i))
    end do
    c_ceq = c_loc(ceq)
  end subroutine c_tqrfil
  
!\begin{verbatim}
  subroutine c_tqrpfil(filename,nel,c_selel,c_ceq) bind(c, name='c_tqrpfil')
    character(kind=c_char), intent(in) :: filename
    integer(c_int), intent(in), value :: nel
    type(c_ptr), intent(in), dimension(nel), target :: c_selel
    type(c_ptr), intent(inout) :: c_ceq  
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    character(len=:), allocatable :: fstring
    character, pointer :: selel(:)
    integer :: i
    character elem(nel)*2
    fstring = c_to_f_string(filename)
    call c_f_pointer(c_ceq, ceq)
! convert the c type selel strings to f-selel strings
! note: additional character is for C terminated '\0'
    do i = 1, nel
       call c_f_pointer(c_selel(i), selel, [3])
       elem(i) = c_to_f_string(selel)
    end do 
    write(*,*) 'I am in the tqrpfil routine passing ', fstring,nel,elem
    call tqrpfil(fstring, nel, elem, ceq)
! after tqrpfil ntup variable is defined
    c_ntup = ntup
    c_nel = nel
    do i = 1, nel
       cnames(i) = trim(cnam(i)) // c_null_char
       c_cnam(i) = c_loc(cnames(i))
    end do
    c_ceq = c_loc(ceq)
  end subroutine c_tqrpfil

!\begin{verbatim}
  subroutine c_tqgcom(n,components,c_ceq) bind(c, name='c_tqgcom')
! get system components
    integer(c_int), intent(inout) :: n
    !character(kind=c_char, len=24), dimension(24), intent(out) :: c_components
    type(c_ptr), intent(inout) :: c_ceq  
!\end{verbatim}
    integer, target :: nc
    character(len=24) :: fcomponents(maxel)
    character(kind=c_char, len=1), dimension(maxel*24) :: components
    type(gtp_equilibrium_data), pointer :: ceq  
    integer :: i,j,l
    call c_f_pointer(c_ceq, ceq)
    call tqgcom(nc, fcomponents, ceq)
! convert the F components strings to C 
    l = len(fcomponents(1))
    do i = 1, nc
       do j = 1, l
          components((i-1)*l+j)(1:1) = fcomponents(i)(j:j)
       end do
! null termination
       components(i*l) = c_null_char 
    end do
    c_ceq = c_loc(ceq)
    n = nc
  end subroutine c_tqgcom

!\begin{verbatim}
  subroutine c_tqgnp(n, c_ceq) bind(c, name='c_tqgnp')
    integer(c_int), intent(inout) :: n
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq, ceq)
    call tqgnp(n, ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqgnp

!\begin{verbatim}
  subroutine c_tqgpn(n,phasename, c_ceq) bind(c, name='c_tqgpn')
! get name of phase n,
! NOTE: n is phase number, not extended phase index
    integer(c_int), intent(in), value :: n
    character(kind=c_char, len=1), intent(inout) :: phasename(24)
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    character(len=24) :: fstring
    integer :: i
    call c_f_pointer(c_ceq, ceq)
! fstring = c_to_f_string(phasename)
    call tqgpn(n, fstring, ceq)
! copy the f-string to c-string and end with '\0'
    do i=1,len(trim(fstring))
       phasename(i)(1:1) = fstring(i:i)
       phasename(i+1)(1:1) = c_null_char
    end do
    c_ceq = c_loc(ceq)
  end subroutine c_tqgpn 

!\begin{verbatim}
  subroutine c_tqgpi(n,phasename,c_ceq) bind(c, name='c_tqgpi')
! get index of phase phasename
    integer(c_int), intent(out) :: n
    character(c_char), intent(in) :: phasename(24)
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    character(len=24) :: fstring
    call c_f_pointer(c_ceq, ceq)
    fstring = c_to_f_string(phasename)
    call tqgpi(n, fstring, ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqgpi

!\begin{verbatim}
  subroutine c_tqgpcn(n, c, constituentname, c_ceq) bind(c, name='c_tqgpcn')
! get name of constitutent c in phase n
    integer(c_int), intent(in) :: n  ! phase number
    integer(c_int), intent(in) :: c  ! extended constituent index: 
!                                      10*species_number + sublattice
    character(c_char), intent(out) :: constituentname(24)
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    write(*,*) 'tqgpcn not implemented yet'
  end subroutine c_tqgpcn

!\begin{verbatim}
  subroutine c_tqgpci(n,c, constituentname, c_ceq) bind(c, name='c_tqgpci')
! get index of constituent with name in phase n
    integer(c_int), intent(in) :: n 
    integer(c_int), intent(out) :: c ! exit: extended constituent index:
!                                      10*species_number+sublattice
    character(c_char), intent(in) :: constituentname(24)
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    character(len=24) :: fstring
    fstring = c_to_f_string(constituentname)
    call c_f_pointer(c_ceq, ceq)
    call tqgpci(n, c, fstring, ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqgpci

!\begin{verbatim}
  subroutine c_tqgpcs(n, c, stoi, mass, c_ceq) bind(c, name='c_tqgpcs')
!get stoichiometry of constituent c in phase n
!? missing argument number of elements????
    integer(c_int), intent(in) :: n
    integer(c_int), intent(in) :: c ! in: extended constituent index:
!                                     10*species_number + sublattice
    real(c_double), intent(out) :: stoi(*) ! exit: stoichiometry of elements
    real(c_double), intent(out) :: mass     ! exit: total mass
    type(c_ptr), intent(inout) :: c_ceq 
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq, ceq)
    call tqgpcs(n,c,stoi,mass,ceq)
    c_ceq=c_loc(ceq)
  end subroutine c_tqgpcs

!\begin{verbatim}
  subroutine c_tqgccf(n1,n2,elnames,stoi,mass,c_ceq)
! get stoichiometry of component n1
! n2 is number of elements ( dimension of elements and stoi )
    integer(c_int), intent(in) :: n1  ! in: component number
    integer(c_int), intent(out) :: n2 ! exit: number of elements in component
    character(c_char), intent(out) :: elnames(2) ! exit: element symbols
    real(c_double), intent(out) :: stoi(*) ! exit: element stoichiometry
    real(c_double), intent(out) :: mass    ! exit: component mass
!                                           (sum of element mass)
    type(c_ptr), intent(inout) :: c_ceq  
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq, ceq)
    call tqgccf(n1,n2,elnames,stoi, mass, ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqgccf

!\begin{verbatim}
  subroutine c_tqgnpc(n,c,c_ceq) bind(c, name='c_tqgnpc')
! get number of constituents of phase n
    integer(c_int), intent(in) :: n ! in: phase number 
    integer(c_int), intent(out) :: c ! exit: number of constituents
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq,ceq)
    call tqgnpc(n,c,ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqgnpc

!\begin{verbatim}
  subroutine c_tqsetc(statvar, n1, n2, mvalue, cnum, c_ceq) &
       bind(c, name='c_tqsetc')
! set condition
! stavar is state variable as text
! n1 and n2 are auxilliary indices
! value is the value of the condition
! cnum is returned as an index of the condition.
! to remove a condition the value sould be equial to RNONE ????
! when a phase indesx is needed it should be 10*nph + ics
! SEE TQGETV for doucumentation of stavar etc.
!>>>> to be modified to use phase tuplets
    integer(c_int), intent(in),value :: n1 !in: 0 or extended phase index:
!                                       10*phase_number+comp.set
                                     ! or component set
    integer(c_int), intent(in),value :: n2 !
    integer(c_int), intent(out) :: cnum !exit: 
!                                        sequential number of this condition
    character(c_char), intent(in) :: statvar !in: character
!                                             with state variable symbol
    real(c_double), intent(in), value :: mvalue  !in: value of condition
    type(gtp_equilibrium_data), pointer :: ceq
    type(c_ptr), intent(inout) :: c_ceq ! in: current equilibrium
!\end{verbatim}
    call c_f_pointer(c_ceq, ceq)
    call tqsetc(statvar, n1, n2, mvalue, cnum, ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqsetc

!\begin{verbatim}
  subroutine c_tqce(mtarget,n1,n2,mvalue,c_ceq) bind(c,name='c_tqce')
! calculate equilibrium with possible target
! Target can be empty or a state variable with indicies n1 and n2
! value is the calculated value of target
    integer(c_int), intent(in),value :: n1
    integer(c_int), intent(in),value :: n2
    type(c_ptr), intent(inout) :: c_ceq
    character(c_char), intent(inout) :: mtarget  
    real(c_double), intent(inout) :: mvalue
    type(gtp_equilibrium_data), pointer :: ceq
!\end{verbatim}
    character(len=24) :: fstring
    call c_f_pointer(c_ceq,ceq)
    fstring = c_to_f_string(mtarget)
    call tqce(fstring,n1,n2,mvalue,ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqce

!\begin{verbatim}
  subroutine c_tqgetv(statvar,n1,n2,n3,values,c_ceq) bind(c,name='c_tqgetv')
! get equilibrium results using state variables
! stavar is the state variable IN CAPITAL LETTERS with indices n1 and n2 
! n3 at the call is the dimension of values, changed to number of values
! value is the calculated value, it can be an array with n3 values.
    implicit none
    integer(c_int), intent(in), value ::  n1,n2
    integer(c_int), intent(inout) :: n3
    character(c_char), intent(in) :: statvar
    real(c_double), intent(inout) :: values(*)
    type(c_ptr), intent(inout) :: c_ceq  !IN: current equilibrium
!========================================================
! >>>> implement use of phase tuples 
! stavar must be a symbol listed below
! IMPORTANT: some terms explained after the table
! Symbol  index1,index2                     Meaning (unit)
!.... potentials
! T     0,0                                             Temperature (K)
! P     0,0                                             Pressure (Pa)
! MU    component,0 or phase-tuple*1,constituent*2  Chemical potential (J)
! AC    component,0 or phase-tuple,constituent      Activity = EXP(MU/RT)
! LNAC  component,0 or phase-tuple,constituent      LN(activity) = MU/RT
!...... extensive variables
! U     0,0 or phase-tuple,0       Internal energy (J) whole system or phase
! UM    0,0 or phase-tuple,0       same per mole components
! UW    0,0 or phase-tuple,0       same per kg
! UV    0,0 or phase-tuple,0       same per m3
! UF    phase-tuple,0              same per formula unit of phase
! S*3   0,0 or phase-tuple,0       Entropy (J/K) 
! V     0,0 or phase-tuple,0       Volume (m3)
! H     0,0 or phase-tuple,0       Enthalpy (J)
! A     0,0 or phase-tuple,0       Helmholtz energy (J)
! G     0,0 or phase-tuple,0       Gibbs energy (J)
! ..... some extra state variables
! NP    phase-tuple,0              Moles of phase
! BP    phase-tuple,0              Mass of moles (kg)
! Q     phase-tuple,0              Internal stability/RT (dimensionless)
! DG    phase-tuple,0              Driving force/RT (dimensionless)
!....... amounts of components
! N     0,0 or component,0 or phase-tuple,component   Moles of component
! X     component,0 or phase-tuple,component          Mole fraction of component
! B     0,0 or component,0 or phase-tuple,component   Mass of component
! W     component,0 or phase-tuple,component          Mass fraction of component
! Y     phase-tuple,constituent*1                     Constituent fraction
!........ some parameter identifiers
! TC    phase-tuple,0              Magnetic ordering temperature
! BMAG  phase-tuple,0              Aver. Bohr magneton number
! MQ&   phase-tuple,constituent    Mobility
! THET  phase-tuple,0              Debye temperature
! LNX   phase-tuple,0              Lattice parameter
! EC11  phase-tuple,0              Elastic constant C11
! EC12  phase-tuple,0              Elastic constant C12
! EC44  phase-tuple,0              Elastic constant C44
!........ NOTES:
! *1 The phase-tuple is   is structure with 2 integers: phase and comp.set
! *2 The constituent index is 10*species_number + sublattice_number
! *3 S, V, H, A, G, NP, BP, N, B and DG can have suffixes M, W, V, F also
!--------------------------------------------------------------------
! special addition for TQ interface: d2G/dyidyj
! D2G + extended phase index
!------------------------------------
    type(gtp_equilibrium_data), pointer :: ceq
    character(len=24) :: fstring
    integer :: n
    integer :: i
    call c_f_pointer(c_ceq, ceq)
! debug ...
!    call list_conditions(6,ceq)
!    call list_phase_results(1,1,0,6,ceq)
!    write(*,*)'Phase and error code: ',1,gx%bmperr
!    call list_phase_results(2,1,0,6,ceq)
!    write(*,*)'Phase and error code: ',2,gx%bmperr
!    write(*,*)
! end debug
    fstring = c_to_f_string(statvar)
    call tqgetv(fstring, n1, n2, n3, values, ceq)
! debug ...
!    write(*,55)fstring(1:len_trim(fstring)),n1,n2,n3,(values(i),i=1,n3)
!55  format(/'From c_tqgetv: ',a,': ',3i3,6(1pe12.4))
!    write(*,*)
! end debug
    c_ceq = c_loc(ceq)
  end subroutine c_tqgetv

!\begin{verbatim}
  subroutine c_tqgphc1(n1,nsub,cinsub,spix,yfrac,sites,extra,c_ceq)&
 bind(c,name='c_tqgphc1')
! tq_get_phase_constitution
! This subroutine returns the sublattices and constitution of a phase
! n1 is phase tuple index
! nsub is the number of sublattices (1 if no sublattices)
! cinsub is an array with the number of const\EDtuents in each sublattice
! spix is an array with the species index of the constituents in all sublattices
! sites is an array of the site ratios for all sublattices.  
! yfrac is the constituent fractions in same order as in spix
! extra is an array with some extra values: 
!    extra(1) is the number of moles of components per formula unit
!    extra(2) is the net charge of the phase
    implicit none
    !integer n1,nsub,cinsub(*),spix(*)
    integer(c_int), intent(in), value :: n1
    integer(c_int), intent(out) :: nsub
    integer(c_int), intent(out) :: cinsub(*)
    integer(c_int), intent(in) :: spix(*)
    !double precision sites(*),yfrac(*),extra(*)
    real(c_double), intent(in) :: sites(*)
    real(c_double), intent(in) :: yfrac(*)
    real(c_double), intent(in) :: extra(*)
    !type(gtp_equilibrium_data), pointer :: ceq
    type(c_ptr), intent(inout) :: c_ceq  
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq, ceq)
    !call tqgphc1(n1,nsub2,cinsub2,spix2,yfrac2,sites2,extra2,ceq)
    call tqgphc1(n1,nsub,cinsub,spix,yfrac,sites,extra,ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqgphc1

!\begin{verbatim}
  subroutine c_tqsphc1(n1,yfra,extra,c_ceq) bind(c,name='c_tqsphc1')
! tq_set_phase_constitution
! To set the constitution of a phase
! n1 is phase tuple index
! yfra is an array with the constituent fractions in all sublattices
! in the same order as obtained by tqgphc1
! extra is an array with returned values with the same meaning as in tqgphc1
! NOTE The constituents fractions are normallized to sum to unity for each
!      sublattice and extra is calculated by tqsphc1
! T and P must be set as conditions.
    implicit none
    integer(c_int), intent(in), value :: n1
    real(c_double), intent(in) ::yfra(*)
    real(c_double), intent(out) :: extra(*)
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq, ceq)
    call set_constitution(phasetuple(n1)%ixphase,phasetuple(n1)%compset,&
         yfra,extra,ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqsphc1

!\begin{verbatim}
  subroutine c_tqcph1(n1,n2,n3,gtp,dgdy,d2gdydt,d2gdydp,d2gdy2,&
       c_ceq) bind(c,name='c_tqcph1')
! tq_calculate_phase_properties
!vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
! WARNIG: this is not a subroutine to calculate chemical potentials
! those can only be made by an equilibrium calculation.
! The values returned are partial derivatives of G for the phase at the
! current T, P and phase constitution.  The phase constitution has been
! obtained by a previous equilibrium calculation or 
! set by the subroutine tqsphc
! It corresponds to the "calculate phase" command.
!
! NOTE that values are per formula unit divided by RT, 
! divide also by extra(1) in subroutine tqsphc1 to get them per mole component
!
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
! calculate G and some or all derivatives for a phase at current composition
! n1 is the phase tuple index
! n2 is 0 if only G and derivatves wrt T and P, 1 also first drivatives wrt 
!    compositions, 2 if also 2nd derivatives
! n3 is returned as number of constituents (dimension of returned arrays)
! gtp is an array with G, G.T, G:P, G.T.T, G.T.P and G.P.P
! dgdy is an array with G.Yi
! d2gdydt is an array with G.T.Yi
! d2gdydp is an array with G.P.Yi
! d2gdy2 is an array with the upper triangle of the symmetrix matrix G.Yi.Yj 
! reurned in the order:  1,1; 1,2; 1,3; ...           
!                             2,2; 2,3; ...
!                                  3,3; ...
! for indexing one can use the integer function ixsym(i1,i2)
    implicit none
    integer(c_int), intent(in), value :: n1
    integer(c_int), intent(in), value :: n2
    integer(c_int), intent(out) :: n3
    real(c_double), intent(out) :: gtp(6)
    real(c_double), intent(out) :: dgdy(*)
    real(c_double), intent(out) :: d2gdydt(*)
    real(c_double), intent(out) :: d2gdydp(*)
    real(c_double), intent(out) :: d2gdy2(*)
    type(c_ptr), intent(inout) :: c_ceq
!\end{verbatim}
    type(gtp_equilibrium_data), pointer :: ceq
    call c_f_pointer(c_ceq, ceq)
    call tqcph1(n1,n2,n3,gtp,dgdy,d2gdydt,d2gdydp,d2gdy2,ceq)
    c_ceq = c_loc(ceq)
  end subroutine c_tqcph1
  
end module liboctqisoc
