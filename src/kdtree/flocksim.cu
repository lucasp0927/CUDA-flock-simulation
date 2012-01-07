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
  cudaMalloc((void**)&_dev_wall,6*sizeof(float));
  cudaMalloc((void**)&_dev_isend,_size*sizeof(int));    
  _ang_dir = new float[_size*3*sizeof(float)];

  // cuda grid sructure
  Block_Dim_x = 128;
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
  cudaFree(&_dev_isend);  
  cudaFree(&_dev_xyz_dir);
  cudaFree(&_dev_ang_dir);
  cudaFree(&_dev_depth);
  cudaFree(&_dev_wall);
  delete [] _ang_dir;
  delete [] _depth;
}

void FlockSim::initializeGpuData()
{
  cudaMemcpy(_dev_pos, _pos, _size*_psize*sizeof(float),cudaMemcpyHostToDevice);
  cudaMemcpy(_dev_xyz_dir, _xyz_dir, _size*3*sizeof(float),cudaMemcpyHostToDevice);
  cudaMemcpy(_dev_wall, _wg._wall , 6*sizeof(float),cudaMemcpyHostToDevice);  
  cudaMemcpyToSymbol("para", &_para, sizeof(Para), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("pos", &_dev_pos, sizeof(float*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("xyz_dir", &_dev_xyz_dir, sizeof(float*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("ang_dir", &_dev_ang_dir, sizeof(float*), size_t(0),cudaMemcpyHostToDevice);    
  cudaMemcpyToSymbol("tree", &_dev_tree, sizeof(int*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("depth", &_dev_depth, sizeof(int*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("size", &_size, sizeof(int), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("psize", &_psize, sizeof(int), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("wall", &(_dev_wall), sizeof(float*), size_t(0),cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol("isend", &_dev_isend, sizeof(int*), size_t(0),cudaMemcpyHostToDevice);  
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
  //_kt->printNodes();
  // if(_kt->checkTree())
  //   cout << "correct" << endl;
  _root = _kt->getRoot();
}

__constant__ Para para;
__constant__ float* pos;
__constant__ float* xyz_dir;
__constant__ float* ang_dir;
__constant__ int* tree;
__constant__ int* depth;
__constant__ int size;
__constant__ int psize;
__constant__ float* wall;
__constant__ int root;          // need to update
__constant__ int* isend;


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

__device__ float3 operator/(const float3 &a, const float &b) {
   if(b!=0){
      return make_float3(a.x/b, a.y/b, a.z/b);
   }
   else{
      return make_float3(0,0,0);
   }
}

__device__ float3 operator*(const float3 &a, const float &b) {
  return make_float3(a.x*b, a.y*b, a.z*b);
}

inline __device__ float3 getPos (int &a)
{
  return make_float3(pos[a*psize],pos[a*psize+1],pos[a*psize+2]);
}

inline __device__ float getPosAx (int &a, int &ax){  return pos[a*psize+ax];}

inline __device__ void setPos (int &a,float3 p)
{
  pos[a*psize] = p.x;
  pos[a*psize+1] = p.y;
  pos[a*psize+2] = p.z;  
}


inline __device__ float3 getDir (int &a)
{
  return make_float3(xyz_dir[a*3],xyz_dir[a*3+1],xyz_dir[a*3+2]);
}

inline __device__ void setDir (int &a,float3 &p)
{
  xyz_dir[a*3] = p.x;
  xyz_dir[a*3+1] = p.y;
  xyz_dir[a*3+2] = p.z;  
}

inline __device__ int getLChild(int &num){  return tree[num*3+1];}
inline __device__ int getRChild(int &num){  return tree[num*3+2];}
inline __device__ int getParent(int &num){return tree[num*3];}
inline __device__ int getDepth(int &num){  return depth[num];}
inline __device__ bool isEnd(int &num)
{
  if (isend[num] == 1) return true;
  else if (isend[num] == 0) return false;
  else if (num==getLChild(num) && num==getRChild(num))
  {
    isend[num] = 1;
    return true;
  }
  else
  {
    isend[num] = 0;
    return false;
  }
}

inline __host__ __device__ float dot(float3 a, float3 b)
{ 
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

inline __device__ float dis(int &a, int &b)
{
  float3 tmp = getPos(a)- getPos(b);
  return sqrtf(dot(tmp, tmp));  
}

__device__ void goDown(int &cur,int& num,Avg& avg)
{
  int ax,tmp;
  float dist;
  dist = dis(cur,num);
  if (cur != num &&  dist< para.R)
  {
    avg.countR++;
    avg.Rpos = avg.Rpos + getPos(cur);
    avg.Rvel = avg.Rvel + getDir(cur);    
    if (dist < para.r)
    {
      avg.countr++;
      avg.rpos = avg.rpos +(getPos(num)-getPos(cur))/(dist/10);
      //avg.rvel = avg.rvel + getDir(num);
    }
  }
  int i=0;
  while(!isEnd(cur)&&i<1)
  {
    ax = getDepth(cur)%3;
    if (getPosAx(num,ax)>getPosAx(cur,ax))
    {
      tmp = getRChild(cur);
     if (tmp == cur)
        cur = getLChild(cur);
      else cur = tmp;
    }
    else
    {
      tmp = getLChild(cur);
      if (tmp == cur)
        cur = getRChild(cur);
      else cur = tmp;      
    }
    dist = dis(cur,num);    
    if (cur != num &&  dist< para.R)
    {
      avg.countR++;
      avg.Rpos = avg.Rpos + getPos(cur);
      avg.Rvel = avg.Rvel + getDir(cur);    
      if (dist < para.r)
      {
        avg.countr++;
        avg.rpos = avg.rpos +(getPos(num)-getPos(cur))/(dist/10);
     //   avg.rpos = avg.rpos + getPos(num)/dist;
      //  avg.rvel = avg.rvel + getDir(num);
      }
    }
    //i++;
  }
}
__device__ bool move(int &cur,int &num)
{
  int parent = getParent(cur);
  int ax = getDepth(parent)%3;
  float d_ax = getPosAx(num,ax);
  float curp_ax = getPosAx(parent,ax);
  if (fabs(d_ax - curp_ax) <= para.R)
  {
    int rc = getRChild(parent);
    int lc = getLChild(parent);              
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

// normalize
inline __host__ __device__ float3 normalize(float3 v)
{
    float invLen = 1.0f / sqrtf(dot(v, v));
    return v * invLen;
}
// __device__ float3 normalize(float3 a)
// {
//   float tx,ty,tz;
//   float t;
//   t = sqrt(a.x*a.x+a.y*a.y+a.z*a.z);
//   if(t!=0){
//   tx = a.x/t;
//   ty = a.y/t;
//   tz = a.z/t;
//   }
//   else{
//   tx=0,ty=0,tz=0;
//   }
//   return make_float3(tx,ty,tz);
// }

__device__ void calculateAvg(int num,Avg &avg)
{
  int cur = root;
  goDown(cur,num,avg);
  while (cur != root)
  {
    if (move(cur,num))
      goDown(cur,num,avg);
  }
}
__device__ void wallCheck(int& num,float3 &pos,float3 &dir)
{
  if(pos.x < wall[0] || pos.x > wall[1])
    dir.x = dir.x*-1.0;
  if(pos.y < wall[2] || pos.y > wall[3])
    dir.y = dir.y*-1.0;
  if(pos.z < wall[4] || pos.z > wall[5])
    dir.z = dir.z*-1.0;  
  
  if(pos.x<wall[0])
    pos.x=wall[0];
  if(pos.x>wall[1])
    pos.x=wall[1];
  if(pos.y<wall[2])
    pos.y=wall[2];
  if(pos.y>wall[3])
    pos.y=wall[3];
  if(pos.z<wall[4])
    pos.z=wall[4];
  if(pos.z>wall[5])
    pos.z=wall[5];
}



__global__ void initIsend()
{
  int num = threadIdx.x + blockDim.x * blockIdx.x;
  if (num < size)
  {
    isend[num] = 2;
  }
  __syncthreads();
}

__global__ void flockUpdate()
{
  int num = threadIdx.x + blockDim.x * blockIdx.x;
  if (num < size)
  {
    float3 tmp;
    float3 tmpv;
    tmp = getPos(num);
    tmpv = getDir(num);
//    wallCheck(num,tmp,tmpv);
    __syncthreads();
    Avg avg;
    avg.Rpos = make_float3(0,0,0);
    avg.rpos = make_float3(0,0,0);
    avg.Rvel = make_float3(0,0,0);
    avg.rvel = make_float3(0,0,0);
    avg.countR = 0;
    avg.countr = 0;    
    calculateAvg(num,avg);
    if(avg.countR>0){
       avg.Rpos = avg.Rpos/avg.countR;
       avg.Rvel = avg.Rvel/avg.countR;
    }
    if(avg.countr>0){
       avg.rpos = avg.rpos;///avg.countr;
    //   avg.rvel = avg.rvel/avg.countr;
    }
    // -----------------------------
    // please update position here
    //------------------------------
    // avg.Rpos average position within R
    // avg.rpos pos/r  position within r
    // avg.Rvel average velocity within R
    // avg.rvel average velocity within r    
    // above variable are float3.
    // wall[0~5]
    tmpv=normalize(tmpv);
    if (avg.countR>0)
    {
//	tmpv=normalize(avg.Rpos-tmp);
        tmpv = normalize(tmpv + normalize(avg.Rpos - tmp)*para.C);
        tmpv = normalize(tmpv + normalize(avg.Rvel)*para.A);    
     
  
//	tmpv=normalize(tmpv+normalize(avg.Rpos-tmp));
  //    tmpv = normalize(tmpv + normalize(avg.Rvel));    
    
    if (avg.countr>0){
 //     tmpv = normalize(avg.rpos)*para.S;
     // tmpv
     tmpv =/* normalize(tmpv + */normalize(avg.rpos)*para.S;
      //tmpv = tmpv+normalize(make_float3(1,0,0))*para.S;
      //tmpv = normalize(tmpv);
	
    }

    }
    wallCheck(num,tmp,tmpv);
    tmp = tmp+(tmpv*para.dt);
    setPos(num,tmp);
    setDir(num,tmpv); 
  }
  
  __syncthreads();
}

void FlockSim::update()
{
  dim3 Grid(Grid_Dim_x, Grid_Dim_y);		//Grid structure
  dim3 Block(Block_Dim_x,Block_Dim_y);	//Block structure, threads/block limited by specific device
  initIsend<<<Grid,Block>>>();  
  flockUpdate<<<Grid,Block>>>();
  convertDir<<<Grid,Block>>>(); // convert xyz velocity to angle
}
