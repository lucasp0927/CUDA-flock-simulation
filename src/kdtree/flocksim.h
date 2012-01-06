#ifndef FLOCKSIM_H_
#define FLOCKSIM_H_
#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <iostream>
#include <cuda.h>
#include "tree.h"
#include "node.h"
#include <sys/time.h>

using namespace std;

typedef struct
{
  float R,r,dt,C,A,S;
  /* put other parameters here */
}Para;

class FlockSim
{
 public:
  FlockSim(int size, int thread_n,WorldGeo& wg,Para para);
  virtual ~FlockSim();
  void makeTree();              /* construct kdtree */
  void update();                /* update data on GPU */
  void initializeGpuData(); /* copy data to dev that only need to be done one time */
  void cpy2host();              /* copy data to host */
  void cpytree2dev();               /* copy tree and data to dev */
  float getPos(int idx,int ax){return Node::getPos(idx,ax);}
  float getDir(int idx,int ax){return _ang_dir[idx*3+ax];}
  void depthArray();
  //void convertDir(float* _xyz_dir,float* _ang_dir,int size);

  KdTree*   _kt;  
 private:
  WorldGeo _wg;

  int      _psize;
  int       _size;
  int      _thread_n;
  pthread_t* _thread_handles;
  float* _dev_pos;
  int* _dev_tree;
  float* _pos;
  int* _depth;
  int* _dev_depth;
  float* _dev_xyz_dir;
  float* _dev_ang_dir;
  float* _dev_wall;    
  float* _xyz_dir;
  float* _ang_dir;
  int* _tree;
  int Block_Dim_x,Block_Dim_y,Grid_Dim_x,Grid_Dim_y;
  Para _para;
  int _root;
};

typedef struct 
{
  float3 Rpos;
  float3 rpos;
  float3 Rvel;
  float3 rvel;
  int countR;
  int countr;
}Avg;

#endif
