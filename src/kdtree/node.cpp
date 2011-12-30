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
