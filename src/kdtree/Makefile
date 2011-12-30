# NVCC is path to nvcc. Here it is assumed that /usr/local/cuda is on one's PATH.
NVCC = nvcc
GXX = g++
CUDAPATH = /usr/lib

#NVCCFLAGS = -arch sm_21  -I$(CUDAPATH)/include 
NVCCFLAGS =   -I$(CUDAPATH)/include 
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart  -lm
GXXFLAG = -O3 -lpthread

kdtree:  node.o main.o
	$(GXX) -o kdtree main.o node.o -lpthread

main.o: main.cpp
	$(GXX) $(GXXFLAG) -o main.o -c main.cpp

tree.o: node.cpp node.h
	$(GXX) $(GXXFLAG) -o node.o -c node.cpp

#kdtree.o: kdtree.cu kdtree.h
#	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o kdtree.o -c  kdtree.cu

clean:
	rm *.o
	rm kdtree
