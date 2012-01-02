#include "tree.h"

#ifndef NDEBUG
#include <sys/time.h>
#include <stdio.h>
#include <unistd.h>
#include <stdio.h>
#endif

WorldGeo::WorldGeo(int dim):_dim(dim)
{
  assert(_dim == 2 || _dim == 3);
  _wall = new float[2*_dim];
}

WorldGeo::~WorldGeo()
{
  delete[] _wall;
}
int WorldGeo::getDim(){return _dim;}
float WorldGeo::getWall(int dim,int m){return _wall[dim*2+m];}
void WorldGeo::setWall(float* wall)
{
  for (int i = 0; i < 2*_dim; ++i)
    _wall[i] = wall[i];
}

KdTree::KdTree(int thread_n, int size, WorldGeo* wg):_thread_n(thread_n),_size(size),_wg(wg)
{
  /* pthread handles */
  _nodes = new Node[_size];
  _dim = wg->getDim();
  for (int i = 0; i < _size; ++i)
    _nodes[i].init(_dim,i,_size);
  assert(_size != 0);
  assert(_dim == 2 || _dim == 3);  
}

KdTree::~KdTree()
{
  delete[] _nodes;
}

void KdTree::findRoot()
{
  _root = _nodes[0].median(SAMPLESIZE,NULL,false);
  _nodes[_root].buildRootList(_size);
  _unfinish.push(&(_nodes[_root]));
}

void* KdTree::construct_thread(Node* job,struct drand48_data* buffer)
{
  #ifndef NDEBUG
  int count = 0;
  // ----------------------------------
  struct timeval start, end;
  long mtime, seconds, useconds;    
  gettimeofday(&start, NULL);
  // ---------------------------------  
  #endif
  queue<Node*> unfinish;
  unfinish.push(job);
  assert(unfinish.size() == 1);
  Node* cur;
  Node* left,* right;
  while(unfinish.size() > 0)
  {
    cur = unfinish.front();
    unfinish.pop();
    cur->separateList();
    if (cur->getLList()->size() != 0)
      left = &(_nodes[cur->leftmedian(buffer)]);
    else
      left = NULL;
    
    if (cur->getRList()->size() != 0)
      right = &(_nodes[cur->rightmedian(buffer)]);
    else
      right = NULL;
    cur->setChild(left,right);
    if (left != NULL)
    {
      #ifndef NDEBUG
      count++;
      #endif
      unfinish.push(left);
    }
    if (right != NULL)
    {
      #ifndef NDEBUG
      count++;
      #endif      
      unfinish.push(right);
    }
  };
  #ifndef NDEBUG
  cout << endl;
  cout << "Thread Report"<<endl;  
  // ----------------------------------------
  gettimeofday(&end, NULL);
  seconds  = end.tv_sec  - start.tv_sec;
  useconds = end.tv_usec - start.tv_usec;
  mtime = ((seconds) * 1000 + useconds/1000.0) + 0.5;
  printf("Elapsed time: %ld milliseconds\n", mtime);
  // -----------------------------------------  
  cout << "processed "<< count << " nodes." << endl;
  cout << endl;
  #endif
}

void KdTree::construct()
{
  Node* cur;
  Node* left,*right;
  
  while(_unfinish.size() < _thread_n)
  {
    cur = _unfinish.front();
    _unfinish.pop();
    cur->separateList();
    if (cur->getLList()->size() != 0)
      left = &(_nodes[cur->leftmedian()]);
    else
      left = NULL;
    
    if (cur->getRList()->size() != 0)
      right = &(_nodes[cur->rightmedian()]);
    else
      right = NULL;

    cur->setChild(left,right);
    
    if (left != NULL)
      _unfinish.push(left);
    if (right != NULL)    
      _unfinish.push(right);    
  };
  assert(_unfinish.size() == _thread_n);
}

void KdTree::printNodes()
{
  for (int i = 0; i < _size; ++i)
    cout << _nodes[i] << endl;
}

