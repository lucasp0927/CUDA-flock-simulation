#ifndef FLOCKSIM_H_
#define FLOCKSIM_H_


typedef struct
{
  float angle; //360
  float x,y;
} Agent;
  
typedef struct
{
  int size;//number of agents
  Agent* flock;
  float wallx,wally;
} Flock;
  
void initialFlock(Flock &F,int size,float wallsize);
void printFlock(Flock &F);
#endif
