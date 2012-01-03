#ifndef TREE_H_
#define TREE_H_
#define NDEBUG
#include <stdlib.h>
#include <vector>
#include <queue>
#include <stack>
#include <algorithm>
#include <math.h>
#include <iostream>
#include <assert.h>
#include <pthread.h>
#include "node.h"
#include <sys/time.h>

#define SAMPLESIZE 300
using namespace std;

class WorldGeo
{
 public:
 WorldGeo(int dim);
  virtual ~WorldGeo();
  void setWall(float* wall);
  int getDim();
  float getWall(int dim,int m);
 private:
  int _dim;
  float* _wall;                  // order in minx maxx miny maxy ...
};

class KdTree
{
 public:
 KdTree(int thread_n, int size, WorldGeo* wg);
 virtual ~KdTree();
 void findRoot();
 void printNodes();
 void testInit();
 void randInit();
 void* construct_thread(Node* job,struct drand48_data* buffer);
 void construct();
 bool move(int& cur,int d,float dis);
 int goDown(int& cur,int d,float dis);
 void findWithin(int d,float dis);
 void findWithin_slow(int d,float dis); 
 bool checkTree();
 int getRoot();
 Node* getJob();
 void clearTree();
 private:
  Node* _nodes; 
  int _thread_n;
  WorldGeo* _wg;
  int _root,_size,_dim;
  queue<Node*> _unfinish;
};

typedef struct{
  int rank;
  Node* job;
  KdTree* myTree;
} ThreadArgs;

typedef struct{
  int job;
  int cur;
  int first;
} searchJob;

void* launchThread(void* arg);
void ConstructTree(int thread_n,KdTree* myTree,pthread_t* thread_handles);
#endif
