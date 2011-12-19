#NVCC = /usr/bin/nvcc
GXX = g++
CUDAPATH = /usr/lib/cuda
NVCC = nvcc
NVCCFLAGS = -I$(CUDAPATH)/include 
#NVCCFLAGS = -arch sm_21  -I$(CUDAPATH)/include 
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart 
GXXFLAG = -O3
FLOCKSIZE = 10
WALLSIZE = 480

flock:  FlockSim.o main.o
	$(NVCC) -o flock main.o FlockSim.o 

main.o:
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o main.o -c main.cu

FlockSim.o:
	$(NVCC) $(NVCCFLAGS) $(LFLAGS)  -o FlockSim.o -c  FlockSim.cu

run:
	./flock $(FLOCKSIZE) $(WALLSIZE)

clean:
	rm -f *.o
	rm -f flock
