#ifndef FLOCKSIM_H_
#define FLOCKSIM_H_

#include<cuda.h>

using namespace std;

typedef struct
{
  float angle; //360
  float x,y;
  float v;  
} Agent;
  
typedef struct
{
  int size;//number of agents
  Agent* flock;
} Flock;

class CudaSpec
{
 public:
  int Block_Dim_x,Block_Dim_y,Grid_Dim_x,Grid_Dim_y;
  dim3 Grid;
  dim3 Block;
  
  CudaSpec()
  {
    Block_Dim_x = 512;
    Block_Dim_y = 1;  
    Grid_Dim_x = 100;
    Grid_Dim_y = 1;
    dim3 Grid(Grid_Dim_x, Grid_Dim_y);		//Grid structure
    dim3 Block(Block_Dim_x,Block_Dim_y);	//Block structure, threads/block limited by specific device      
  }
};


  
class FlockSim
{
 private:
  //  __global__ void update_flock_gpu (Agent* dev_flock, float wallx,float wally,int size,float dt);
  void initialFlock(int size);
  /* data member */
//  Flock F;
  float wallx,wally;
  CudaSpec cusp;
    
 public:
  FlockSim(int size,float wall_size);
  virtual ~FlockSim()
  {
    cudaFree(&dev_flock);
    free(F.flock);
  };
  void printFlock();
  void copy2host();
  void update_flock (float dt);  
  /* data type */
  Flock F;
  Agent* dev_flock;
};
  


#endif
