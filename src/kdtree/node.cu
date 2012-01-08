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
    //    delete [] _pos;
    free(_pos);
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
    _pos =(float*) malloc(_psize*_size*sizeof(float));
    //new float[_psize*_size];
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
  assert(dim >= 0 && dim < 3);
  float piv = getPos(_idx,dim);
  for(vector<int>::iterator it = _list->begin(); it != _list->end(); ++it) {
    if (*it != _idx)
    {
      assert(*it >= 0 && *it < _size);
      assert(_idx >= 0 && _idx < _size);
      assert(dim >= 0 && dim < 3);
      if (getPos(*it,dim) > piv)
        _rlist->push_back(*it);
      else
        _llist->push_back(*it);
    }
  }
  _list->clear();
  delete _list;
  _list = NULL;
}

void Node::setPos(int dim,float pos)
{
  _pos[_idx*_psize+dim] = pos;  
}

void Node::setDir(int dim,float dir)
{
  _xyz_dir[_idx*_psize+dim] = dir;  
}

int compare (const void* a,const void* b)
{
  return(((tuplet*)a)->pos - ((tuplet*)b)->pos);
}

int Node::median(int sample_sz,vector<int>* list,bool next,struct drand48_data *buffer)
{
  double randnum;
  //  vector<int> sample;
  tuplet* sample;    
  //  sample = new vector<int>;
  int tmp;

  //  cerr << list->size();
  if (list == NULL)
  {
    int ax = getDepth(_idx)%getDim();    
    sample_sz = _size < sample_sz? _size:sample_sz;
    sample = (tuplet*) malloc(sample_sz*sizeof(tuplet));
    assert (sample_sz == SAMPLESIZE || sample_sz == _size );
    for (int i = 0; i < sample_sz; ++i)
    {
      if (buffer == NULL)
        tmp = rand() % (_size);
      else
      {
        drand48_r(buffer, &randnum);
        tmp =  (int)(randnum*_size);
      }
      assert(tmp >=0 && tmp < _size);
      // if (tmp >= _size)
      //   tmp = _size-1;
      assert(tmp >=0 && tmp < _size);
      //      sample.push_back(tuplet(tmp,Node::getPos(tmp,ax)));
      sample[i].idx = tmp;
      sample[i].pos = Node::getPos(tmp,ax);
    }
    //sort(sample.begin(),sample.end(),compare);        
    qsort(sample,sample_sz,sizeof(tuplet),compare);
  }
  else
  {
    if(next)
      _depth[_idx]++;
    int ax = getDepth(_idx)%getDim();        
    assert(list->size() != 0);
    sample_sz = list->size() < sample_sz? list->size():sample_sz;
    sample = (tuplet*) malloc(sample_sz*sizeof(tuplet));
    assert (sample_sz == SAMPLESIZE || sample_sz == list->size());    
    //    sample.clear();
    //    sample.reserve(sample_sz);
    for (int i = 0; i < sample_sz; ++i)
    {
      if (buffer == NULL)
        tmp = rand() % (list->size());        
      else
      {
        drand48_r(buffer, &randnum);
        tmp =  (int)(randnum*list->size());
      }
      assert(tmp >= 0 && tmp < list->size());
      // if (tmp >= list->size() )
      //   tmp = list->size()-1;
      tmp = (*list)[tmp];
      assert(tmp >= 0 && tmp < _size);
      sample[i].idx = tmp;
      sample[i].pos = Node::getPos(tmp,ax);      
      //      sample.push_back(tuplet(tmp,Node::getPos(tmp,ax)));      
    }
    // vector<int>::iterator it;
    // cout << "sample contains:";
    // for (it=sample.begin(); it!=sample.end(); ++it)
    //   cout << " " << *it;
    // cout << endl;
    assert(getDepth(_idx) >= 0);    
    assert(ax >= 0 && ax < 3);    
    //    sort(sample.begin(),sample.end(),compare);    
//quick_sort (sample, sample_sz,getDepth(_idx));
    qsort(sample,sample_sz,sizeof(tuplet),compare);
    if(next)
      _depth[_idx]--;
  }
  
  int result = sample[sample_sz/2].idx;
  free(sample);
  //  delete sample;
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
    int lidx = left->getIdx();
    setLChild(lidx);
    left->setParent(_idx);
    Node::setDepth(lidx,_depth[_idx]+1);
    left->setList(_llist);
    _llist = NULL;
  }
  else
  {
    setLChild(_idx);
    delete _llist;
    _llist = NULL;
  }
    
  if (right != NULL)
  {
    int ridx = right->getIdx();
    setRChild(ridx);
    right->setParent(_idx);  
    Node::setDepth(ridx,Node::getDepth(_idx)+1);
    right->setList(_rlist);
    _rlist = NULL;
  }
  else
  {
    setRChild(_idx);
    delete _rlist;
    _rlist = NULL;
  }
  
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
    tmp = getPos(idx,i%3 ) - getPos(_idx,i%3 );
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
    os << setw(10) << n.getPos(n.getIdx(),i%3 );
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
