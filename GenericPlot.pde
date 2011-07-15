import com.healthmarketscience.*;

class GenericPlot implements MoveableComponent {
  PApplet parent;

  boolean visible;
  int x, y, width, height;
  
  Integrator _x, _y, _width, _height; 

  float plotX1, plotY1;
  float plotX2, plotY2;
  float labelX, labelY;

  int xmin, xmax;
  int ymin, ymax;  
   
  float minValue, maxValue; // these are used to form the filter

  String xAxis_variable;
  String yAxis_variable;
  
  String xAxisLabel, yAxisLabel;

  float [] tabLeft, tabRight;

  float tabTop, tabBottom;
  float tabPad = 10;

  PFont plotFont;
  //contains PlotContents objects 
  ArrayList <PlotContents> contents; 

  ArrayList <Integer> colorChoices;
  
  Stack <Integer> colors;
  
  GenericPlot(PApplet parent, String xv, String yv, String xl, String yl){
    this.parent = parent;
    xAxis_variable = xv;
    yAxis_variable = yv;
    xAxisLabel = xl;
    yAxisLabel = yl;
    
    visible = true;
    
    _x = new Integrator(0);
    _y = new Integrator(0);
    _width = new Integrator(0);
    _height = new Integrator(0);

    
    minValue = maxValue = -1; //-1 means no selection!

    contents = new ArrayList<PlotContents>();

    Integer [] cc = {
      color(27, 158, 119), color(217, 95, 2), color( 117, 112, 179), color( 231, 41, 138), color( 102, 166, 30), color( 230, 171, 2), color( 166, 118, 29), color( 102, 102, 102) 
    };
    colors = new Stack<Integer>();
    for(int i = cc.length - 1; i>=0; i--){
      colors.push(cc[i]);
    }
    //colors.addAll(Arrays.asList(cc));
    //colorChoices = new ArrayList<Integer>(Arrays.asList(cc));
    colorChoices = new ArrayList<Integer>();
    for (int a: cc){
      colorChoices.add(a);
   }
    textMode(SHAPE);
    plotFont = createFont("Verdana-Bold-22.vlw", 20);
    textFont(plotFont);
  }
  
  GenericPlot getReference(){
    return this;
  }
  
  public float getWidthTarget(){
    return _width.target;
  }
  
  public int getX() { return x; }
  public int getY() { return y; }
  public int getWidth() { return width; }
  public int getHeight() { return height; }

  void updateContents(Set countriesToShow) { 
    //changes the plotcontents objects to show the relevant countries, and adds new ones as needed
    //two passes: are the ones here in the list?
    String toCheck;
    for(int i = contents.size() -1; i>=0; i--) {
      //reverse order so that I can delete
       toCheck = cityMap.get(contents.get(i).city); //look up country name for this city
      if (!countriesToShow.contains(toCheck)) {
        colorChoices.add(contents.get(i).col);
        colors.push(contents.get(i).col);
        contents.get(i).dispose(); //interrupt queries if needed - want this object to be garbage collected
        contents.remove(i);
        //println("Removing " + toCheck);
      }
    }
    /*for (int i = 0 ; i< contents.size(); i++) {
      println("Contents " + i + " is " + contents.get(i).city);
    }*/
    //then: iterate over set
    Iterator i = countriesToShow.iterator();
    boolean needToAdd = true;
    while(i.hasNext()) {
      toCheck = (String) i.next();
      for (int j = 0 ; j< contents.size(); j++) {
        if( contents.get(j).city.equals(countryMap.get(toCheck))) {
          needToAdd = false;
          break;
        }
      }
      if(needToAdd) {
        //println("Need to add " + countryMap.get(toCheck));
        
        if(xAxis_variable.equals("SYMPTOM")){    
          addSeries(new PlotContentsStringInteger( countryMap.get(toCheck)));  //call different contructor for synd
        }else if(yAxisLabel.contains("Percentage")){
          if(xAxisLabel.contains("Date")){
            addSeries(new PlotContents_PrognosisDate( countryMap.get(toCheck)));  
          }else{
            addSeries(new PlotContents_Prognosis( countryMap.get(toCheck)));  
          }
        }else if(yAxisLabel.contains("Cumulative")){
          addSeries(new PlotContentsDateNumber_Cumulative( countryMap.get(toCheck)));  
        }else if (xAxis_variable.startsWith("DATE")){
            addSeries(new PlotContentsDateNumber( countryMap.get(toCheck))); 
        }else{
          addSeries(new PlotContentsNumberNumber( countryMap.get(toCheck)));  
        }
      }
      needToAdd = true;
    }
    refresh();
  }
  
