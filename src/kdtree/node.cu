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
float* Node::_pos = NULL;
int* Node::_depth = NULL;
float* Node::_xyz_dir = NULL;
int* Node::_tree = NULL;

Node::Node()
{
}

Node::~Node()
{
  clear();
  if (_static_init)
  {
    delete [] _pos;
    _pos = NULL;
    delete [] _tree;
    _tree = NULL;
    delete [] _xyz_dir;
    _xyz_dir = NULL;
    delete [] _depth;
    _depth = NULL;
    _static_init = false;
  }

}

void Node::init(int dim,int idx,int size)
{
  _idx = idx;
  _list = NULL;
  _llist = NULL;
  _rlist = NULL;
  if (!_static_init)
  {
    assert(dim == 2||dim == 3);
    if (dim == 3)
      _psize = 3;
    else if (dim == 2)
      _psize = 2;
    _size = size;
    _dim = dim;
    _tree = new int[3*_size];
    _xyz_dir = new float[_dim*_size];
    _depth = new int[_size];        
    _pos = new float[_psize*_size];
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
  //_list->reserve(size);    
  for (int i = 0; i < size; ++i)
    (*_list).push_back(i);
  setDepth(_idx,0);
}

void Node::separateList()
{
  int dim = getDepth(_idx)%_dim;
  if (_rlist == NULL)
    _rlist = new vector<int>;
  else _rlist->clear();
  
  if (_llist == NULL)
    _llist = new vector<int>;
  else _llist->clear();  
  // _rlist->reserve(_list->size()/2);
  // _llist->reserve(_list->size()/2);
  for(vector<int>::iterator it = _list->begin(); it != _list->end(); ++it) {
    if (*it != _idx)
    {
      assert(*it >= 0 && *it < _size);
      assert(_idx >= 0 && _idx < _size);      
      if (getPos(*it,dim) > getPos(_idx,dim))
        _rlist->push_back(*it);
      else
        _llist->push_back(*it);
    }
  }
  _list->clear();
}


void Node::setPos(int dim,float pos)
{
  _pos[_idx*_psize+dim] = pos;  
}

void Node::setDir(int dim,float dir)
{
  _xyz_dir[_idx*_psize+dim] = dir;  
}


bool Node::Less::operator() (const int & a, const int& b)
{
  assert(a >= 0&& a < myNode->_size);
  assert(b >= 0&& b < myNode->_size);
  return (Node::getPos(a,Node::getDepth(myNode->getIdx())%Node::getDim()) < Node::getPos(b,Node::getDepth(myNode->getIdx())%Node::getDim()));
} 


void quick_sort (int *a, int n,int depth) {
  int dim = Node::getDim();
    if (n < 2)
        return;
    float p = Node::getPos(a[n / 2],depth%dim);
    int *l = a;
    int *r = a + n - 1;
    while (l <= r) {
      while (Node::getPos(*l,depth%dim) < p)
            l++;
      while ( Node::getPos(*r,depth%dim)> p)
            r--;
        if (l <= r) {
            int t = *l;
            *l++ = *r;
            *r-- = t;
        }
    }
    quick_sort(a, r - a + 1, depth);
    quick_sort(l, a + n - l, depth);
}

int Node::median(int sample_sz,vector<int>* list,bool next,struct drand48_data *buffer)
{
  double randnum;
  //  vector<int> sample;
  vector<int>* sample;
  sample = new vector<int>;
  int tmp;
  if (list == NULL)
  {
    sample_sz = _size < sample_sz? _size:sample_sz;
    assert (sample_sz == SAMPLESIZE || sample_sz == _size );
    sample->clear();
    int count = 0;
    while (count < sample_sz)
    {
      if (buffer == NULL)
        tmp = rand() % (_size);
      else
      {
        drand48_r(buffer, &randnum);
        tmp =  (int)randnum*(_size);
      }
      //    if (find(sample.begin(),sample.end(),tmp) == sample.end())
      // {
      if (tmp >= _size)
        tmp = _size-1;
      assert(tmp >=0 && tmp < _size);
      sample->push_back(tmp);
      count++;
      //      }
    }
    sort(sample->begin(),sample->end(),Less(this));        
    //quick_sort (sample, sample_sz,getDepth(_idx));
    
  }
  else
  {
    if(next)
      _depth[_idx]++;
    assert(list->size() != 0);
    sample_sz = list->size() < sample_sz? list->size():sample_sz;
    assert (sample_sz == SAMPLESIZE || sample_sz == list->size());    
    sample->clear();
    //    sample.reserve(sample_sz);      
    int count = 0;
    while (count < sample_sz)
    {
      if (buffer == NULL)
        tmp = rand() % (list->size());        
      else
      {
        drand48_r(buffer, &randnum);
        tmp =  (int)randnum*(list->size());
      }      

      //      if (find(sample.begin(),sample.end(),tmp) == sample.end())
      //      {
      if (tmp >= list->size() )
        tmp = list->size()-1;
      sample->push_back(tmp);
      count++;
      //      }
    };
    for (int i = 0; i < sample_sz; ++i)
    {
      int tmp;
      tmp = (*list)[(*sample)[i]];
      assert(tmp >= 0 && tmp < _size);
      (*sample)[i] = tmp;
    }
    
    sort(sample->begin(),sample->end(),Less(this));    
//quick_sort (sample, sample_sz,getDepth(_idx));          
    if(next)
      _depth[_idx]--;
  }
  
  int result = (*sample)[sample_sz/2];    
  delete sample;
  return result;  
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
    Node::setDepth(left->getIdx(),_depth[_idx]+1);
    left->setList(_llist);
    _llist = NULL;
  }
  else
    setLChild(_idx);
  
  if (right != NULL)
  {
    setRChild(right->getIdx());
    right->setParent(_idx);  
    Node::setDepth(right->getIdx(),Node::getDepth(_idx)+1);
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
  for (int i = 0; i < Node::getDim(); ++i)
  {
    os << setw(10) << n.getPos(n.getIdx(),i);
  }
  os << setw(5) << "p:" << setw(5) << n.getParent();
  os << setw(5) << "l:" << setw(5) << n.getLChild();
  os << setw(5) << "r:" << setw(5) << n.getRChild();
  os << setw(5) << "d:" << setw(5) << Node::getDepth(n.getIdx());
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
