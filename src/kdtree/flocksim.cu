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
  _pos = Node::getPos();
  _xyz_dir = Node::getDir();  
  _tree = Node::getTree();  
  cudaMalloc((void**)&_dev_pos,_size*_psize*sizeof(float));
  cudaMalloc((void**)&_dev_tree,_size*3*sizeof(int));
  cudaMalloc((void**)&_dev_xyz_dir,_size*3*sizeof(int));
  cudaMalloc((void**)&_dev_ang_dir,_size*3*sizeof(int));  
  _ang_dir = new float[_size*3*sizeof(float)];
  // cuda grid sructure
  Block_Dim_x = 512;
  Block_Dim_y = 1;  
  Grid_Dim_x = (int)_size/Block_Dim_x +1;
  if (Grid_Dim_x > 65565)
    cerr << "too many block!" << endl;
  Grid_Dim_y = 1;
}

FlockSim::~FlockSim()
{
  cudaFree(&_dev_pos);         // will render need this mem?
  cudaFree(&_dev_tree);
  cudaFree(&_dev_xyz_dir);
  cudaFree(&_dev_ang_dir);  
  delete [] _ang_dir;
}

void FlockSim::initializeGpuData()
{
  cudaMemcpy(_dev_pos, _pos, _size*_psize*sizeof(float),cudaMemcpyHostToDevice);
  cudaMemcpy(_dev_xyz_dir, _xyz_dir, _size*3*sizeof(float),cudaMemcpyHostToDevice);    
}

void FlockSim::cpytree2dev()
{
  cudaMemcpy(_dev_tree, _tree, _size*3*sizeof(int),cudaMemcpyHostToDevice);      
}

void FlockSim::cpy2host()
{
  cudaMemcpy(_pos, _dev_pos, _size*_psize*sizeof(float),cudaMemcpyDeviceToHost);
  cudaMemcpy(_ang_dir, _dev_ang_dir, _size*3*sizeof(float),cudaMemcpyDeviceToHost);  
}

void FlockSim::makeTree()
{
  _kt->findRoot();  
  _kt->construct();
  ConstructTree(_thread_n,_kt,_thread_handles);
  if(_kt->checkTree())
    cout << "correct" << endl;
}
__global__  void convertDir(float* _xyz_dir,float* _ang_dir,int size)
{
  int num = threadIdx.x + blockDim.x * blockIdx.x;
  if (num < size)
  {
    float r = 0.0;
    for (int i = 0; i < 3; ++i)
    {
      r += _xyz_dir[num*3+i]*_xyz_dir[num*3+i];
    }
    r = sqrt(r);
    _ang_dir[num*3] = -180.0*acos(_xyz_dir[num*3]/r)/M_PI;    
    _ang_dir[num*3+1] = _xyz_dir[num*3+2];
    _ang_dir[num*3+2] = -1.0*_xyz_dir[num*3+1];    
  }
}

__device__ void calculate(int root,int num,float R,float r,float3* avgRpos,float3* rpos,float3* avgRvel, float3* avgrvel)
{
  int cur = root;
  cur = goDown(cur,num,dis);
  while (cur != root)
  {
    if (move(cur,num,dis))
      cur = goDown(cur,num,dis);
  }
}

__global__ void flockUpdate(float* _pos,float* _xyz_dir,int size)
{
  int num = threadIdx.x + blockDim.x * blockIdx.x;
  if (num < size)
  {
    float3 avgRpos,rpos,avgRvel,avgrvel;    
    calculate(num,R,r,&avgRpoa,&rpos,&avgRvel,&avgrvel);
    
  }
}


void FlockSim::update()
{
    dim3 Grid(Grid_Dim_x, Grid_Dim_y);		//Grid structure
    dim3 Block(Block_Dim_x,Block_Dim_y);	//Block structure, threads/block limited by specific device

    
    convertDir<<<Grid,Block>>>(_dev_xyz_dir,_dev_ang_dir,_size); // convert xyz velocity to angle
}
