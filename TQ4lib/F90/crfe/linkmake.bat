REM Copy libraries (compiled without OpenMP) from OC directory

set FF=ifort
set CC=icl
set FFLAGS=/debug
copy ..\..\..\liboceq.lib .
copy ..\..\..\liboceqplus.mod .

REM This is the Fortran part of TQ library for C++
copy ..\liboctq.F90 .
%FF% %FFLAGS% -c liboctq.F90 /I..\..\..\


ifort %FFLAGS% -o tqex1 TQ1-crfe.F90 liboctq.obj liboceq.lib /I..\..\..\

