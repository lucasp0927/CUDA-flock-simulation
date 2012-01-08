#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <iostream>
#include <pthread.h>
//#include <GL/glut.h>
#include <GL/glew.h>
#include <GL/glut.h>
//#include <GL/gl.h>
//#include <cutil_inline.h>
//#include "Obj.cpp"
//#include <omp.h>

#include "flocksim.h"

#define W    1280
#define H    768
#define Ratio 10
//Obj bird[1000000];
int timeo,timen,frame,fps;
//GLfloat position[2000000];
//GLuint positionVBO;


extern FlockSim *fs;
extern int flocksize;

float Border[6];

float boxangleX,boxangleY;
bool mouseLeftDown;
float Xmouse,Ymouse;

GLfloat Vertices[]={
  2,0,0, -1,1,0, 
  2,0,0, -1,-1,0,
  2,0,0,  -1,0,1,
  -1,1,0, -1,-1,0,
  -1,1,0, -1,0,1,
  -1,-1,0, -1,0,1

};

GLuint Vindex[]={
  1,2,3,
  2,3,4,
  1,2,4,
  1,3,4
	
};


void glDirToRotate(float dx,float dy,float dz){
  //	float angle=180*acos(dx/sqrt(dx*dx+dy*dy+dz*dz))/M_PI;

  //printf("dx:%f dy:%f dz:%f x:%d y:%f z:%f\n",dx,dy,dz,0,dz,-dy);

  glRotatef(-180*acos(dx/(sqrt(dx*dx+dy*dy+dz*dz)))/M_PI,0,dz,-dy);
}


void initGL(){
  glEnable(GL_DEPTH_TEST);
}


void idle(){
  glutPostRedisplay();
}

/*
  void updateposition(){
  int i;
  for(i=0;i<flocksize;i++){
  position[i*2]=bird[i].X();
  position[i*2+1]=bird[i].X();
  }

  }*/

void printBitmapString(void *font,char *str){
  char *strPos=str;
  while(*strPos!=0){
    glutBitmapCharacter(font,*strPos);
    strPos++;
  }


}


void fpscal(){
  frame++;
  timen=glutGet(GLUT_ELAPSED_TIME);
  if(timen-timeo>1000){
    fps=1000.0*frame/(timen-timeo);
    timeo=timen;
    frame=0;
  }
}

void printfps(){
  glPushMatrix();
  glLoadIdentity();

  glMatrixMode(GL_PROJECTION);
  glPushMatrix();
  glLoadIdentity();
  glOrtho(0,W,0,H,-1,1); 
  char temp[100];
  sprintf(temp,"FPS: %d",fps);
  glColor3f(1.0f,0,0);
  glRasterPos2i(W/2,10);
  printBitmapString(GLUT_BITMAP_HELVETICA_18,temp);
  // printf("%s",temp);
  glPopMatrix();
  
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix();

}

void printBorder(){
  glPushMatrix();
  glBegin(GL_LINES);
  glColor3f(1.0f,0,0);
  glVertex3f(2*Border[0]/Ratio,2*Border[2]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[0]/Ratio,2*Border[3]/Ratio,2*Border[4]/Ratio);

  glVertex3f(2*Border[0]/Ratio,2*Border[2]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[0]/Ratio,2*Border[2]/Ratio,2*Border[5]/Ratio);

  glVertex3f(2*Border[0]/Ratio,2*Border[2]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[1]/Ratio,2*Border[2]/Ratio,2*Border[4]/Ratio);

  glVertex3f(2*Border[1]/Ratio,2*Border[2]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[1]/Ratio,2*Border[3]/Ratio,2*Border[4]/Ratio);

  glVertex3f(2*Border[1]/Ratio,2*Border[2]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[1]/Ratio,2*Border[2]/Ratio,2*Border[5]/Ratio);

  glVertex3f(2*Border[1]/Ratio,2*Border[2]/Ratio,2*Border[5]/Ratio);
  glVertex3f(2*Border[1]/Ratio,2*Border[3]/Ratio,2*Border[5]/Ratio);

  glVertex3f(2*Border[1]/Ratio,2*Border[2]/Ratio,2*Border[5]/Ratio);
  glVertex3f(2*Border[0]/Ratio,2*Border[2]/Ratio,2*Border[5]/Ratio);

  glVertex3f(2*Border[0]/Ratio,2*Border[2]/Ratio,2*Border[5]/Ratio);
  glVertex3f(2*Border[0]/Ratio,2*Border[3]/Ratio,2*Border[5]/Ratio);

  glVertex3f(2*Border[0]/Ratio,2*Border[3]/Ratio,2*Border[5]/Ratio);
  glVertex3f(2*Border[0]/Ratio,2*Border[3]/Ratio,2*Border[4]/Ratio);

  glVertex3f(2*Border[0]/Ratio,2*Border[3]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[1]/Ratio,2*Border[3]/Ratio,2*Border[4]/Ratio);

  glVertex3f(2*Border[1]/Ratio,2*Border[3]/Ratio,2*Border[4]/Ratio);
  glVertex3f(2*Border[1]/Ratio,2*Border[3]/Ratio,2*Border[5]/Ratio);

  glVertex3f(2*Border[1]/Ratio,2*Border[3]/Ratio,2*Border[5]/Ratio);
  glVertex3f(2*Border[0]/Ratio,2*Border[3]/Ratio,2*Border[5]/Ratio);

  glEnd();
  glPopMatrix();
}


