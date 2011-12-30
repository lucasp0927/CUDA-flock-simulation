#include <stdlib.h>
#include <string>
#include<vector>
#include <iostream>
#include <iomanip>
#include "node.h"

using namespace std;

int main(int argc, char *argv[])
{
  Node* nds = new Node[10];
  for (int i = 0; i < 10; ++i)
  {
    nds[i].init(3,i,10);
  }

  vector<int> list;
  list.reserve(10);
  for (int i = 0; i < 10; ++i)
    list.push_back(i);
  
  for (int i = 0; i < 10; ++i)
  {
    nds[i].setPos(0,(float)i);
  }
  cout << list.size() << endl;
  cout << nds[0].median(10,NULL,false) << endl;
  nds[5].buildRootList(10);
  nds[5].separateList();
  return 0;
}
