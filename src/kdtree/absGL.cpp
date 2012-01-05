#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <iostream>
//#include <GL/glut.h>
#include <GL/glew.h>
#include <GL/glut.h>
//#include <GL/gl.h>
//#include <cutil_inline.h>
//#include "Obj.cpp"
#include <omp.h>

#include "flocksim.h"

#define W    1280
#define H    768
#define Ratio 10
//Obj bird[1000000];
int timeo,timen,frame,fps;
//GLfloat position[2000000];
//GLuint positionVBO;


extern FlockSim *fs;
extern int size;


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
    for(i=0;i<size;i++){
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
char temp[100];
   sprintf(temp,"FPS: %d",fps);
    glColor3f(1.0f,0,0);
   glRasterPos2i(-40,-30);
   printBitmapString(GLUT_BITMAP_HELVETICA_18,temp);
  // printf("%s",temp);

}


void display() {
    fpscal();
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glPushMatrix();

    glTranslatef(0,0,-700);
    glRotatef(-70,1,0,0);  
  //  glLoadIdentity();
//    gluLookAt(0,0,5,0,0,0,0,1,0);
    //glBufferData(GL_ARRAY_BUFFER,size*2*sizeof(float),position,GL_DYNAMIC_DRAW);
//    glBegin(GL_POINTS);
    glColor3f(1.0f,1.0f,1.0f);

    //glutWireTeapot(3);
       glEnableClientState(GL_VERTEX_ARRAY);
       glVertexPointer(3,GL_FLOAT,0,Vertices);
     //  #pragma omp parallel for   
       for(int i=0;i<size;i++){
       
       glPushMatrix();
//	printf("x:%f\n",fs->getPos(i,0));
       glTranslated(2*fs->getPos(i,0)/Ratio,2*fs->getPos(i,1)/Ratio,fs->getPos(i,2));
       //glDirToRotate(bird[i].dX(),bird[i].dY(),bird[i].dZ());
//	printf("%d: %f %f %f\n",i,fs->getDir(i,0),fs->getDir(i,1),fs->getDir(i,2));
       glRotatef(fs->getDir(i,0),0,fs->getDir(i,1),fs->getDir(i,2)); 
     // glTranslated(bird[i].X()/5,bird[i].Y()/5,-2);
     //  glDrawElements(GL_TRIANGLES,12,GL_UNSIGNED_BYTE,Vindex);    
       glDrawArrays(GL_LINES,0,12);
       glPopMatrix();
      // bird[i].move();
       }
	

	fs->makeTree();
	fs->cpytree2dev();
	fs->update();
	fs->cpy2host();
   //    #pragma omp parallel for 
    //   for(int i=0;i<size;i++){
    //       printf("%d bird %d\n",omp_get_thread_num(),i);   
    //       bird[i].move();
     //      bird[i].calR();
     //  }
       glDisableClientState(GL_VERTEX_ARRAY);
      printfps();
   // updateposition();
   // for(int i=0;i<size;i++){
  //if(i==0){      printf("x=%f y=%f\n",bird[i].X(),bird[i].Y());}
//        glVertex2f(2*bird[i].X()/W,2*bird[i].Y()/H);
//	bird[i].move();
	//bird[i].turns(0.5);
  //  }        
  //  glEnd();
     glPopMatrix();
    glutSwapBuffers();
   // glFinish();
}

void reshape(int w,int h){
       glMatrixMode(GL_PROJECTION);
       glLoadIdentity();
        glFrustum(-W/Ratio,W/Ratio,-H/Ratio,H/Ratio,600,800);
    //   glOrtho(-W/10,W/10,-H/10,H/10,-100,100);
   //    glRotatef(-30,1,0,0);
  //     glTranslated(0,0,-10);
       glMatrixMode(GL_MODELVIEW);
       glLoadIdentity();


}

   // cudaMalloc((void**)&d_a, sizeof(h_a));
   // do_cuda<<<20,32>>>(d_a);
   // cudaMemcpy(h_a, d_a, sizeof(h_a), cudaMemcpyDeviceToHost);

  /*  if (! glewIsSupported("GL_VERSION_1_5 ")) {
        printf("fuck!!!!!!!!");
    }*/
//printf("fuck!\n");

void mainGL(int argc,char **argv){
    timen=0;
    timeo=0;

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGBA|GLUT_DEPTH|GLUT_DOUBLE);
    glutInitWindowSize(W, H);
    glutCreateWindow("projecttest");

//    glGenBuffers(1,&positionVBO);

//printf("fuck!\n");
//    glBindBuffer(GL_ARRAY_BUFFER,positionVBO);
//    glBufferData(GL_ARRAY_BUFFER,size*2*sizeof(float),0,GL_DYNAMIC_DRAW);
    
//printf("fuck!\n");

       
    glutDisplayFunc(display);
    glutReshapeFunc(reshape);
    glutIdleFunc(idle);

    initGL();
    glutMainLoop();


}
