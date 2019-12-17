OBJS=liboctq.o liboctqisoc.o
EXE=tqcpptest1
LIBS=../..
FF=gfortran
CC=g++-9
RM=rm
FFOPT= 
MAKE=mingw32-make

.PHONY : all clean

all:$(OBJS) $(EXE)

	 
clean:
	$(RM) -f *.o *.mod $(EXE)

liboctq.o:	liboctq.F90
	cp ../../../liboceqplus.mod .	
	$(FF) -c -g -I$(LIBS) liboctq.F90

liboctqisoc.o:	liboctqisoc.F90
	$(FF) -c -g -I$(LIBS) liboctqisoc.F90

$(EXE): $(OBJS)
	$(CC) -o $(EXE) $(EXE).cpp liboctqisoc.o liboctq.o ../../../liboceq.a -lgfortran -lm -lstdc++ 
