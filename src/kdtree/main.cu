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

using namespace std;

int main(int argc, char *argv[])
{
  assert(argc == 3);
  int size = atoi(argv[1]);
  cout << "size: " << size << endl;
  int thread_number = atoi(argv[2]);        // thread number has to be power of 2
  
  // init
  WorldGeo wg(3);
  float ws[6] = {-10.0,10.0,-10.0,10.0,-10.0,10.0};
  wg.setWall(ws);
  //

  FlockSim fs = FlockSim(size,thread_number,wg);

// ----------------------------------
  struct timeval start, end;
  long mtime, seconds, useconds;    
  gettimeofday(&start, NULL);
  // ---------------------------------
  fs.makeTree();  
  fs.cpy2dev();
  fs.update();
  fs.cpy2host();
  // ----------------------------------------
  gettimeofday(&end, NULL);
  seconds  = end.tv_sec  - start.tv_sec;
  useconds = end.tv_usec - start.tv_usec;
  mtime = ((seconds) * 1000 + useconds/1000.0) + 0.5;
  printf("Elapsed time: %ld milliseconds\n", mtime);
  // -----------------------------------------  

}
