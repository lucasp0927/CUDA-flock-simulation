#include"FlockSim.h"
#include<cuda.h>
#include<stdlib.h>
#include<iostream>
#include<iomanip>
#include<time.h>

//#define NDEBUG
using namespace std;

FlockSim::FlockSim(){
  

}


FlockSim::FlockSim(int size,float wall_size)
{
  wallx = wall_size;
  wally = wall_size;    
  initialFlock(size);
  cudaMalloc((void**)&dev_flock,F.size*sizeof(Agent));
  cudaMemcpy(dev_flock, F.flock, F.size*sizeof(Agent),cudaMemcpyHostToDevice);  
}
__device__ float check_angle (float ang)
{
  if (ang >= (float)360)
    return ang - (float) 360;
  if (ang < 0)
    return ang + (float) 360;
  else
    return ang;
}

__global__ void update_flock_gpu (Agent* F, float wallx,float wally,int size,float dt)
{
  int num = threadIdx.x + blockDim.x * blockIdx.y;
  if (num < size)
  {
    F[num].x += cos(F[num].v)*dt;
    F[num].y += sin(F[num].v)*dt;
    if (F[num].x >= wallx || F[num].x <= (float)0.0)
      F[num].angle = ((float)180.0 - F[num].angle);
    if (F[num].y >= wally || F[num].y <= (float)0.0)
      F[num].angle =  (-(float)1.0* F[num].angle);
    check_angle(F[num].angle);
  }
}



void FlockSim::update_flock(float dt)
{
  update_flock_gpu<<<cusp.Grid,cusp.Block>>>(dev_flock,wallx,wally,F.size,dt);
}

  
void FlockSim::initialFlock(int size)
{
  /*
    space 0~wallx 0~wally 0~wallz
  */
  F.size = size;
  F.flock =(Agent*) malloc(size*sizeof(Agent));
  srand((unsigned)time(0));
  for (int i = 0; i < F.size; ++i)
  {
    F.flock[i].angle = (float)rand()/(float)RAND_MAX*360.0;
    F.flock[i].x = (float)rand()/(float)RAND_MAX*wallx;
    F.flock[i].y = (float)rand()/(float)RAND_MAX*wally;
    F.flock[i].v = (float)rand()/(float)RAND_MAX; // 0~1
  }
}

void FlockSim::printFlock()
{
  cudaMemcpy(F.flock,dev_flock,F.size*sizeof(Agent),cudaMemcpyDeviceToHost);  
//  cout  <<setw(8)<< "n"\
        <<setw(8) << "ang"\
        <<setw(8) << "x"\
        <<setw(8) << "y"\
        <<setw(8) << "v"\    
//        << endl;
//  for (int i = 0; i < F.size; ++i)
//  {
//    cout << setw(8) << i\
         <<setw(8) <<(int) F.flock[i].angle             \
         <<setw(8) << setprecision(2)<< F.flock[i].x    \
         <<setw(8) << F.flock[i].y                      \
         <<setw(8) << F.flock[i].v                      \      
 //        <<endl;
 // }
//  cout << endl;
}


