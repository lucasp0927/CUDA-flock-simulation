#ifndef NODE_H_
#define NODE_H_
#include <vector>

usning namespace std;

void normalize(float* f,int size);
float randRange(float a,float b);
class Node
{
 public:
  Node();
  virtual ~Node();
  void init(int dim,int idx);
  void setIdx(int i);
  void setParent(int p);
  void setLChild(int l);
  void setRChild(int r);
  void getParent() const;
  void getLChild() const;
  void getRChild() const;
  void setDepth(int d);
  void getDepth() const;
  void buildRootList(int size);
  void seperateList();
  float getPos(int idx,int dim) const;
  float getDir(int idx,int dim) const;
  void setPos(int idx,int dim,float pos);
  void setDir(int idx,float* dir);  
 private:
  int _idx;
  int _depth;
  int _dim;
  static float* _data;          /* position and direction */
  static int* _tree;
  vector<int>* _list,*_llist,*_rlist;
};
#endif
