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

 int first;
int flock_size;
int wall_size;
FlockSim Fsim;
void idle(){
    glutPostRedisplay();
}


void display() {
    printf("fuckyou]\n");
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glBegin(GL_POINTS);
    glColor3f(1.0f,1.0f,1.0f);
    for(int i=0;i<flock_size+1;i++){
      printf("%d\n",i);
  if(1){      printf("i=%d x=%f y=%f\n",i,Fsim.F.flock[i].x,Fsim.F.flock[i].y);}
        glVertex2f(2*Fsim.F.flock[i].x/W,2*Fsim.F.flock[i].y/H);
        //bird[i].move();
        //bird[i].turns(0.5);
    }
    if(first==1){
       Fsim.printFlock();
       first=0;  
    }
    Fsim.update_flock(100.0);
    Fsim.printFlock();
    glEnd();
    glFinish();
}




int main(int argc, char **argv)
{
  first=1;
  flock_size=atoi(argv[1]);
  wall_size=atoi(argv[2]);  
  cout << "Simulate a flock with " << flock_size << " agents." << endl;
  Fsim=FlockSim(flock_size,wall_size);
  //Fsim.printFlock();
      //  printf("x=%f y=%f\n",Fsim.F.flock[0].x,Fsim.F.flock[0].y);
//printf("fuck\n");
 // Fsim.update_flock(100.0);     // big dt for testing
  //Fsim.printFlock();
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGBA);
    glutInitWindowSize(W, H);
    glutCreateWindow("flock");
    glutDisplayFunc(display);
    glutIdleFunc(idle);
    glutMainLoop();

  return 0;
}
