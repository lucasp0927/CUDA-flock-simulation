#ifndef NODE_H_
#define NODE_H_
#define NDEBUG
#include <stdlib.h>
#include <vector>
#include <algorithm>
#include <math.h>
#include <iostream>
#include <iomanip>
#include <assert.h>
#define SAMPLESIZE 300
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
  int getIdx() const;  
  inline void setParent(int p);
  inline void setLChild(int l);
  inline void setRChild(int r);
  bool isEnd()  ;
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
  void setList(vector<int>* list);
  int median(int sample_sz,vector<int> * list,bool next,struct drand48_data *buffer = NULL); /* next will add _depth 1 */
  int leftmedian(struct drand48_data *buffer = NULL);
  int rightmedian(struct drand48_data *buffer = NULL);
  float distance(int idx);
  vector<int>* getList() const;
  vector<int>* getLList() const;
  vector<int>* getRList() const;  
  void setChild(Node* left,Node* right);
  void clear();
  friend ostream& operator <<(ostream &os,Node& n);
  
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
