from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
#This line only needed if building with NumPy in Cython file.
from numpy import get_include
from os import system
import os 
#set correctly the CC compiler
os.environ["CC"]="gcc"
os.environ["CXX"]="g++"
os.environ["LINKCC"]="gcc"
#copy latest oc library to current directory 
library_copy = 'cp ../liboceq.a .'
print(library_copy)
system(library_copy)
#compile the fortran modules without linking
fortran_mod_comp = 'gfortran -I../../ ../TQ4lib/Cpp/Matthias/liboctqisoc.F90 -c -o liboctqisoc.o -O3 -fPIC'
#fortran_mod_comp = 'ifort /I..\ ..\TQ4lib\Cpp\Matthias\liboctqisoc.F90 -c -o liboctqisoc.obj -O3' 
print (fortran_mod_comp)
system(fortran_mod_comp)
shared_obj_comp = 'gfortran -I../../ ../TQ4lib/Cpp/Matthias/liboctq.F90 -c -o liboctq.o -O3 -fPIC'
#shared_obj_comp = 'ifort /I..\ ..\TQ4lib\Cpp\Matthias\liboctq.F90 -c -o liboctq.obj -O3'
print (shared_obj_comp)
system(shared_obj_comp)

ext_modules=[Extension(# module name:
			'pyoctq',
			#source file:
			['pyoctq.pyx'],
			#other compile args for intel 
			extra_compile_args=[ '-O','-fPIC'],
			#other files to link to
			extra_link_args=['liboctqisoc.o', 'liboctq.o','liboceq.a','-lgfortran'])]
setup(name = 'pyoctq',
      cmdclass = {'build_ext': build_ext},
      # Needed if building with Numpy.
      # This includes the NumPy headers when compiling.
      include_dirs = [get_include()],
      ext_modules = ext_modules)