void KdTree::testInit()
{
  
}

void KdTree::randInit()
{
  srand (time(NULL));
  // position
  for (int i = 0; i < _size; ++i)
    for (int j = 0; j < _dim; ++j)
      _nodes[i].setPos(j,randRange(_wg->getWall(j,0),_wg->getWall(j,1)));
}

int KdTree::getRoot(){return _root;}
Node* KdTree::getJob(){
  Node* tmp;
  tmp = _unfinish.front();
  _unfinish.pop();
  return tmp;
}


bool KdTree::checkTree()
{
  // stupid kd tree check.
  int check;
  int cur,tmp;
  int ax;
  int lr;                       // 0 if left.1 if right
  assert(_dim == 2 || _dim == 3);
  for (int i = 0; i < _size; ++i)
  {
    check = i;
    cur = i;
    while (cur != _root)
    {
      tmp = _nodes[cur].getParent();
      if (cur == _nodes[tmp].getLChild())
        lr = 0;
      if (cur == _nodes[tmp].getRChild())
        lr = 1;
      cur = tmp;
      ax = _nodes[cur].getDepth()%_dim;
      if (lr == 0)
      {
        if (_nodes[check].getPos(check,ax) > _nodes[cur].getPos(cur,ax))
        {
          cout << "check:" << check << " wrong at:" << cur << endl;
          return false;
        }
      }
      else
      {
        if (_nodes[check].getPos(check,ax) < _nodes[cur].getPos(cur,ax))
        {
          cout << "check:" << check << " wrong at:" << cur << endl;          
          return false;
        }
      }
    };
  }
  return true;
}

void KdTree::findNearest(float* x)
{
  int cur = _root;              // current best
  int cur_best;
  int cur_tmp;
  float cur_d,tmp_d;
  int ax;
  while (!_nodes[cur].isEnd())
  {
    ax = _nodes[cur].getDepth()%_dim;
    if (x[ax] > _nodes[cur].getPos(cur,ax))
      cur = _nodes[cur].getRChild();
    else
      cur = _nodes[cur].getLChild();
  };
  cur_tmp = cur;
  cur_d = _nodes[cur].distance(x);
  while (cur_tmp != _root)
  {
    cur_tmp = _nodes[cur_tmp].getParent();
    tmp_d = _nodes[cur_tmp].distance(x);
    if (tmp_d < cur_d)
    {
      cur_d = tmp_d;
      cur = cur_tmp;
    }
    // search other side
    ax = _nodes[cur_tmp].getDepth()%_dim;
    float pd = x[ax] - _nodes[cur_tmp].getPos(cur_tmp,ax);
    pd = (pd < 0.0)? -1.0*pd:pd;
    cout << cur_d <<" "<<pd<<endl;
    if (cur_d > pd)
    {
      cout << "there may be point on other side" << endl;
      
    }
  };
  cout << cur << endl;
}

void* launchThread(void* arg)
{
  // initialize drand
  ThreadArgs * myarg = (ThreadArgs*)arg;
  struct timeval tv;
  gettimeofday(&tv, NULL);
  struct drand48_data drand_buffer;  
  srand48_r(tv.tv_sec * myarg->rank + tv.tv_usec, &drand_buffer);
  
  myarg->myTree->construct_thread(myarg->job, &drand_buffer);
}

void ConstructTree(int thread_n , KdTree* myTree, pthread_t* thread_handles)
{
  ThreadArgs* args = new ThreadArgs[thread_n];
  for (int i = 0; i < thread_n; ++i)
  {
    args[i].rank = i;
    args[i].job = myTree->getJob();
    args[i].myTree = myTree;
  }
  
  for (long thread = 0; thread < thread_n; thread++)
    pthread_create(&thread_handles[thread],NULL, launchThread,(void*) &args[thread]);
  
  for (long thread = 0; thread < thread_n; thread++)
    pthread_join(thread_handles[thread],NULL);    
}



