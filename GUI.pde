ArrayList<UIElement> uiElements = new ArrayList<UIElement>();
ArrayList<ClickListener> mouseClickListeners = new ArrayList<ClickListener>();
ArrayList<DragListener> mouseDragListeners = new ArrayList<DragListener>();

//Keep a reference to these elements so a key can be mapped to their actions
ToggleButton recordToggle;

void createUI() {
  recordToggle = new ToggleButton( this.g, dataFrameWidth+10, 10, "Record", false, 
    new ToggleAction() {
    public void toggle(boolean on) {
      if (on && !recording) {
        exportResult = null;
        frameRecorder.prepare();
        recording = on;
      } else if (!on && recording) {
        recording = false;
        frameRecorder.stop();
        selectOutput("Select a file to write to:", "fileSelected");
      }
    }
  }
  );
  uiElements.add( recordToggle );
  mouseClickListeners.add( recordToggle );

  ToggleButton roiEditToggle = new ToggleButton( this.g, recordToggle.rightOf(), 10, "Edit ROI", false, 
    new ToggleAction() {
    public void toggle(boolean on) {
      if (on && !editROI) {
        editROI = on;
      } else if (!on && editROI) {
        editROI = false;
      }
    }
  }
  );
  mouseClickListeners.add( roiEditToggle );
  uiElements.add( roiEditToggle );

 

  final Label thresholdLabel = new Label(this.g, dataFrameWidth+10, recordToggle.belowOf(), "Threshold: "+settings.brightnessThreshold);
  ;
  uiElements.add( thresholdLabel );
  final Slider thresholdSlider = new Slider( this.g, dataFrameWidth+10, thresholdLabel.belowOf(), dataFrameWidth, 40, 0, 255, settings.brightnessThreshold, 
    new SliderAction() {
    public void changed(float val) {
      settings.brightnessThreshold = (int)val;
      thresholdLabel.setText("Threshold: "+settings.brightnessThreshold);
    }
  }
  );
  mouseDragListeners.add( thresholdSlider );
  uiElements.add( thresholdSlider );
  
   Button loadSettingsButton = new Button( this.g, dataFrameWidth+10, thresholdSlider.belowOf(), "Load settings", 
    new ToggleAction() {
    public void toggle(boolean on) {
      Settings s = loadSettingsFromFile();
      if (s!=null) {
        settings = s;
        thresholdSlider.setVal(settings.brightnessThreshold);
      }
    }
  });
  mouseClickListeners.add( loadSettingsButton );
  uiElements.add( loadSettingsButton );
  
   Button saveSettingsButton = new Button( this.g, loadSettingsButton.rightOf(), thresholdSlider.belowOf(), "Save settings", 
    new ToggleAction() {
    public void toggle(boolean on) {
      saveSettingsToFile(settings);
    }
  });
  mouseClickListeners.add( saveSettingsButton );
  uiElements.add( saveSettingsButton );
}


void drawUI() {
  for (UIElement elem : uiElements) {
    elem.update(this.g);
  }
}

void keyReleased() {
  switch(key) {
    case ' ':
      recordToggle.toggle();
  }
}


void mouseClicked() {
  for (ClickListener elem : mouseClickListeners) {
    elem.mouseClicked();
  }
}

void mouseDragged() {

  for (DragListener elem : mouseDragListeners) {
    elem.mouseDragged();
  }

  if (!editROI) {
    return;
  }
  //Update ROI rectangle if dragging one of the handles
  if ( !translateROI && !resizeROI ) {
    return;
  }

  int dX = mouseX - pmouseX;
  int dY = mouseY - pmouseY;

  if (translateROI) {
    settings.ROI.translate(dX, dY);
  } else {
    settings.ROI.grow(dX, dY);
  }
  doCV();
}

interface UIElement {
  public void update(PGraphics pg);
  public void enable(boolean enabled);
  public float leftOf();
  public float rightOf();
  public float aboveOf();
  public float belowOf();
}

interface ClickListener {
  public void mouseClicked();
}

interface DragListener {
  public void mouseDragged();
}

interface ToggleAction {
  public void toggle(boolean on);
}

boolean isMouseOver(float x, float y, float w, float h) {
  return mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h;
}

class Label implements UIElement {
  float x, y;
  float labelW, labelH, totalWidth, totalHeight, textX, textY;
  String label;
  boolean ready = false;

  public Label(PGraphics pg, float x, float y, String label) {
    this.x = x;
    this.y = y;
    this.label = label;
    pg.pushStyle();
    pg.textSize(14);
    computeSize(pg);
    pg.popStyle();
  }

  public void setText(String label) {
    this.label = label;
    ready = false;
  }

  public void computeSize(PGraphics pg) {
    labelH = 14;
    totalHeight = labelH + 10;
    labelW = textWidth(label);
    totalWidth = labelW + 20;
    textX = x + totalWidth/2 - labelW/2;
    textY = y + totalHeight/2 + labelH/2;
    ready = true;
  }

  public void update(PGraphics pg) {
    pg.pushStyle();
    pg.textSize(14);
    if ( !ready ) {
      computeSize(pg);
    }
    pg.fill(255);
    pg.text(label, textX, textY);
    pg.popStyle();
  }

