#ifndef FLOCKSIM_H_
#define FLOCKSIM_H_

#include<cuda.h>

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
  }
  
};


  
class FlockSim
{
 private:
  Flock F;
  float wallx,wally;
  void initialFlock(int size);
  //  CudaSpec cusp();
 public:
  FlockSim(int size,float wall_size);
  virtual ~FlockSim()
  {
    free(F.flock);
  };
  void printFlock();  
};
  


#endif
