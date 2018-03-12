import java.nio.channels.AsynchronousFileChannel;
import java.nio.file.*;
import java.util.concurrent.*;

FrameRecorder frameRecorder;
ExecutorService exportExecutor = Executors.newFixedThreadPool(1);
Future<Boolean> exportResult = null;

class BadConversionTable extends Exception{
  public BadConversionTable(){
    super("The size of the depth to camera space mapping table of the recording " +
              "does not match the size of the depth frames.");
  }
}

class FrameRecorder {
  Path depthToCameraFilePath;
  Path filePath;
  AsynchronousFileChannel asyncFile;
  long nextPosition = 0;

  public FrameRecorder() {
    depthToCameraFilePath = Paths.get(sketchPath() + File.separator + "data" + File.separator + "depthToCamera.float");
  }

  public FrameRecorder(String recordingID) {
    filePath = Paths.get(sketchPath() + File.separator+ "data" + File.separator +recordingID+".rec");
  }

  public boolean prepare() {
    //First check if the conversion table has already been saved
    if ( !Files.exists(depthToCameraFilePath) ) {
      //Save the depth to camera space conversion table
      FloatBuffer mappingTable = kinect.getDepthToCameraSpaceTable();
      //Transfer to a float array
      float[] tmp = new float[dataFrameWidth * dataFrameHeight * 2];
      mappingTable.get(tmp);

      String serializedTable = Arrays.toString(tmp).replaceAll("\\[|\\]|\\s", "");
      try {
        // always create new file, failing if it already exists
        OutputStream out = Files.newOutputStream(depthToCameraFilePath, StandardOpenOption.CREATE_NEW);
        out.write( (serializedTable).getBytes() );
        out.flush();
        out.close();
      }
      catch(Exception e) {
        e.printStackTrace();
        return false;
      }
    }

    String recordingFileName = new Date().getTime()+".rec";
    filePath = Paths.get(sketchPath() + File.separator+ "data" + File.separator +recordingFileName);

    try {
      asyncFile = AsynchronousFileChannel.open(filePath, 
        StandardOpenOption.WRITE, 
        StandardOpenOption.CREATE);
        nextPosition = 0;
/*
      //Save the depth to camera space conversion table
      FloatBuffer mappingTable = kinect.getDepthToCameraSpaceTable();
      //Transfer to a float array
      float[] tmp = new float[dataFrameWidth * dataFrameHeight * 2];
      mappingTable.get(tmp);


      String serializedTable = Arrays.toString(tmp).replaceAll("\\[|\\]|\\s", "")+";";
      byte[] asBytes = (serializedTable).getBytes();
      asyncFile.write(ByteBuffer.wrap(asBytes), 0);
      nextPosition = asBytes.length;
      */
    }
    catch(Exception e) {
      e.printStackTrace();
      return false;
    }
    return true;
  }

  protected PVector markerCenter( Contour ctr ) {
    Rectangle boundingBox = ctr.getBoundingBox();
    return new PVector( boundingBox.x + boundingBox.width/2.0, boundingBox.y + boundingBox.height/2.0 );
  }

  private String sampleInCircle( PVector center, int radius, int[] depthData ) {
    int startX = floor(center.x - radius);
    int startY = floor(center.y - radius);
    int index = 0;

    String circle = "";
    for (int x = startX; x < floor(center.x + radius); x++) {
      if (x < 0 || x >= dataFrameWidth) { //outside the frame
        continue;
      }
      for (int y = startY; y < floor(center.y + radius); y++) {
        if ( y < 0 || y >= dataFrameHeight ) { //outside the frame
          continue;
        }
        index = y * dataFrameWidth + x;
        circle += String.format(":%d,%d,%d", x, y, depthData[index]);
      }
    }
    return circle.substring(1);
  }

  public void record( Contour[] markers, int[] depthData ) {
    if ( markers == null || markers.length < 3 ||
      markers[0] == null || markers[1] == null || markers[2] == null ) {
      //Not enough data to compute a centroid
      return;
    }

    PVector marker1 = markerCenter( markers[0] );
    PVector marker2 = markerCenter( markers[1] );
    PVector marker3 = markerCenter( markers[2] );

    //Centroid in depth space
    PVector centroid = PVector.add( marker1, marker2 )
      .add( marker3 )
      .div(3.0);

    //Sample the depth values around the centroid and serialize
    //as x:y:depth triplets
    int radius = 5;
    String frame = sampleInCircle( centroid, radius, depthData );
    //Sample halfway between centroid and 1st marker
    frame += "|"+sampleInCircle( PVector.add(centroid, marker1).div(2.0), radius, depthData );
    //Sample halfway between centroid and 2nd marker
    frame += "|"+sampleInCircle( PVector.add(centroid, marker2).div(2.0), radius, depthData );
    //Sample halfway between centroid and 3rd marker
    frame += "|"+sampleInCircle( PVector.add(centroid, marker3).div(2.0), radius, depthData );

    byte[] asBytes = (frame+";").getBytes();
    asyncFile.write(ByteBuffer.wrap(asBytes), nextPosition);
    nextPosition += asBytes.length;
  }

