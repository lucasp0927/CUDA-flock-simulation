#include "flocksim.h"

FlockSim::FlockSim(int size, int thread_n,WorldGeo& wg):_size(size),_thread_n(thread_n),_wg(wg)
{
  _thread_handles = (pthread_t*)malloc(_thread_n*sizeof(pthread_t));
  cout << "Using " << _thread_n << " threads!" << endl;
  _kt = new KdTree(_thread_n,size,&_wg);
  cout << "random initialize"<<endl;
  _kt->randInit();
  cout << "allocate memory on GPU"<< endl;
  _psize = Node::getPSize();
  _data = Node::getData();
  _tree = Node::getTree();  
  cudaMalloc((void**)&_dev_data,_size*_psize*sizeof(float));
  cudaMalloc((void**)&_dev_tree,_size*3*sizeof(int));    
}

FlockSim::~FlockSim()
{
  cudaFree(&_dev_data);         // will render need this mem?
  cudaFree(&_dev_tree);  
}

void FlockSim::cpy2dev()
{
  cudaMemcpy(_dev_data, _data, _size*_psize*sizeof(float),cudaMemcpyHostToDevice);
  cudaMemcpy(_dev_tree, _tree, _size*3*sizeof(int),cudaMemcpyHostToDevice);      
}

void FlockSim::cpy2host()
{
  cudaMemcpy(_data, _dev_data, _size*_psize*sizeof(float),cudaMemcpyDeviceToHost);
}

void FlockSim::makeTree()
{
  _kt->findRoot();  
  _kt->construct();
  ConstructTree(_thread_n,_kt,_thread_handles);
}

void FlockSim::update()
{
  
}
