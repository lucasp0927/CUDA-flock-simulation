#include <stdlib.h>
#include <string>
#include <vector>
#include <stack>
#include <iostream>
#include <iomanip>
#include "flocksim.h"

#include <sys/time.h>
#include <stdio.h>
#include <unistd.h>

#include "absGL.cpp"

using namespace std;
FlockSim *fs;
int size;


int main(int argc, char *argv[])
{
  assert(argc == 3);
  size = atoi(argv[1]);
  cout << "size: " << size << endl;
  int thread_number = atoi(argv[2]);
  // init wall
  WorldGeo wg(3);
  float ws[6] = {-650.0,650.0,-400.0,400.0,-100.0,100.0};
  wg.setWall(ws);
  //parameters
  Para para;
  para.R = 100.0;
  para.r = 20.0;
  para.dt = 1.2;
  para.C = 10.0;
  para.A = 5.0;
  para.S = 4;
  // 
  fs =  new FlockSim(size,thread_number,wg,para);
  fs->initializeGpuData();       // only needed one time
  mainGL(argc,argv,ws);
  // while(true)
  // {
  //   fs->_kt->randInit();    
  //   fs->makeTree();
  //   fs->cpytree2dev();
  //   fs->update();
  //   fs->cpy2host();
  // }
  
  //    display();
}
