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
  if (_static_init)
  {
    delete [] _data;
    delete [] _tree;
    _static_init = false;
  }
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
inline void Node::setParent(int p){  _tree[3*_idx] = p;}
inline void Node::setLChild(int l){  _tree[3*_idx+1] = l;}
inline void Node::setRChild(int r){  _tree[3*_idx+2] = r;}
int Node::getParent() const{  return _tree[3*_idx];}
int Node::getLChild() const{  return _tree[3*_idx+1];}
int Node::getRChild() const{  return _tree[3*_idx+2];}
void Node::setDepth(int d){  _depth = d;}
int Node::getDepth() const{return _depth;}
int Node::getDim() const{return _dim;}
int Node::getIdx() const{return _idx;}
vector<int>* Node::getList() const{return _list;}
vector<int>* Node::getLList() const{return _llist;}
vector<int>* Node::getRList() const{return _rlist;}
bool Node::isEnd()
{
  if (getLChild() == _idx && getRChild() == _idx)
    return true;
  else return false;
}

void Node::buildRootList(int size)
{
  setParent(_idx);
  if (_list == NULL)
    _list = new vector<int>;
  else
    _list->clear();
  
  _list->reserve(size);    
  for (int i = 0; i < size; ++i)
    (*_list).push_back(i);
  _depth = 0;  
}

void Node::separateList()
{
  int dim = _depth%_dim;
  if (_rlist == NULL)
    _rlist = new vector<int>;
  if (_llist == NULL)
    _llist = new vector<int>;
  for(vector<int>::iterator it = _list->begin(); it != _list->end(); ++it) {
    if (*it != _idx)
    {
      if (getPos(*it,dim) > getPos(_idx,dim))
        _rlist->push_back(*it);
      else
        _llist->push_back(*it);
    }
  }
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

int Node::median(int sample_sz,vector<int>* list,bool next,struct drand48_data *buffer)
{
  double randnum;
  vector<int> sample;
  if (list == NULL)
  {
    //    assert(_depth == 0);
    sample_sz = _size < sample_sz? _size:sample_sz;
    sample.reserve(sample_sz);  
    // test all points
    int count = 0;
    int tmp;
    while (count != sample_sz)
    {
      if (buffer == NULL)
        tmp = rand() % _size;
      else
      {
        drand48_r(buffer, &randnum);
        tmp =  tmp*(_size);
      }
        //    if (find(sample.begin(),sample.end(),tmp) == sample.end())
        // {
        sample.push_back(tmp);
        count++;
        //      }
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
    sample.reserve(sample_sz);      
    int count = 0;
    int tmp;
    while (count != sample_sz)
    {
      if (buffer == NULL)
        tmp = rand() % (list->size());        
      else
      {
        drand48_r(buffer, &randnum);
        tmp =  randnum*(list->size());
      }      

      //      if (find(sample.begin(),sample.end(),tmp) == sample.end())
      //      {
        sample.push_back(tmp);
        count++;
        //      }
    };
    for (int i = 0; i < sample.size(); ++i)
      sample[i] = (*list)[sample[i]];
    sort(sample.begin(),sample.end(),Less(this));
    if(next)
      _depth--;
    return sample[sample.size()/2];
  }
}

void Node::setList(vector<int>* list)
{
  if (_list != NULL)
  {
    delete _list;
    _list = NULL;
  }
  _list = list;
}

void Node::setChild(Node* left,Node* right)
{
  if (left != NULL)
  {
  setLChild(left->getIdx());
  left->setParent(_idx);
  left->setDepth(_depth+1);
  left->setList(_llist);
  _llist = NULL;
  }
  else
    setLChild(_idx);
  
  if (right != NULL)
  {
    setRChild(right->getIdx());
    right->setParent(_idx);  
    right->setDepth(_depth+1);
    right->setList(_rlist);
    _rlist = NULL;
  }
  else
    setRChild(_idx);
}

int Node::leftmedian(struct drand48_data *buffer)
{
  return median(100,_llist,true,buffer);
}

int Node::rightmedian(struct drand48_data *buffer)
{
  return median(100,_rlist,true,buffer);  
}

float Node::distance(int idx)
{
  float d = 0.0;
  float tmp;
  for (int i = 0; i < _dim; ++i)
  {
    tmp = getPos(idx,i) - getPos(_idx,i);
    d += tmp*tmp;
  }
  d = sqrt(d);
  return d;
}

void Node::clear()
{
  if (_list != NULL)
  {
    delete _list;
    _list = NULL;
  }

  if (_llist != NULL)
  {
    delete _llist;
    _llist = NULL;
  }
  
  if (_rlist != NULL)
  {
    delete _rlist;
    _rlist = NULL;
  }
}

  
ostream &operator <<(ostream &os,Node& n)
{
  os << setw(3) << n.getIdx();
  for (int i = 0; i < n.getDim(); ++i)
  {
    os << setw(10) << n.getPos(n.getIdx(),i);
  }
  os << setw(5) << "p:" << setw(5) << n.getParent();
  os << setw(5) << "l:" << setw(5) << n.getLChild();
  os << setw(5) << "r:" << setw(5) << n.getRChild();
  os << setw(5) << "d:" << setw(5) << n.getDepth();
  os << setw(5) << "e:" << setw(5) << n.isEnd();    
  return os;
}

/*
  angle:  -180*acos( dx / sqrt (  dx*dx + dy*dy  + dz *dz ))/M_PI
  rX:0
  rY: dz
  rZ: -dy
  dx dy dz是方向向
*/