  void moveTo(int tx, int ty, int tw, int th){
    _x.target(tx);
    _y.target(ty);
    _width.target(tw);
    _height.target(th);
  }
  
  void updateIntegrators(){
    _x.update();
    _y.update();
    _width.update();
    _height.update();
    
    x = int(_x.value);
    y = int(_y.value);
    width = int(_width.value);
    height = int(_height.value);
    textMode(SHAPE);
    textFont(plotFont);
    textSize(width/55);
    //plotX1 = x + textWidth("000000") + textWidth(yAxisLabel) + 20;//120; 
    plotX1 = x + width/6;//120; 
    /*println("x is " + x);
    println("textWidth(ymax) is " + ""+ymax);
    println("textWidth(yAxisLabel) is " + textWidth(yAxisLabel));
    println("PlotX1 is " + plotX1);
    println();*/
    plotX2 = x + width - (width * 0.1);
    labelX = plotX1 - 2*textWidth(yAxisLabel)/3 - textWidth(""+ymax)-10;//50;
    plotY1 = y + 60;
    plotY2 = y + height - (height * 0.26);
    labelY = y + height - (height * 0.26) + 3.5*(textAscent() + textDescent());
    
    //println("stats are now " + x + ", " + y + " and " + width + ", " + height);
  }
  
  Map<String, List<String>> getFilter(){
    //gets the filter that this plot would like applied to other plots
    //by default, this is:
    Map toReturn = new HashMap<String, List<String>>();
    List tempList =  new ArrayList<String>();
    //println("Checking filter " + a.xAxis_variable + ": " + a.minValue + ", " + a.maxValue);
    if(minValue != -1 && maxValue != minValue){
      tempList.add( "" + contents.get(0).convertValueToDatabaseFormat(maxValue));
      tempList.add( "" + contents.get(0).convertValueToDatabaseFormat(minValue));
      //Collections.sort(tempList); //does string sort, this is no good!
      toReturn.put(new String(xAxis_variable), tempList);
      //println("Adding filter " + xAxis_variable + ": " + minValue + ", " + maxValue);
    }
    return toReturn;
  }

  void draw() {
    if(visible){
      updateIntegrators();
      textFont(plotFont);
      // Show the plot area as a white box  
      fill(255);
      rectMode(CORNERS);
      noStroke();
      rect(plotX1, plotY1, plotX2, plotY2);
      
      //check for updates in plots:
      for(PlotContents a: contents){
        if(a.dataChanged){
          refresh();
          a.dataChanged = false;
        }
      }
  
      drawFilter();
  
      drawTitleTabs();
      drawAxisLabels();
      drawXLabels() ;
      drawYLabels();
      drawData();
      //drawNormal();
    }
  }
  
 
  
  void drawFilter(){
    //overridden
  }