void* mtree(void* i)
{
  fs->_kt->clearTree();
    fs->makeTree();
    return NULL;
}



void display() {
  pthread_t thread1;
	 
  pthread_create( &thread1, NULL, &mtree, NULL);

  fpscal();
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

  glPushMatrix();

  glTranslatef(0,0,-(Border[1]*1.2));
  glRotatef(boxangleY,1,0,0);
  glColor3f(1.0f,1.0f,1.0f);

  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(3,GL_FLOAT,0,Vertices);
  
  for(int i=0;i<flocksize;i++){
    glPushMatrix();
    glTranslated(2*fs->getPos(i,0)/Ratio,2*fs->getPos(i,1)/Ratio,2*fs->getPos(i,2)/Ratio);
    if(i==1)   { 
	}
    glRotatef(fs->getDir(i,0),0,fs->getDir(i,1),fs->getDir(i,2)); 
    glDrawArrays(GL_LINES,0,12);
    glPopMatrix();
  }
  
  glDisableClientState(GL_VERTEX_ARRAY);
  printfps();
  printBorder();
  glPopMatrix();
  glutSwapBuffers();
  
  pthread_join( thread1, NULL);
  fs->cpytree2dev();
  fs->update();
  fs->cpy2host();

}

void reshape(int w,int h){
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  
  glFrustum(-W/Ratio,W/Ratio,-H/Ratio,H/Ratio,600,600+(Border[1]+50)*2);
  //   glOrtho(-W/10,W/10,-H/10,H/10,-100,100);
  //    glRotatef(-30,1,0,0);
  //     glTranslated(0,0,-10);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();


}


void mouse(int button,int state,int x,int y){
  Xmouse=x;
  Ymouse=y;
  if(button==GLUT_LEFT_BUTTON){
	if(state==GLUT_DOWN){
      mouseLeftDown=true;
	}
    else if(state==GLUT_UP){
      mouseLeftDown=false;
	}
  }

}

void mouseM(int x,int y){
  if(mouseLeftDown){
    boxangleY+=(y-Ymouse)/100;
    boxangleX+=(x-Xmouse)/100;
  }
}

// cudaMalloc((void**)&d_a, flocksizeof(h_a));
// do_cuda<<<20,32>>>(d_a);
// cudaMemcpy(h_a, d_a, sizeof(h_a), cudaMemcpyDeviceToHost);

/*  if (! glewIsSupported("GL_VERSION_1_5 ")) {
    printf("fuck!!!!!!!!");
    }*/
//printf("fuck!\n");

void mainGL(int argc,char **argv,float* border){
  timen=0;
  timeo=0;
  boxangleX=0;
  boxangleY=-70;
  mouseLeftDown=false;
  for(int i=0;i<6;i++){
    Border[i]=border[i]+2/Ratio;
  }

  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_RGBA|GLUT_DEPTH|GLUT_DOUBLE);
  glutInitWindowSize(W, H);
  glutCreateWindow("projecttest");
  glutDisplayFunc(display);
  glutReshapeFunc(reshape);
  glutIdleFunc(idle);
  glutMouseFunc(mouse);
  glutMotionFunc(mouseM);
  initGL();
  glutMainLoop();
}
