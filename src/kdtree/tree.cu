#include "tree.h"
//#ifndef NDEBUG
#include <stdio.h>
#include <unistd.h>
#include <stdio.h>

WorldGeo::WorldGeo(int dim):_dim(dim)
{
  assert(_dim == 2 || _dim == 3);
  _wall = new float[2*_dim];
}

WorldGeo::~WorldGeo()
{
  //delete[] _wall;
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
  _nodes = NULL;
}

void KdTree::findRoot()
{
  _root = _nodes[0].median(SAMPLESIZE,NULL,false);
  _nodes[_root].buildRootList(_size);
  _unfinish.push(&(_nodes[_root]));
}

void* KdTree::construct_thread(Node* job,struct drand48_data* buffer)
{
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
      unfinish.push(left);
    }
    if (right != NULL)
    {
      unfinish.push(right);
    }
  };
  return NULL;
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
  }
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
  for (int i = 0; i < _size; ++i)
    for (int j = 0; j < _dim; ++j)
      _nodes[i].setDir(j,randRange(-2.0,2.0));  
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
      assert(check>= 0 && check < _size);
      assert(cur>= 0 && cur < _size);                        
      ax = Node::getDepth(cur)%_dim;
      if (lr == 0)
      {
        assert(check>= 0 && check < _size);
        assert(cur>= 0 && cur < _size);              
        if (Node::getPos(check,ax) > Node::getPos(cur,ax))
        {
          cout << "check:" << check << " wrong at:" << cur << endl;
          return false;
        }
      }
      else
      {
        assert(check>= 0 && check < _size);
        assert(cur>= 0 && cur < _size);                            
        if (Node::getPos(check,ax) < Node::getPos(cur,ax))
        {
          cout << "check:" << check << " wrong at:" << cur << endl;          
          return false;
        }
      }
    };
  }
  return true;
}

void KdTree::findWithin_slow(int d,float dis)
{
  int count = 0;
  cout << "slow version"<<endl;
  for (int i = 0; i < _size; ++i)
  {
    if (i != d)
    {
      if (_nodes[d].distance(i) < dis)
      {
        //cout << i << endl;
        count++;
      }
    }
  }
  cout << count<<endl;
}

int KdTree::goDown(int& cur,int& d,float& dis)
{
  int ax;
  int tmp;
  int count = 0;
  if (cur != d && _nodes[d].distance(cur) < dis)
  {
    //cout << cur << endl;
    count++;
  }  
  while (!_nodes[cur].isEnd())
  {
    ax = Node::getDepth(cur)%_dim;
    assert(d>= 0 && d < _size);
    assert(cur>= 0 && cur < _size);                    
    if (Node::getPos(d,ax) > Node::getPos(cur,ax))
    {
      tmp = _nodes[cur].getRChild();
      if (tmp == cur)
        cur = _nodes[cur].getLChild();
      else cur = tmp;
    }
    else
    {
      tmp = _nodes[cur].getLChild();
      if (tmp == cur)
        cur = _nodes[cur].getRChild();
      else cur = tmp;          
    }
    if (cur != d && _nodes[d].distance(cur) < dis)
    {
      //cout << cur << endl;
      count++;
    }
  }
  return count;
}

bool KdTree::move(int& cur , int& d,float& dis)
{
  assert(d>= 0 && d < _size);                
  int parent = _nodes[cur].getParent();
  int ax = Node::getDepth(parent)%_dim;
  float d_ax = Node::getPos(d,ax);
  assert(parent>= 0 && parent < _size);                  
  float curp_ax = Node::getPos(parent,ax);

  if (fabs(d_ax - curp_ax) <= dis)
  {
    int rc = _nodes[parent].getRChild();
    int lc = _nodes[parent].getLChild();              
    if (d_ax > curp_ax)
    {
      if (cur == rc && parent != lc)
      {
        cur = lc;
        return true;
      }
      else
      {
        cur = parent;
        return false;
      }
    }
    else
    {
      if (cur == lc && parent != rc)
      {
        cur = rc;
        return true;
      }
      else
      {
        cur = parent;
        return false;
      }
    }
  }
  else
  {
    cur= parent;
    return false;
  }
}

void KdTree::findWithin(int d,float dis)
{
  int count = 0;
  int cur = _root;
  count += goDown(cur,d,dis);
  while (cur != _root)
  {
    if (move(cur,d,dis))
    {
      count += goDown(cur,d,dis);
    }
  }
  cout << count << endl;
}

int KdTree::deepest()
{
  int d = 0;
  int tmp;
  for (int i = 0; i < _size; ++i)
  {
    tmp = Node::getDepth(i);
    if (tmp > d)
      d = tmp;
  }
  return d;
}
void KdTree::depthArray(int* arr)
{
  for (int i = 0; i < _size; ++i)
    arr[i] = Node::getDepth(i);
}

void KdTree::clearTree()
{
  for (int i = 0; i < _size; ++i)
    _nodes[i].clear();
}

void* launchThread(void* arg)
{
  // initialize drand
  ThreadArgs * myarg = (ThreadArgs*)arg;
  struct timeval tv;
  gettimeofday(&tv, NULL);
  struct drand48_data drand_buffer;  
  srand48_r(tv.tv_sec * myarg->rank + tv.tv_usec, &drand_buffer);
  cout << "        thread" <<myarg->rank<<endl;
  myarg->myTree->construct_thread(myarg->job, &drand_buffer);
  cout << "        return" << myarg->rank<<endl;
  return NULL;
}

void ConstructTree(int thread_n , KdTree* myTree, pthread_t* thread_handles)
{
  ThreadArgs* args = new ThreadArgs[thread_n];
  for (int i = 0; i < thread_n; ++i)
  {
    args[i].rank = i;
    args[i].job = myTree->getJob();
    //    assert(args[i].job->getIdx() >= 0&&args[i].job->getIdx() <10000);
    args[i].myTree = myTree;
  }
  int thread;
  void                 *status[thread_n];
  //    cerr <<"      start thread"<<endl;
  for (thread = 0; thread < thread_n; thread++)
  {
    pthread_create(&thread_handles[thread],NULL, launchThread,(void*) &args[thread]);
  }
  
  //    cerr <<"      join thread"<<endl;
  for (thread = 0; thread < thread_n; thread++)
  {
    pthread_join(thread_handles[thread],&status[thread]);
  }
  for (int i=0; i <thread_n; ++i) {
    if (status[i] != NULL) {
      printf("Unexpected thread status\n");
    }
  }  
  //  cerr << "       delete"<<endl;
  delete [] args;
  args = NULL;
}



