#include "tree.h"
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

void* KdTree::construct_thread(Node* job)
{
  #ifndef NDEBUG
  int count = 0;
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
      left = &(_nodes[cur->leftmedian()]);
    else
      left = NULL;
    
    if (cur->getRList()->size() != 0)
      right = &(_nodes[cur->rightmedian()]);
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
  cout << "process "<< count << " nodes." << endl;
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
  //  srand (time(NULL));
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

void* launchThread(void* arg)
{
  ThreadArgs * myarg = (ThreadArgs*)arg;
  myarg->myTree->construct_thread(myarg->job);
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
  {
    pthread_create(&thread_handles[thread],NULL, launchThread,(void*) &args[thread]);
  }
  
  for (long thread = 0; thread < thread_n; thread++)
    pthread_join(thread_handles[thread],NULL);    
}



