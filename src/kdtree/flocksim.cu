#include "flocksim.h"

FlockSim::FlockSim(int size, int thread_n,WorldGeo& wg,Para para):_size(size),_thread_n(thread_n),_wg(wg)
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
  _depth = new int[_size];
  cudaMalloc((void**)&_dev_pos,_size*_psize*sizeof(float));
  cudaMalloc((void**)&_dev_tree,_size*3*sizeof(int));
  cudaMalloc((void**)&_dev_depth,_size*sizeof(int));  
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
  _para = para;
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
  cudaMemcpyToSymbol("para", &_para, sizeof(Para), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("pos", &_dev_pos, sizeof(float*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("xyz_dir", &_dev_xyz_dir, sizeof(float*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("ang_dir", &_dev_ang_dir, sizeof(float*), size_t(0),cudaMemcpyHostToDevice);    
  cudaMemcpyToSymbol("tree", &_dev_tree, sizeof(int*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("depth", &_dev_depth, sizeof(int*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("size", &_size, sizeof(int), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("psize", &_psize, sizeof(int), size_t(0),cudaMemcpyHostToDevice);    
}

void FlockSim::cpytree2dev()
{
  cudaMemcpy(_dev_tree, _tree, _size*3*sizeof(int),cudaMemcpyHostToDevice);
  cudaMemcpy(_dev_depth, _depth, _size*sizeof(int),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("root", &_root, sizeof(int), size_t(0),cudaMemcpyHostToDevice);  
}

void FlockSim::cpy2host()
{
  cudaMemcpy(_pos, _dev_pos, _size*_psize*sizeof(float),cudaMemcpyDeviceToHost);
  cudaMemcpy(_ang_dir, _dev_ang_dir, _size*3*sizeof(float),cudaMemcpyDeviceToHost);  
}

void FlockSim::depthArray()
{
  _kt->depthArray(_depth);
}

void FlockSim::makeTree()
{
  _kt->findRoot();  
  _kt->construct();
  ConstructTree(_thread_n,_kt,_thread_handles);
  _kt->printNodes();
  // if(_kt->checkTree())
  //   cout << "correct" << endl;
  _root = _kt->getRoot();
  depthArray();
}

__constant__ Para para;
__constant__ float* pos;
__constant__ float* xyz_dir;
__constant__ float* ang_dir;
__constant__ int* tree;
__constant__ int* depth;
__constant__ int size;
__constant__ int psize;
__constant__ int root;          // need to update



__global__  void convertDir()
{
  int num = threadIdx.x + blockDim.x * blockIdx.x;
  if (num < size)
  {
    float r = 0.0;
    for (int i = 0; i < 3; ++i)
    {
      r += xyz_dir[num*3+i]*xyz_dir[num*3+i];
    }
    r = sqrt(r);
    ang_dir[num*3] = -180.0*acos(xyz_dir[num*3]/r)/M_PI;    
    ang_dir[num*3+1] = xyz_dir[num*3+2];
    ang_dir[num*3+2] = -1.0*xyz_dir[num*3+1];    
  }
}


__device__ float3 operator+(const float3 &a, const float3 &b) {
  return make_float3(a.x+b.x, a.y+b.y, a.z+b.z);
}

__device__ float3 operator-(const float3 &a, const float3 &b) {
  return make_float3(a.x-b.x, a.y-b.y, a.z-b.z);
}

__device__ float3 getPos (int &a)
{
  return make_float3(pos[a*psize],pos[a*psize+1],pos[a*psize+2]);
}

__device__ void setPos (int &a,float3 &p)
{
  pos[a*psize] = p.x;
  pos[a*psize+1] = p.y;
  pos[a*psize+2] = p.z;  
}


__device__ float3 getDIr (int &a)
{
  return make_float3(xyz_dir[a*3],xyz_dir[a*3+1],xyz_dir[a*3+2]);
}

__device__ void setDIr (int &a,float3 &p)
{
  xyz_dir[a*3] = p.x;
  xyz_dir[a*3+1] = p.y;
  xyz_dir[a*3+2] = p.z;  
}


__device__ float distance(int &a, int &b)
{
  float3 tmp = getPos(a)-getPos(b);
  return sqrt(tmp.x*tmp.x+tmp.y*tmp.y+tmp.z*tmp.z);
}

__device__ void calculateAvg(int num,Avg &avg)
{
  int cur = root;
  
  // int cur = root;
  // cur = goDown(cur,num,dis);n
  // while (cur != root)
  // {
  //   if (move(cur,num,dis))
  //     cur = goDown(cur,num,dis);
  // }
}

__global__ void flockUpdate()
{
  int num = threadIdx.x + blockDim.x * blockIdx.x;
  if (num < size)
  {
    Avg avg;
    avg.Rpos = make_float3(0,0,0);
    avg.rpos = make_float3(0,0,0);
    avg.Rvel = make_float3(0,0,0);
    avg.rvel = make_float3(0,0,0);
    avg.count = 0;
    calculateAvg(num,avg);
    // use para variable like para.R para.r
    if (num == 0)
    {
      printf("R:%f\n",para.R);
      printf("r:%f\n",para.r);
      printf("root:%d\n",root);
      printf("psize:%d\n",psize);
    }
    
  }
}

void FlockSim::update()
{
    dim3 Grid(Grid_Dim_x, Grid_Dim_y);		//Grid structure
    dim3 Block(Block_Dim_x,Block_Dim_y);	//Block structure, threads/block limited by specific device
    flockUpdate<<<Grid,Block>>>();
    convertDir<<<Grid,Block>>>(); // convert xyz velocity to angle
}
