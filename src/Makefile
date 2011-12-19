#NVCC = /usr/bin/nvcc
GXX = g++
CUDAPATH = /usr/lib
NVCC = nvcc
NVCCFLAGS = -I$(CUDAPATH)/include 
#NVCCFLAGS = -arch sm_21  -I$(CUDAPATH)/include 
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart 
GXXFLAG = -O3

flock:  FlockSim.o main.o
	$(NVCC) -o flock main.o FlockSim.o 

main.o:
	$(GXX) $(GXXFLAG) -o main.o -c main.cpp

FlockSim.o:
	$(NVCC) $(NVCCFLAGS) $(LFLAGS)  -o FlockSim.o -c  FlockSim.cu

clean:
	rm -f *.o
	rm -f flock
