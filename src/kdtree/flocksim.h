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

class FlockSim
{
 public:
  FlockSim(int size, int thread_n,WorldGeo& wg);
  virtual ~FlockSim();
  void makeTree();              /* construct kdtree */
  void update();                /* update data on GPU */
  void cpy2host();              /* copy data to host */
  void cpy2dev();               /* copy tree and data to dev */
 private:
  WorldGeo _wg;
  KdTree*   _kt;
  int      _psize;
  int       _size;
  int      _thread_n;
  pthread_t* _thread_handles;
  float* _dev_data;
  int* _dev_tree;
  float* _data;
  int* _tree;
};

#endif
