#include <stdlib.h>
#include <string>
#include <vector>
#include <stack>
#include <iostream>
#include <iomanip>
#include "flocksim.h"

#include <sys/time.h>
#include <stdio.h>

using namespace std;
FlockSim *fs;
int flocksize;
extern int sepmode;
#include "absGL.cpp"


int main(int argc, char *argv[])
{
  assert(argc == 4);
  flocksize = atoi(argv[1]);
  cout << "size: " << flocksize << endl;
  int thread_number = atoi(argv[2]);
    // init wall
  WorldGeo wg(3);
  float ws[6] = {-650.0,650.0,-470.0,470.0,-200.0,200.0};
  wg.setWall(ws);
  //parameters
  Para para;
  para.R = 100.0;
  para.r = 20.0;
  para.dt = 1.2;
  para.C = 10.0;
  para.A = 5.0;
  para.S = 4;
  para.sepmode=atoi(argv[3]);
  // 
  fs =  new FlockSim(flocksize,thread_number,wg,para);
  fs->initializeGpuData();       // only needed one time
  fs->_kt->clearTree();
  // while (true)
  // {
  // fs->makeTree();
  // fs->cpytree2dev();
  // fs->update();
  // fs->cpy2host();
  // fs->_kt->randInit();  
  // fs->_kt->clearTree();
  // }
  mainGL(argc,argv,ws);


  // while(true)
  // {
  //   fs->_kt->randInit();    
  //   fs->makeTree();
  //   fs->cpytree2dev();
  //   fs->update();
  //   fs->cpy2host();
  // }

}
