#NVCC = /usr/bin/nvcc
GXX = g++
CUDAPATH = /usr/lib

NVCCFLAGS = -I$(CUDAPATH)/include 
#NVCCFLAGS = -arch sm_21  -I$(CUDAPATH)/include 
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart 
GXXFLAG = -O3

flock:  FlockSim.o main.o
	$(NVCC) -o ../bin/flock main.o FlockSim.o  -lgmp -lgmpxx

main.o:
	$(GXX) $(GXXFLAG) -o main.o -c main.cpp

FlockSim.o:
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o FlockSim.o -c  FlockSim.cu

clean:
	rm *.o
	../bin/*
