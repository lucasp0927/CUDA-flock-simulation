#include "node.h"
void normalize(float* f,int size)
{
  float len = 0.0;
  for (int i = 0; i < size; ++i)
    len += (*(f+i))*(*(f+i));
  len = sqrt(len);
  for (int i = 0; i < size; ++i)
    *(f+i) /= len;
}

float randRange(float a,float b)
{
  // give a random float between a and b
  return a+(b-a)*((float)rand()/RAND_MAX);
}


bool Node:: _static_init = false;
int Node::_dim = 0;
int Node::_size = 0;
int Node::_psize = 0;
float* Node::_data = NULL;
int* Node::_tree = NULL;

Node::Node()
{
}
Node::~Node()
{
}
void Node::init(int dim,int idx,int size)
{
  _idx = idx;
  _depth = 0;
  _list = NULL;
  _llist = NULL;
  _rlist = NULL;
  if (!_static_init)
  {
    assert(dim == 2||dim == 3);
    if (dim == 3)
      _psize = 8;
    else if (dim == 2)
      _psize = 4;
    _size = size;
    _dim = dim;
    _tree = new int[3*_size];
    _data = new float[_psize*_size];
    _static_init = true;
  }
  
}
void Node::setIdx(int i){  _idx = i;}
void Node::setParent(int p){  _tree[3*_idx] = p;}
void Node::setLChild(int l){  _tree[3*_idx+1] = l;}
void Node::setRChild(int r){  _tree[3*_idx+2] = r;}
int Node::getParent() const{  return _tree[3*_idx];}
int Node::getLChild() const{  return _tree[3*_idx+1];}
int Node::getRChild() const{  return _tree[3*_idx+2];}
void Node::setDepth(int d){  _depth = d;}
int Node::getDepth() const{return _depth;}
int Node::getDim() const{return _dim;}
void Node::buildRootList(int size)
{
  _list = new vector<int>;
  _list->reserve(size);
  for (int i = 0; i < size; ++i)
    (*_list).push_back(i);
  _depth = 0;  
}
void Node::separateList()
{
  cerr << "separate"<<endl;
  int dim = _depth%_dim;
  for(vector<int>::iterator it = _list->begin(); it != _list->end(); ++it) {
    /* std::cout << *it; ... */
    if (getPos(*it,dim) > getPos(_idx,dim))
      _rlist->push_back(*it);
    else
      _llist->push_back(*it);
  }
  cout << "original list" << endl;
  for(vector<int>::iterator it = _list->begin(); it != _list->end(); ++it)
    cout << *it << " ";
  cout << endl;
  cout << "right list" << endl;
  for(vector<int>::iterator it = _rlist->begin(); it != _rlist->end(); ++it)
    cout << *it << " ";
  cout << endl;
  cout << "left list" << endl;
  for(vector<int>::iterator it = _llist->begin(); it != _llist->end(); ++it)
    cout << *it << " ";
  cout << endl;  
  _list->clear();
}
float Node::getPos(int idx,int dim) const
{
   assert (dim < _dim);
   return _data[idx*_psize+dim];   
}
float Node::getDir(int dim) const
{
  assert (dim < _dim);
  return _data[_idx*_psize+_dim+dim];
}
void Node::setPos(int dim,float pos)
{
  assert (dim < _dim);
  _data[_idx*_psize+dim] = pos;  
}
void Node::setDir(float* dir)
{
  normalize(dir,_dim);
  for (int i = 0; i < _dim; ++i)
    _data[_idx*_psize+_dim+i] = dir[i];      
}
bool Node::Less::operator() (const int & a, const int& b)
{
      return (myNode->getPos(a,myNode->getDepth()%myNode->getDim()) < myNode->getPos(b,myNode->getDepth()%myNode->getDim()));          
} 

int Node::median(int sample_sz,vector<int>* list,bool next)
{
  static vector<int> sample;
  sample.clear();  
  if (list == NULL)
  {
    assert(_depth == 0);
    sample_sz = _size < sample_sz? _size:sample_sz;    
    // test all points
    int count = 0;
    int tmp;
    while (count != sample_sz)
    {
      tmp = rand() % (_size);
      if (find(sample.begin(),sample.end(),tmp) == sample.end())
      {
        sample.push_back(tmp);
        count++;
      }
    };
    sort(sample.begin(),sample.end(),Less(this));
    return sample[sample.size()/2];    
  }
  else
  {
    if(next)
      _depth++;
    assert(list->size() != 0);
    sample_sz = list->size() < sample_sz? list->size():sample_sz;        
    int count = 0;
    int tmp;
    while (count != sample_sz)
    {
      tmp = rand() % (list->size());
      if (find(sample.begin(),sample.end(),tmp) == sample.end())
      {
        sample.push_back(tmp);
        count++;
      }
      for (int i = 0; i < sample.size(); ++i)
      {
        sample[i] = (*list)[sample[i]];
      }
    };
    sort(sample.begin(),sample.end(),Less(this));
    if(next)
      _depth--;
    return sample[sample.size()/2];
  }
}
/*
  angle:  -180*acos( dx / sqrt (  dx*dx + dy*dy  + dz *dz ))/M_PI
  rX:0
  rY: dz
  rZ: -dy
  dx dy dz是方向向
*/