  public void enable(boolean enabled) {
  }

  public float leftOf() {
    return x - 10;
  }
  public float rightOf() {
    return x + totalWidth + 10;
  }
  public float aboveOf() {
    return y - 10;
  }
  public float belowOf() {
    return y + totalHeight + 10;
  }
}

class ToggleButton implements UIElement, ClickListener {
  float x, y;
  float labelW, labelH, totalWidth, totalHeight, textX, textY;
  String label;
  boolean on;
  boolean enabled = true;
  boolean ready = false;
  color onFill = color(0, 255, 0);
  color offFill = color(255, 255, 255);
  color onText = color(0, 0, 255);
  color offText = color(0, 0, 0);
  ToggleAction action;

  public ToggleButton(PGraphics pg, float x, float y, String label, boolean on, ToggleAction action) {
    this.x = x;
    this.y = y;
    this.label = label;
    this.on = on;
    this.action = action;
    this.action.toggle(this.on);
    pg.pushStyle();
    pg.textSize(26);
    computeSize(pg);
    pg.popStyle();
  }

  public float leftOf() {
    return x - 10;
  }
  public float rightOf() {
    return x + totalWidth + 10;
  }
  public float aboveOf() {
    return y - 10;
  }
  public float belowOf() {
    return y + totalHeight + 10;
  }
  
  public void toggle(){
      this.on = !this.on;
      this.action.toggle(this.on);
  }

  public void mouseClicked() {
    if ( isMouseOver(x, y, totalWidth, totalHeight) ) {
      toggle();
    }
  }

  public void computeSize(PGraphics pg) {
    labelH = 26;
    totalHeight = labelH + 10;
    labelW = textWidth(label);
    totalWidth = labelW + 20;
    textX = x + totalWidth/2 - labelW/2;
    textY = y + totalHeight/2 + labelH/2;
    ready = true;
  }

  public void update(PGraphics pg) {

    pg.pushStyle();
    pg.textSize(26);
    if ( !ready ) {
      computeSize(pg);
    }

    fill( on? onFill : offFill );
    pg.rect(x, y, totalWidth, totalHeight);
    fill( on? onText : offText );
    pg.text(label, textX, textY);
    pg.popStyle();
  }

  public void enable(boolean enabled) {
    this.enabled = enabled;
  }
}

class Button extends ToggleButton {

  color onFill = color(255, 255, 255);
  color onText = color(0, 0, 0);

  public Button(PGraphics pg, float x, float y, String label, ToggleAction action) {
    super(pg, x, y, label, false, action);
  }

  public void mouseClicked() {
    if ( isMouseOver(x, y, totalWidth, totalHeight) ) {
      this.action.toggle(true);
    }
  }
}

interface SliderAction {
  public void changed(float val);
}

class Slider implements UIElement, DragListener {
  float x, y, w, h, min, max, val, handleW, handleH;
  boolean horizontal;
  SliderAction action;

  public Slider(PGraphics pg, float x, float y, float w, float h, float min, float max, float val, SliderAction action) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.min = min;
    this.max = max;
    this.val = val;
    this.action = action;
    action.changed(val);

    horizontal = w > h;
    if (horizontal) {
      handleW = 100;
      handleH = h;
    } else {
      handleW = w;
      handleH = 100;
    }
  }

  private float handlePosition() {
    if (horizontal) {
      return map(this.val, this.min, this.max, this.x, this.x+this.w-handleW);
    } else {
      return map(this.val, this.min, this.max, this.y, this.y+this.h-handleH);
    }
  }

  public void update(PGraphics pg) {
    pg.pushStyle();
    float handlePos = handlePosition();
    pg.fill(255);
    pg.rect(x, y, w, h);

    pg.fill(0, 255, 0);
    if (horizontal) {
      pg.rect(handlePos, y, handleW, handleH);
    } else {
      pg.rect(x, handlePos, handleW, handleH);
    }
    pg.popStyle();
  }

  public void enable(boolean enabled) {
  }

  private float valueAtPosition(float handlePosition) {
    if (horizontal) {
      return max(min(map(handlePosition, this.x, this.x+this.w-handleW, this.min, this.max), this.max), this.min);
    } else {
      return max(min(map(handlePosition, this.y, this.y+this.h-handleH, this.min, this.max), this.max), this.min);
    }
  }

  public void setVal(float val) {
    this.val = val;
    action.changed(val);
  }

  public void mouseDragged() {
    float handlePos = handlePosition();
    boolean isDragging = horizontal ? isMouseOver(handlePos, y, handleW, handleH) : isMouseOver(x, handlePos, handleW, handleH);
    if (!isDragging) {
      return;
    }

    setVal( valueAtPosition( horizontal ? handlePos + mouseX - pmouseX : handlePos + mouseY - pmouseY ) );
  }

  public float leftOf() {
    return x - 10;
  }
  public float rightOf() {
    return x + w + 10;
  }
  public float aboveOf() {
    return y - 10;
  }
  public float belowOf() {
    return y + h + 10;
  }
}