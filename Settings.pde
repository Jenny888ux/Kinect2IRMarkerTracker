import java.io.*;
Settings settings = null;
/*
 
*/
public static class Settings implements java.io.Serializable {
  public Rectangle ROI = new Rectangle(10, 10, dataFrameWidth-20, dataFrameHeight-20);
  public int brightnessThreshold = 150;
}

void saveSettingsToFile(Settings s) {
    try {
      OutputStream fileOut = createOutput("data/settings.ser");
      ObjectOutputStream out = new ObjectOutputStream(fileOut);
      out.writeObject(s);
      out.close();
      fileOut.close();
      println("Settings saved to data/settings.ser");
    } 
    catch (IOException i) {
      i.printStackTrace();
    }
  }

Settings loadSettingsFromFile() {
  Settings e;
  try {
    InputStream fileIn = createInput("data/settings.ser");
    if(fileIn == null){
      return null;
    }
    ObjectInputStream in = new ObjectInputStream(fileIn);
    e = (Settings) in.readObject();
    in.close();
    fileIn.close();
  } 
  catch (IOException i) {
    i.printStackTrace();
    return null;
  } 
  catch (ClassNotFoundException c) {
    System.out.println("Settings class not found");
    c.printStackTrace();
    return null;
  }
  println("Settings loaded from /data/settings.ser");
  return e;
}