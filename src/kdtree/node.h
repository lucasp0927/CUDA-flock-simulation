#ifndef NODE_H_
#define NODE_H_
//#defind NDEBUG
#include <stdlib.h>
#include <vector>
#include <algorithm>
#include <math.h>
#include <iostream>
#include <assert.h>

using namespace std;

void normalize(float* f,int size);
float randRange(float a,float b);
class Node
{
  struct Less {
  Less(Node* c) : myNode(c) {}
    bool operator () ( const int & a, const int & b );
    Node* myNode;
  };  
 public:
  Node();
  virtual ~Node();
  void init(int dim,int idx,int size);
  void setIdx(int i);
  void setParent(int p);
  void setLChild(int l);
  void setRChild(int r);
  int getParent() const;
  int getLChild() const;
  int getRChild() const;
  void setDepth(int d);
  int getDepth() const;
  int getDim() const;  
  void buildRootList(int size);
  void separateList();
  float getPos(int idx,int dim) const;
  float getDir(int dim) const;
  void setPos(int dim,float pos);
  void setDir(float* dir);
  int median(int sample_sz,vector<int> * list,bool next); /* next will add _depth 1 */
   private:
  int _idx;
  int _depth;
  static int _psize;
  static int _size;
  static int _dim;  
  static bool _static_init;
  static float* _data;          /* position and direction */
  static int* _tree;
  vector<int>* _list,*_llist,*_rlist;
};
#endif
