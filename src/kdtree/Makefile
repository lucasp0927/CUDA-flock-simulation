# NVCC is path to nvcc. Here it is assumed that /usr/local/cuda is on one's PATH.
NVCC = nvcc
GXX = g++
CUDAPATH = /usr/lib

#NVCCFLAGS = -arch sm_21  -I$(CUDAPATH)/include 
NVCCFLAGS =   -I$(CUDAPATH)/include 
LFLAGS = #-L$(CUDAPATH)/lib64 -lcuda -lcudart -lm -O3 -lpthread
GXXFLAG = -O3 -lm -lpthread -Xcompiler -fopenmp
OPENFLAG = -L/usr/lib -lGL -lglut -lGLEW

kdtree:  main.o flocksim.o node.o tree.o
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) $(OPENFLAG) -o kdtree main.o flocksim.o node.o tree.o -lpthread

main.o: main.cu
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) $(OPENFLAG) -o main.o -c main.cu

node.o: node.cu node.h
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o node.o -c node.cu

tree.o: tree.cu tree.h
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o tree.o -c tree.cu

flocksim.o: flocksim.cu flocksim.h tree.o node.o
	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o flocksim.o -c flocksim.cu


#kdtree.o: kdtree.cu kdtree.h
#	$(NVCC) $(NVCCFLAGS) $(LFLAGS) -o kdtree.o -c  kdtree.cu

clean:
	rm *.o
	rm kdtree
