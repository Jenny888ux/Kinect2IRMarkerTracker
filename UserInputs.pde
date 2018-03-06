boolean showContours = true;
boolean showOpenCV = false;
//boolean showMarkers = true;
boolean recording = false;

/*
 Keys:
 'SPACE' to start/stop recording the markers positions
 'x' export recorded tracking data to csv file
 'p' to start/stop video playback
 'c' to hide/show the contours found by OpenCV
 'm' show hide the detected markers
 'r' toggle the edit mode of the Region Of Interest
 'o' show/hide the image with all the OpenCV filters applied
 'l' load previously saved settings from file
 's' save current settings to file
 '0' show depth image
 '1' show infrared image
 Up/Down arrows: increase/decrease brightness threshold for finding bright area contours
 Left/Right: navigate recorded markers positions
 */
 
/*
void keyReleased() {
  switch(key) {
  case ' ':
    recording = !recording;
    println(recording ? "Recording started":"Recording ended");
    if(recording){
      exportResult = null;
      frameRecorder.prepare();
    }else{
      frameRecorder.stop();
      selectOutput("Select a file to write to:", "fileSelected");
    }
    break;
  case 'p': //play/pause
    videoIsPlaying = !videoIsPlaying;
    println( videoIsPlaying ? "Playing" : "Paused" );
    break;
  case 'c': //show/hide markers contours
    showContours = !showContours;
    println( showContours ? "Contours shown": "Contours hidden" );
    break;
  case 'm': //show/hide markers contours
    showMarkers = !showMarkers;
    println( showMarkers ? "Markers shown": "Markers hidden" );
    break;
  case 'r':
    editROI = !editROI;
    println( editROI ? "Edit Region Of Interest: ON" : "Edit Region Of Interest: OFF");
    break;
  case 'o':
    showOpenCV = !showOpenCV;
    println( showOpenCV ? "OpenCV MAP shown" : "OpenCV MAP hidden" );
    break;
  case 's':
    saveSettingsToFile(settings);
    break;
  case 'l':
    Settings s = loadSettingsFromFile();
    if (s!=null) {
      settings = s;
      doCV();
    }
    break;
  case 'x': //export data to csv file
    saveData();
    break;
  case '0':
    currentView = DEPTH;
    println( "Showing depth data" );
    break;
  case '1':
    currentView = INFRARED;
    println( "Showing infrared datat" );
    break;
  }
}

void keyPressed(KeyEvent keyEvent) {
  if ( key != CODED ) {
    return;
  }

  switch(keyCode) {
  case UP: //increase brightness threshold
    settings.brightnessThreshold = min(255, settings.brightnessThreshold + 1*(keyEvent.isShiftDown() ? 10 : 1));
    doCV();
    break;
  case DOWN: //increase brightness threshold
    settings.brightnessThreshold = max(0, settings.brightnessThreshold - 1*(keyEvent.isShiftDown() ? 10 : 1));
    doCV();
    break;
  case LEFT:
    markersFrameIndex = max(0, markersFrameIndex - 1);
    break;
  case RIGHT:
    markersFrameIndex = recordedFrames.containsKey(markersFrameIndex+1) ? markersFrameIndex + 1 : markersFrameIndex;
    break;
  }
}
*/
boolean editROI = false;
boolean translateROI = false;
boolean resizeROI = false;

void mousePressed() {
  if (!editROI) {
    return;
  }
  translateROI = false;
  resizeROI = false;
  if (  mouseIsOverROICenter() ) {
    translateROI = true;
    return;
  }

  if ( mouseIsOverROIBottomRight() ) {
    resizeROI = true;
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    frameRecorder.deleteRecording();
    return;
  }
  try{
    exportResult = frameRecorder.exportToCSV( selection );
  }catch(Exception e){
    println("Export failed...");
    e.printStackTrace();
  }
}

void mouseReleased() {
  translateROI = false;
  resizeROI = false;
}