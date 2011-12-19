#include <stdio.h>
#include<stdlib.h>
#include<iostream>
#include"FlockSim.h"

#include <GL/glut.h>
#include <cuda.h>
#include <cudaGL.h>

#define W 640
#define H 480

using namespace std;

FlockSim* Fsim;

void idle(){
  glutPostRedisplay();
}


void display() {
  printf("fuckyou]\n");
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  glBegin(GL_POINTS);
  glColor3f(1.0f,1.0f,1.0f);
  for(int i=0;i<Fsim->F.size;i++){
    printf("%d\n",i);
    if(1){      printf("i=%d x=%f y=%f\n",i,Fsim->F.flock[i].x,Fsim->F.flock[i].y);}
    glVertex2f(2*Fsim->F.flock[i].x/W,2*Fsim->F.flock[i].y/H);
    //bird[i].move();
    //bird[i].turns(0.5);
  }
  Fsim->update_flock(1.0);
  Fsim->copy2host();
  glEnd();
  glFinish();
}




int main(int argc, char **argv)
{
  int flock_size=atoi(argv[1]);
  int wall_size=atoi(argv[2]);  //wall_size is a data menber of FlockSim
  cout << "Simulate a flock with " << flock_size << " agents." << endl;
  FlockSim Fs = FlockSim(flock_size,wall_size);
  Fsim = &Fs;
  /*
  Fsim->printFlock();
  Fsim->update_flock(100.0);     // big dt for testing
  Fsim->copy2host();
  Fsim->printFlock();
  Fsim->update_flock(100.0);     // big dt for testing
  Fsim->copy2host();
  Fsim->printFlock();
  */

  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_RGBA);
  glutInitWindowSize(W, H);
  glutCreateWindow("flock");
  glutDisplayFunc(display);
  glutIdleFunc(idle);
  glutMainLoop();

  return 0;
}
