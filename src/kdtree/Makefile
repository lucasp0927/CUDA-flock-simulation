# NVCC is path to nvcc. Here it is assumed that /usr/local/cuda is on one's PATH.
NVCC = nvcc
GXX = g++
CUDAPATH = /usr/lib

#NVCCFLAGS = -arch sm_21  -I$(CUDAPATH)/include 
NVCCFLAGS =   -I$(CUDAPATH)/include 
LFLAGS = -L$(CUDAPATH)/lib64 -lcuda -lcudart  -lm
GXXFLAG = -O3 -lm -lpthread

kdtree:  node.o main.o tree.o
	$(GXX) $(GXXFLAG) -o kdtree main.o node.o tree.o -lpthread

main.o: main.cpp
	$(GXX) $(GXXFLAG) -o main.o -c main.cpp

node.o: node.cpp node.h
	$(GXX) $(GXXFLAG) -o node.o -c node.cpp

tree.o: tree.cpp tree.h
	$(GXX) $(GXXFLAG) -o tree.o -c tree.cpp

#kdtree.o: kdtree.cu kdtree.h
#	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o kdtree.o -c  kdtree.cu

clean:
	rm *.o
	rm kdtree
