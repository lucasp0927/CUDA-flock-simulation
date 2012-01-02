#include <stdlib.h>
#include <string>
#include <vector>
#include <iostream>
#include <iomanip>
#include "node.h"
#include "tree.h"

#include <sys/time.h>
#include <stdio.h>
#include <unistd.h>

using namespace std;

int main(int argc, char *argv[])
{
  assert(argc == 3);
  int size = atoi(argv[1]);
  cout << "size: " << size << endl;
  int thread_number = atoi(argv[2]);        // thread number has to be power of 2
  pthread_t* thread_handles = (pthread_t*)malloc(thread_number*sizeof(pthread_t));
  
  cout << "construct kd tree with " << thread_number << " threads!" << endl;
  WorldGeo wg(3);
  float ws[6] = {-10.0,10.0,-10.0,10.0,-10.0,10.0};
  wg.setWall(ws);
  KdTree kt(thread_number,size,&wg);
  kt.randInit();

  // ----------------------------------
  struct timeval start, end;
  long mtime, seconds, useconds;    
  gettimeofday(&start, NULL);
  // ---------------------------------
  
  //  kt.printNodes();
  for (int i = 0; i < 10000; ++i)
  {
    cout << i << endl;
    kt.randInit();  
    kt.findRoot();  
    kt.construct();
    ConstructTree(thread_number,&kt,thread_handles);
    //    kt.clearTree();
  }
  
  // ----------------------------------------
  gettimeofday(&end, NULL);
  seconds  = end.tv_sec  - start.tv_sec;
  useconds = end.tv_usec - start.tv_usec;
  mtime = ((seconds) * 1000 + useconds/1000.0) + 0.5;
  printf("Elapsed time: %ld milliseconds\n", mtime);
  // -----------------------------------------
  //  kt.printNodes();
  if (kt.checkTree())
    cout << "kd tree is correct"<<endl;
  else
    cout << "kd tree is incorrect" << endl;
  // float* p = new float[3];
  // p[0] = 1.0;
  // p[1] = 1.0;
  // p[2] = 1.0;
  // kt.findNearest(p);
  // delete [] p;
  // return 0;
}
