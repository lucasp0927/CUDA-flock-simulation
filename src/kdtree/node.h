#ifndef NODE_H_
#define NODE_H_
//#define NDEBUG
#include <stdlib.h>
#include <vector>
#include <algorithm>
#include <math.h>
#include <iostream>
#include <iomanip>
#include <assert.h>
#define SAMPLESIZE 100
using namespace std;

void normalize(float* f,int size);
float randRange(float a,float b);
struct Less {
Less(int ax) : _ax(ax) {}
  bool operator () ( int  a,int  b );
  int _ax;
};  
class Node
{

 public:
  Node();
  virtual ~Node();
  void init(int dim,int idx,int size);
  void setIdx(int i);
  int getIdx() const;  
  inline void setParent(int p);
  inline void setLChild(int l);
  inline void setRChild(int r);
  bool isEnd()  ;
  int getParent() const;
  int getLChild() const;
  int getRChild() const;
  static void setDepth(int idx,int d){
    assert(idx >= 0 && idx < _size);
    assert(d >= 0);
    _depth[idx]=d;
  }
  static int getDepth(int idx){
    assert(idx >= 0 && idx < _size);
    return _depth[idx]; }
  static int getDim() {return _dim;}
  void buildRootList(int size);
  void separateList();
  static float getPos(int idx,int dim)  {
    assert(idx >= 0 && idx < _size);
    return _pos[idx*_psize+dim];  }
  static float getDir(int idx,int dim)  {
    assert(idx >= 0 && idx < _size);
    return _xyz_dir[idx*_psize+dim];  }  
  float getDir(int dim) const;
  void setPos(int dim,float pos);
  void setDir(int dim,float dir);
  void setList(vector<int>* list);
  int median(int sample_sz,vector<int> * list,bool next,struct drand48_data *buffer = NULL); /* next will add _depth 1 */  
  int leftmedian(struct drand48_data *buffer = NULL);
  int rightmedian(struct drand48_data *buffer = NULL);
  static int* getTree(){return _tree;}
  static float* getPos(){return _pos;}
  static float* getDir(){return _xyz_dir;}  
  static int getPSize(){return _psize;}  
  float distance(int idx);
  vector<int>* getList() const;
  vector<int>* getLList() const;
  vector<int>* getRList() const;  
  void setChild(Node* left,Node* right);
  void clear();
  friend ostream& operator <<(ostream &os,Node& n);
  static int _size;  
 private:
  int _idx;

  static int _psize;

  static int _dim;  
  static bool _static_init;
  static int* _depth;  
  static float* _pos;          /* position only */
  static float* _xyz_dir;
  static int* _tree;
  vector<int>* _list,*_llist,*_rlist;
};
#endif
