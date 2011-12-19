#include<stdlib.h>
#include<iostream>
#include"FlockSim.h"

using namespace std;

int main(int argc, char *argv[])
{
  int flock_size = atoi(argv[1]);
  int wall_size = atoi(argv[1]);  
  cout << "Simulate a flock with " << flock_size << " agents." << endl;
  Flock F;
  initialFlock(F,flock_size,(float) wall_size);
  printFlock(F);
  
  free(F.flock);
  return 0;
}
