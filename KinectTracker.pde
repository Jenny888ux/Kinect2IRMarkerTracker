import KinectPV2.*;

import gab.opencv.*;
import java.awt.Rectangle;
import java.util.*;
import java.nio.*;

KinectPV2 kinect;
OpenCV opencv;
PImage lastFrame;

//Distance Threashold
public static final int maxD = 4000; // 4m
public final static int minD = 0;  //  0m
public static final int dataFrameWidth = 512;
public static final int dataFrameHeight = 424;

int[][] views = {{0, 0}, {0, 1}};

public static final int DEPTH = 0;
public static final int INFRARED = 1;
int currentView = INFRARED;
int dataFrameCount = 0;
int markersFrameIndex = 0;

Contour[] contours = null;
ArrayList<PVector[]> markers = new ArrayList<PVector[]>(); 


void setup() {
  settings =  loadSettingsFromFile();
  if(settings == null){
    settings = new Settings();
  }
  /*512 * 2 + 20*/
  size(1044, 424);
  createUI();
  //frameRecorder = new FrameRecorder("1518606239751");
  //selectOutput("Select a file to write to:", "fileSelected");
  
  opencv = new OpenCV(this, dataFrameWidth, dataFrameHeight);
  kinect = new KinectPV2(this);
  kinect.enableInfraredImg(true);
  kinect.enableDepthImg(true);
  kinect.enableCameraSpaceTable(true);
  kinect.setLowThresholdPC(minD);
  kinect.setHighThresholdPC(maxD);
  kinect.init();
}

void draw() {
  background(0);
  //A blue rectangle to show where the Kinect monitor is
  fill(0,0,255);
  rect(0,0, dataFrameWidth, dataFrameHeight);
  drawUI();
  processFrame();
 if(showOpenCV){
    image(opencv.getOutput(), 0, 0);
  }else{
    image(lastFrame, 0, 0);
  }
  
  if(showContours && contours != null){
    pushMatrix();
    translate(settings.ROI.x, settings.ROI.y);
    pushStyle();
    fill(0,255,0);
    stroke(0,255,0);
    for(Contour contour : contours){
      if(contour == null){
        continue;
      }
      contour.draw();
    }
    popStyle();
    popMatrix();
  }

   if(editROI){
     drawROI();
   }
 
   drawValues();
}

void drawValues(){
   if( exportResult != null ){
     String exportStatus = "Export in progress";
     if( exportResult.isDone() ){
       try{
         if( exportResult.get() ){
           exportStatus = "Export successful!";
         }else{
           exportStatus = "Export failed...";
         }
       }catch(Exception e){
         println("Getting the export task status failed");
         e.printStackTrace();
       }
     }
     text(exportStatus, dataFrameWidth/2 - textWidth(exportStatus)/2, 30);
   }
   
   if(recording){
     text("RECORDING", dataFrameWidth/2 - textWidth("RECORDING")/2, 30);
   }/*else{
     text(markersFrameIndex, width/2 - textWidth(""+markersFrameIndex)/2, 20);
   }
   text(dataFrameCount, 10, 20);
   text(settings.brightnessThreshold, width-textWidth(""+settings.brightnessThreshold)-10, 20);
   */
}

void drawROI(){
   //Draw ROI
   pushStyle();
   noFill();
   stroke(255,255,0);
   strokeWeight(2);
   rect(settings.ROI.x, settings.ROI.y, settings.ROI.width, settings.ROI.height);
   ellipseMode(RADIUS);
   if( mouseIsOverROICenter() ){
     fill(0,0,255);
   }else{
     noFill();
   }
   ellipse(settings.ROI.x+settings.ROI.width/2, settings.ROI.y+settings.ROI.height/2, 10, 10);
   if(mouseIsOverROIBottomRight() ){
     fill(0,0,255);
   }else{
     noFill();
   }
   ellipse(settings.ROI.x + settings.ROI.width, settings.ROI.y + settings.ROI.height, 10, 10);
   popStyle();
}

boolean mouseIsOverROICenter(){
   return (mouseX - settings.ROI.x-settings.ROI.width/2)*(mouseX - settings.ROI.x-settings.ROI.width/2) + (mouseY - settings.ROI.y-settings.ROI.height/2)*(mouseY - settings.ROI.y-settings.ROI.height/2) <= 100;
}

boolean mouseIsOverROIBottomRight(){
   return (mouseX - settings.ROI.x - settings.ROI.width)*(mouseX - settings.ROI.x - settings.ROI.width) + (mouseY - settings.ROI.y - settings.ROI.height)*(mouseY - settings.ROI.y - settings.ROI.height) <= 100;
}


Contour[] threeBiggest(List<Contour> contours) {
  Contour result[] = {null, null, null};
  // Sorting
  Collections.sort(contours, new Comparator<Contour>() {
    @Override
      public int compare(Contour contour1, Contour contour2)
    {

      return  contour2.numPoints() - contour1.numPoints();
    }
  }
  );

  int m = 0;
  for( int i = 0; m < 3 && i < contours.size(); i++ ) {
    //println(contours.get(i).numPoints());
    if(contours.get(i).numPoints() < 1){
      break;
    }
    result[m++] = contours.get(i);
  }

  return result;
}

// Called every time a new frame is available to read
void processFrame() {
  lastFrame = kinect.getInfraredImage();
  //m.read();
  doCV();
  if(recording){
     frameRecorder.record( contours, kinect.getRawDepthData() );
  }
  markersFrameIndex = dataFrameCount;

  dataFrameCount++;
}

void doCV(){
  opencv.loadImage( lastFrame );
  opencv.setROI(settings.ROI.x, settings.ROI.y, settings.ROI.width, settings.ROI.height);
  opencv.threshold(settings.brightnessThreshold);

  //PVector loc = opencv.max(); //find the brightest point
  contours = threeBiggest(opencv.findContours());

}