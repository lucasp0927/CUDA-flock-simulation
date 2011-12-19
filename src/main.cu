#include<stdlib.h>
#include<iostream>
#include"FlockSim.h"

#include <GL/glut.h>
#include <cuda.h>
#include <cudaGL.h>

using namespace std;

int main(int argc, char *argv[])
{
  int flock_size = atoi(argv[1]);
  int wall_size = atoi(argv[2]);  
  cout << "Simulate a flock with " << flock_size << " agents." << endl;
  FlockSim Fsim(flock_size,wall_size);
  Fsim.printFlock();
  
  return 0;
}
