import geomerative.*;
import java.util.HashMap;

class svgMapInterface implements MoveableComponent {

  boolean visible;
  int x, y, width, height;
  RShape mapShape;
  PImage backgroundMap;
  PFont font;
  PApplet parent;
  String selectedCountry;
  Set selectedCountries;
  String mouseOverText;
  float scaleFactor;

  Integrator _x, _y, _width, _height;

  svgMapInterface(PApplet parent, int x, int y, int width, int height) {
    this.parent = parent;
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    
    visible = true;

    _x = new Integrator(x);
    _y = new Integrator(y);
    _width = new Integrator(width);
    _height = new Integrator(height);

    selectedCountries = new HashSet();
    scaleFactor = width/900.0;
    
    backgroundMap = loadImage("BlankMap-World6.png");

    RG.init(parent);

    RG.setPolygonizer(RG.UNIFORMLENGTH);
    RG.setPolygonizerLength(3.0);
    mapShape = RG.loadShape("BlankMap-World6.svg");
    mapShape = RG.polygonize(mapShape);
    mapShape.translate(-mapShape.getTopLeft().x, -mapShape.getTopLeft().y);
    mapShape.transform(0, 0, width, height, false);
    /*println("Map size is " + mapShape.getTopLeft().x + ", " + mapShape.getTopLeft().y + " with " + mapShape.getWidth() + ", " + mapShape.getHeight());
    println("Component size is " + x + ", " + y + " and " + width + ", " + height);
    println("Map bounds are " + mapShape.getBoundsPoints()[0].x + ", " + mapShape.getBoundsPoints()[0].y);
    println("Map bounds are " + mapShape.getBoundsPoints()[1].x + ", " + mapShape.getBoundsPoints()[1].y);
    println("Map bounds are " + mapShape.getBoundsPoints()[2].x + ", " + mapShape.getBoundsPoints()[2].y);
    println("Map bounds are " + mapShape.getBoundsPoints()[3].x + ", " + mapShape.getBoundsPoints()[3].y);*/

    RG.ignoreStyles();
    //mapShape = RG.centerIn(mapShape, g);
    font = loadFont("Verdana-Bold-22.vlw");
    //scale the shape here?
    //mapShape.scale(scaleFactor, height/500.0);
  }
  
  GenericPlot getReference(){
    return null;
  }
  
  float getWidthTarget(){
    return _width.target;
  }
  
    public int getX() { return x; }
  public int getY() { return y; }
  public int getWidth() { return width; }
  public int getHeight() { return height; }

  void draw() {
    if(visible){
      updateIntegrators();
      noFill();
      stroke(255);  
      strokeWeight(0.5);
      //actually draw it
      image(backgroundMap, x, y, width, height);
      //drawOcean();
      //drawCountries();
      drawCountriesWithData();
      drawSelectedCountry();
      drawMouseOverText();
      noFill();
      //RG.shape(mapShape, x, y);  
      //println("Map size is " + mapShape.getTopLeft().x + ", " + mapShape.getTopLeft().y + " with " + mapShape.getWidth() + ", " + mapShape.getHeight());   
      //println("Component size is " + x + ", " + y + " and " + width + ", " + height);
      //noFill();
      //stroke(255,0,0);
      //rectMode(CORNER);
      //rect(x,y,this.width,this.height);
    }
  }

  void updateIntegrators() {
    _x.update();
    _y.update();
    _width.update();
    _height.update();

    x = int(_x.value);
    y = int(_y.value);
    width = int(_width.value);
    height = int(_height.value);

    mapShape.transform(0, 0, _width.value, _height.value, false);
  }

  void moveTo(int tx, int ty, int tw, int th) {
    _x.target(tx);
    _y.target(ty);
    _width.target(tw);
    _height.target(th);
  }

  void drawCountriesWithData() {
    boolean drawText = false;

    RShape toDraw;
    RPoint p = new RPoint(mouseX - x, mouseY - y);//mouseX - x - width/2, mouseY - y - height/2);
    Set s = countryMap.keySet();
    String myKey;
    Iterator i = s.iterator();
    while(i.hasNext()) {
      fill(203,144,88);
      myKey = (String) i.next();
      toDraw = mapShape.getChild( myKey );
      //println(myKey);
      if(toDraw.contains(p)) {
        fill(0xFFE01E00);
        //print("Over!");
        drawText = true;
        mouseOverText = (String) countryMap.get( myKey);
      }
      //RG.shape(toDraw, x + width/2, y + height/2);     
      //RG.shape(toDraw, toDraw.getTopLeft().x, toDraw.getTopLeft().y, width, height );     
      RG.shape(toDraw, x, y);
    }
    //draw mouseover text if required
    if(!drawText) {
      mouseOverText = null;
    }
  }


  void drawMouseOverText() {
    if(mouseOverText != null) {
      fill(0);
      textFont(font);
      textAlign(LEFT, BOTTOM);
      text(mouseOverText, mouseX, mouseY);
    }
  }

  boolean mouseOver() {
    return (mouseX > x && mouseX < (x+width) && mouseY > y && mouseY < (y+height));
  }

  void mousePressed() {
    //select a country if we're over one
    RShape toDraw;
    RPoint p = new RPoint(mouseX - x, mouseY - y);
    Set s = countryMap.keySet();
    String myKey;
    Iterator i = s.iterator();
    while(i.hasNext()) {
      myKey = (String) i.next();
      toDraw = mapShape.getChild(myKey);
      if(toDraw.contains(p)) {
        //two cases: control held and control not held
        selectedCountry = toDraw.name;
        if(keyCode == CONTROL) {
          if(!selectedCountries.contains(toDraw.name)) {
            selectedCountries.add(toDraw.name);
            ((VASTvis) parent).updateCountry(selectedCountries);
          }
          else {
            selectedCountries.remove(toDraw.name);
            ((VASTvis) parent).updateCountry(selectedCountries);
          }
        }
        else {
          //make this the only one selected
          selectedCountries.clear();
          selectedCountries.add(toDraw.name);
          ((VASTvis) parent).updateCountry(selectedCountries);
        }
      }
    }
  }
  
  void setAllRequiredCountries(){
    selectedCountries.clear();
    selectedCountries.add("Venezuela");
    selectedCountries.add("Yemen");
    //selectedCountries.add("Turkey");
    selectedCountries.add("Colombia");
    selectedCountries.add("Saudi_Arabia");
    selectedCountries.add("Iran");
    selectedCountries.add("Lebanon");
    selectedCountries.add("Pakistan");
    selectedCountries.add("Kenya");
    selectedCountries.add("Syria");
    
    ((VASTvis) parent).updateCountry(selectedCountries);
  }

  void drawSelectedCountry() {
    Iterator i = selectedCountries.iterator();
    String toTest;
    while(i.hasNext()) {
      RShape toDraw = mapShape.getChild((String) i.next());
      if(toDraw != null) {
        fill(0xFF3D00C4);
        RG.shape(toDraw, x, y);
      }
    }
  }

  void drawOcean() {
    RShape toDraw = mapShape.getChild("ocean");
    fill(0xffb3e6ef);
    stroke(0);
    strokeWeight(2);
    RG.shape(toDraw, x, y);
  }

  void drawCountries() {
    RShape toDraw;
    for(int i = 0; i < mapShape.children.length; i++) {
      stroke(255);
      strokeWeight(0.5);
      fill(0xFFDAC8B7);
      toDraw = mapShape.children[i];
      //no ocean!
      if(!toDraw.name.equals("ocean")) {
        RG.shape(toDraw, x, y);
      }
    }
  }
}














