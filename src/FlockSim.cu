#include"FlockSim.h"
#include<cuda.h>
#include<stdlib.h>
#include<iostream>
#include<iomanip>
#include<time.h>

//#define NDEBUG
using namespace std;

void initialFlock(Flock &F,int size,float wallsize)
{
  /*
    space 0~wallx 0~wally 0~wallz
  */
  F.size = size;
  F.wallx = wallsize;
  F.wally = wallsize;
  F.flock =(Agent*) malloc(size*sizeof(Agent));
  srand((unsigned)time(0));
  for (int i = 0; i < F.size; ++i)
  {
    F.flock[i].angle = (float)rand()/(float)RAND_MAX*360.0;
    F.flock[i].x = (float)rand()/(float)RAND_MAX*F.wallx;
    F.flock[i].y = (float)rand()/(float)RAND_MAX*F.wally;        
  }
}

void printFlock(Flock &F)
{
  cout  <<setw(8)<< "n"\
        <<setw(8) << "ang"\
        <<setw(8) << "x"\
        <<setw(8) << "y"\
        << endl;
  for (int i = 0; i < F.size; ++i)
  {
    cout << setw(8) << i\
         <<setw(8) <<(int) F.flock[i].angle             \
         <<setw(8) << setprecision(2)<< F.flock[i].x    \
         <<setw(8) << F.flock[i].y                      \
         <<endl;
  }
}


