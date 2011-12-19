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
} Flock;

class FlockSim
{
 private:
  Flock F;
  float wallx,wally;
  void initialFlock(int size);
  
 public:
  FlockSim(int size,float wall_size);
  virtual ~FlockSim()
  {
    free(F.flock);
  };
  void printFlock();  
};
  


#endif