  void drawData() {
   //loop through contents and draw each set of data
    for(PlotContents a: contents){
      a.draw(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
      if(mouseOver()){
         a.drawDataHighlight(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
      }
      if(showStats)
        a.drawStats(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
      if(showMean)
        a.drawMean(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
    }
  }

  void drawAxisLabels() {
    if(! contents.isEmpty()) {
      PlotContents a = (PlotContents) contents.get(0);

      fill(0);
      textSize(width/55);
      textLeading(width/50);

      textAlign(CENTER, CENTER);
      if(deathsOnly){
        yAxisLabel = yAxisLabel.replaceFirst("patients", "deaths");
      }else{
        yAxisLabel = yAxisLabel.replaceFirst("deaths", "patients");
      }
      text(yAxisLabel, labelX, (plotY1+plotY2)/2);
      textAlign(CENTER);
      text(xAxisLabel, (plotX1+plotX2)/2, labelY);
    }
  }

  void drawXLabels() {
    fill(0);
    textSize(width/60);
    textAlign(CENTER);

    // Use thin, gray lines to draw the grid
    stroke(224);
    strokeWeight(1);

    if(xAxis_variable.startsWith("DATE")) {
      drawDateXLabels();
      return;
    }
    //do it based on logs!
    int powerOfTen = ceil(log(xmax-xmin)/log(10));

    int xLineInterval = int(pow(10, powerOfTen-1)) ;

    for (int row = xmin; row <= xmax; row++) {
      if (xLineInterval != 0 && (row-xmin) % xLineInterval == 0) {
        float x = map(row, xmin, xmax, plotX1, plotX2);
        text(row, x, plotY2 + textAscent() + textDescent());
        line(x, plotY1, x, plotY2);
      }
    }
  }

  void drawDateXLabels() {
    //do it based on logs!
    int xLineInterval = 10;
    long multiplierToLong = 86400000;

    Calendar current = Calendar.getInstance();
    Calendar next = Calendar.getInstance();

    float monthStart, monthEnd; //centre the month in the space available
    monthStart = plotX1;
    int dayOfMonth=0;
    float x =0 ;
    strokeWeight(1);
    
    textSize(width/55);
    
    Date firstDate = new Date(xmin * multiplierToLong);
    //println("First date is " + firstDate + " and last is " + new Date(xmax * multiplierToLong));

    for (int row = xmin; row <= xmax; row++) {
      x = map(row, xmin, xmax, plotX1, plotX2);
  
      current.setTime(new Date(row * multiplierToLong));
      next.setTime(new Date(((row+1) * multiplierToLong))); //next day!
      //stupid rounding errors still - eventually fix with eg Joda
      dayOfMonth = current.get(Calendar.DAY_OF_MONTH);
      if ((dayOfMonth == 9 || dayOfMonth==19) && (dayOfMonth != next.get(Calendar.DAY_OF_MONTH))) {
        //fill(128);
        text(next.get(Calendar.DAY_OF_MONTH), x, plotY2 + textAscent() + textDescent());
        stroke(224);
        line(x, plotY1, x, plotY2);
      }
  
      if(current.get(Calendar.MONTH) != next.get(Calendar.MONTH)) {
        stroke(224);
        line(x, plotY1, x, plotY2);
        //end of month mark
        monthEnd = x;
        fill(0);
        text(getMonthFromInt(current.get(Calendar.MONTH)), (monthStart + monthEnd)/2, plotY2 +  2*(textAscent() + textDescent()));
        stroke(0);
        line(x, plotY2, x, plotY2+2 * textAscent());
        monthStart = x;
      }
    }
  
    //last month hack:
    if(dayOfMonth > 20) {
      monthEnd =x;
      text(getMonthFromInt(current.get(Calendar.MONTH)), (monthStart + monthEnd)/2, plotY2 + 2*(textAscent() + textDescent()));
    }
  }
  

  public String getMonthFromInt(int iMonth) {
    String month = "invalid";
    DateFormatSymbols dfs = new DateFormatSymbols();
    String[] months = dfs.getMonths();
    if (iMonth >= 0 && iMonth <= 11)
      month = months[iMonth];
    return month;
  }

  void drawYLabels() {
    fill(0);
    textSize(width/60);
    textAlign(RIGHT);
  
    stroke(128);
    strokeWeight(1);
  
    int powerOfTen = ceil(log((ymax-ymin))/log(10));
  
    float volumeIntervalMinor = int(pow(10, powerOfTen-2)); 
    if(ymax > 0.8*pow(10,powerOfTen)){
      volumeIntervalMinor *=2;
    }
    volumeIntervalMinor = max(volumeIntervalMinor, 1); //always at least 1
    //int volumeIntervalMinor = powerOfTen * int(pow(10, powerOfTen-2));
    float volumeInterval = volumeIntervalMinor *5;
    //println("Intervals are " + volumeIntervalMinor + " and " + volumeInterval);
    if(normalise) {
      volumeInterval = 1.0;
      volumeIntervalMinor = 0.25;
      ymin = 0; 
      ymax = 1;
    /*}else if(showPercentages){
      volumeInterval = 20.0;
      volumeIntervalMinor = 5.0;
      ymin = 0; 
      ymax = 100;*/
    }
  
    for (float v = ymin; v <= (ymax); v += volumeIntervalMinor) {
      //if (v % volumeIntervalMinor == 0) {     // If a tick mark
      float y = map( v, ymin, ymax, plotY2, plotY1);  
      if ( (v-ymin) % volumeInterval == 0) {        // If a major tick mark
        float textOffset = textAscent()/2;  // Center vertically
        if (v == ymin) {
          textOffset = 0;                   // Align by the bottom
        } 
        else if (v == ymax) {
          textOffset = textAscent();        // Align by the top
        }
        text(nfc(floor(v)), plotX1 - 10, y + textOffset);
        line(plotX1 - 4, y, plotX1, y);     // Draw major tick
        //println(v);
      } 
      else {
        line(plotX1 - 2, y, plotX1, y);   // Draw minor tick
      }
    }
  }


  void refresh() {
    //update with new data!
    //noLoop();
    //get min and max for x and y from PlotContents!
    xmin = ymin = Integer.MAX_VALUE;
    xmax = ymax = Integer.MIN_VALUE;
  
    //loop over PlotContents
    PlotContents a;
    for(int i = 0; i< contents.size(); i++) {
      a = (PlotContents) contents.get(i);
  
      a.update(a.generateQuery(a.city, xAxis_variable, yAxis_variable), xAxis_variable, yAxis_variable);
  
      xmin = min(xmin, a.getMinX());
      xmax = max(xmax, a.getMaxX());
  
      ymin = min(ymin, a.getMinY());
      ymax = max(ymax, a.getMaxY());
    }
    if(normalise) {
      ymin = 0;
      ymax = 1;
    }
  
    //aesthetics for y!
    ymax *=1.1;
    //redraw();
    //println("Redraw!");
    //draw();
    //println("Using x min/max as " + xmin + ", " + xmax);
    //println("Using y min/max as " + ymin + ", " + ymax);
    //println("OK here!");
    //loop();
    
  }
  
  void addSeries(PlotContents c) {
  
    //color col = colorChoices[colorsUsed++];
    //if (colorsUsed >= colorChoices.length) colorsUsed = 0;
    //println("Color for " + country + " is " + col);
    /*if(!colorChoices.isEmpty()) {
      c.col = colorChoices.get(0);
      colorChoices.remove(0);
    }*/
    if(!colors.isEmpty()){
      c.col = colors.pop();
    }
    contents.add(c);
    refresh();
  }
  
  boolean mouseOver() {
    return (mouseX > x && mouseX < (x+width) && mouseY > y && mouseY < (y+height));
  }
  
  void mousePressed() {
   //overridden!
  }
  
  void mouseMoved(){
  }
  
  void mouseDragged(){
    //OVERRIDDEN
  }
  
  void mouseReleased(){
    //overridden
  }



  void drawTitleTabs() {
    rectMode(CORNERS);
    noStroke();
    textSize(width/45);
    textAlign(LEFT);
  
    // On first use of this method, allocate space for an array
    // to store the values for the left and right edges of the tabs
    if (tabLeft == null|| tabLeft.length != contents.size()) {
      tabLeft = new float[contents.size()];
      tabRight = new float[contents.size()];
    }
  
    float runningX = plotX1; 
    tabTop = plotY1 - textAscent() - 15;
    tabBottom = plotY1;
  
    for (int col = 0; col < contents.size(); col++) {
      String title = (contents.get(col)).city.substring(0,3);
      tabLeft[col] = runningX; 
      float titleWidth = textWidth(title);
      tabRight[col] = tabLeft[col] + tabPad + titleWidth + tabPad;
  
      // If the current tab, set its background white, otherwise use pale gray
      //fill(col == currentColumn ? 255 : 224);
      fill(255);
      rect(tabLeft[col], tabTop, tabRight[col], tabBottom);
  
      // If the current tab, use black for the text, otherwise use dark gray
      //fill(col == currentColumn ? 0 : 64);
      fill(contents.get(col).col);
      text(title, runningX + tabPad, plotY1 - 10);
  
      runningX = tabRight[col];
    }
  }
}
