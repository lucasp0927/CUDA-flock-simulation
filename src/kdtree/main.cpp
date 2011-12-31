#include <stdlib.h>
#include <string>
#include<vector>
#include <iostream>
#include <iomanip>
#include "node.h"
#include "tree.h"

using namespace std;

int main(int argc, char *argv[])
{
  assert(argc == 2);
  int size = atoi(argv[1]);
  cout << "size: " << size << endl;
  int thread_number = 8;        // thread number has to be power of 2
  pthread_t* thread_handles = (pthread_t*)malloc(thread_number*sizeof(pthread_t));
  
  cout << "construct kd tree with " << thread_number << " threads!" << endl;
  WorldGeo wg(3);
  float ws[6] = {-10.0,10.0,-10.0,10.0,-10.0,10.0};
  wg.setWall(ws);
  KdTree kt(thread_number,size,&wg);
  kt.randInit();
  
  
  //  kt.printNodes();
  kt.findRoot();
  kt.construct();
  kt.printNodes();    
  ConstructTree(thread_number,&kt,thread_handles);
  //kt.printNodes();      
  return 0;
}