  public boolean stop() {
    try {
      asyncFile.force(false);
      asyncFile.close();
    }
    catch(Exception e) {
      e.printStackTrace();
      return false;
    }
    return true;
  }


  private PVector computeCloudAverage( String pointCloudData, float[] cameraSpaceTable ) {
    String[] components;
    int i, depthX, depthY;
    float depth, accX = 0, accY = 0, accZ = 0;
    String[] triplets = pointCloudData.split(":");

    i = 0;
    for (String triplet : triplets) {
      components = triplet.split(",");
      depthX = Integer.parseInt( components[0] );
      depthY = Integer.parseInt( components[1] );
      depth = Float.parseFloat( components[2] );
      accX += depth * cameraSpaceTable[(depthY * dataFrameWidth + depthX) * 2];
      accY += depth * cameraSpaceTable[(depthY * dataFrameWidth + depthX) * 2 + 1];
      accZ += depth;
      i++;
    }
    //  - compute 3D centroid
    return new PVector( accX/i, accY/i, accZ/i );
  }
  
  private float[] loadCameraSpaceTable() throws IOException, BadConversionTable{
      //Open recording file
      BufferedReader in = new BufferedReader(new FileReader( depthToCameraFilePath.toFile() ) );
      
      
       //Read mapping table
          String[] mappingTableStr = in.readLine().split(",");
          if ( mappingTableStr.length != dataFrameWidth * dataFrameHeight * 2 ) {
            in.close();
            throw new BadConversionTable();
          }
          float[] cameraSpaceTable = new float[dataFrameWidth * dataFrameHeight * 2];
          int i = 0;
          for (String f : mappingTableStr) {
            cameraSpaceTable[i] = Float.parseFloat(f);
            i++;
          }
          in.close();
          println("Mapping table loaded.");
          return cameraSpaceTable;
  }

  public Future<Boolean> exportToCSV(final File destinationFile) throws IOException {

    Files.deleteIfExists(destinationFile.toPath());

    Callable<Boolean> exportTask = new Callable<Boolean>() {
      public Boolean call() {
        AsynchronousFileChannel asyncCSVFile = null;
        FileInputStream inputStream = null;
        Scanner scan = null;
        try {
          //Read mapping table
          float[] cameraSpaceTable = loadCameraSpaceTable();
          
          //Open recording file
          inputStream = new FileInputStream( filePath.toFile() );
          scan = new Scanner(inputStream);
          scan.useDelimiter(java.util.regex.Pattern.compile(";"));

          //Open/create CSV file
          asyncCSVFile = AsynchronousFileChannel.open(destinationFile.toPath(), 
            StandardOpenOption.WRITE, 
            StandardOpenOption.CREATE);
          byte[] asBytes;
          int writePosition = 0;

          //For each frame
          String frame = "";//readLine(inputStream);
          String[] PCDs; //point cloud data
          PVector centroid, marker1, marker2, marker3, AB, BC, CA, normal;

          while (scan.hasNext()) {
            frame = scan.next();
            PCDs = frame.split("\\|");
            //println( "Length:" + PCDs.length );
            if (PCDs.length != 4) {
              println("Wrong frame format! Aborting.");
              scan.close();
              return false;
            }
            //  - compute 3D centroid
            centroid = computeCloudAverage( PCDs[0], cameraSpaceTable );
            //  - compute normal
            marker1 = computeCloudAverage( PCDs[1], cameraSpaceTable );
            marker2 = computeCloudAverage( PCDs[2], cameraSpaceTable );
            marker3 = computeCloudAverage( PCDs[3], cameraSpaceTable );
            AB = PVector.sub(marker1, marker2);
            BC = PVector.sub(marker2, marker3);
            CA = PVector.sub(marker3, marker1);
            normal = PVector.add(AB.cross(BC), BC.cross(CA)).add(CA.cross(AB)).div(3.0).normalize();
            normal.z = abs(normal.z);

            //  - write to destinationFile
            asBytes = (String.format(Locale.ROOT, "%f,%f,%f,%f,%f,%f", 
              centroid.x, centroid.y, centroid.z, 
              normal.x, normal.y, normal.z) + System.getProperty("line.separator")).getBytes();

            asyncCSVFile.write( ByteBuffer.wrap(asBytes), writePosition );
            writePosition += asBytes.length;

            //Process next frame
            //frame = readLine(inputStream);
          }

          //Clean up
          scan.close();
          inputStream.close();
          asyncCSVFile.force(false);
          asyncCSVFile.close();
        }
        catch(BadConversionTable e){
          e.printStackTrace();
          return false;
        }
        catch(IOException e) {
          e.printStackTrace();
          return false;
        }
        deleteRecording();
        return true;
      }
    };

    return exportExecutor.submit(exportTask);
  }

  public void deleteRecording() {
    try {
      Files.deleteIfExists(filePath);
    }
    catch(Exception e) {
      println("WARNING: could not delete tracking session recording file.");
    }
    filePath = null;
  }
}