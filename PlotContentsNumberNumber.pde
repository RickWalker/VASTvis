class PlotContentsNumberNumber extends PlotContents {

  PlotContentsNumberNumber(String a) {
    super(a);
    values = new HashMap<Integer, Integer>();
  }


  void update(String query, String xv, String yv) {
    //determines query string and populates the TreeMap as needed

    if(!query.equals(previousQuery)) {
      if(queryCache.containsKey(query)){
        getDataFromCache(query);
      }else{
        if(myQuery != null){
          //already querying
          myQuery.cancel();
          }
        myQuery = new QueryThread(parentApp, query, xv, yv);
        needsUpdate = true;
        upToDate.target(20);
      }
      
      previousQuery = query;
      //updateStats(yv);
    }
    else {
      //println("Using cached results for " + query);
    }
    //println(country);
    //println("xmin, xmax " + xmin + " " + xmax);
    //println("ymin, ymax " + ymin + " " + ymax);
  }
  


  String convertValueToDatabaseFormat(float v) {
    return ""+v;
  }
  
  float convertValueFromDatabaseFormat(String s){
    return float(s);
  }

  void draw(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    upToDate.update();
    if(myQuery != null){
      if(myQuery.available()){
        getDataFromThread();
        needsUpdate = false;
        dataChanged = true;
        upToDate.target(255);
        //println("Got data from thread!" + myQuery.query);
        myQuery = null;
      }
    }
    //if(needsUpdate){
    //  stroke(128, 40);
    //  fill(128, 40);
    //  rect(plotX1, plotY1, plotX2, plotY2);
    //}
    strokeWeight(2);
    stroke(color(red(col), green(col), blue(col), upToDate.value));
    noFill();
    if(!values.isEmpty() && !dataChanged){ //not if empty, and not first time after update because min and max may be wrong
      if(smoothed){
        drawSmoothed(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
      }else{
        drawNonSmoothed(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
      }  
    }
    
  }
  
  void drawNonSmoothed(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    float tx, ty;
    float value = 0;
    beginShape();
    for(int j = xmin; j <= xmax; j++) {
      value = get(j); 
      if(value <= -1) value = 0;
      //plot it!
      tx = map(j, xmin, xmax, plotX1, plotX2);
      if(normalise) {
        value = normalise(value);
        ty = map(value, 0, 1.0, plotY2, plotY1);
      }else{
        ty = map(value, ymin, ymax, plotY2, plotY1);
      }
      vertex(tx, ty);
    } 
    endShape();
  }
  
  void drawSmoothed(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    //moving average of five values to smooth out graph!
    float value, total, tx=0.0, ty=0.0;
    int count = 0;
    beginShape();
    //force first vertex
    for(int j = xmin; j <= xmax; j++) {
      total = 0;
      count = 0;
      float t;
      for(int i =j-2; i<=j+2;i++){ //five point moving average! but less if no info
        t = get(i);
        if (t != -1){
          total += t;
          count++;
        }
      }
      if(count!=0){
        value = total/float(count); //because we might not have five values
      }else{
        value = ymin; //no values to average!
      }
      tx = map(j, xmin, xmax, plotX1, plotX2);
      if(normalise) {
        value = normalise(value);
        ty = map(value, 0, 1.0, plotY2, plotY1);
      }else {
        ty = map(value, ymin, ymax, plotY2, plotY1);
      }
      curveVertex(tx, ty);
      if(j == xmin)
        curveVertex(tx, ty); //hack for start
    }
    curveVertex(tx, ty);
    endShape();
  }

  void drawDataHighlight(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    float tx, ty;
    float value = 0;

    for(int j = xmin; j <= xmax; j++) {

      value = get(j); 

      if(value <= -1) value = 0;
      //plot it!
      tx = map(j, xmin, xmax, plotX1, plotX2);
      if(normalise) {
        value = normalise(value);
        ty = map(value, 0, 1.0, plotY2, plotY1);
      }
      else {
        ty = map(value, ymin, ymax, plotY2, plotY1);
      } 
      if (dist(mouseX, mouseY, tx, ty) < 3) {
        strokeWeight(10);
        point(tx, ty);
        fill(0);
        textSize(10);
        textAlign(CENTER);
        String toShow = nf(value, 1, 2) + " (" +convertForDisplay(j) + ")";
        if( (tx-plotX1) < textWidth(toShow)/2){
          textAlign(LEFT);
        }else if ( (plotX2 - tx) < textWidth(toShow)/2){
          //textAlign(RIGHT); //don't need to do this, overflow on right is fine
        }else{
          textAlign(CENTER);
        }
        text(toShow, tx, ty-8);
        textAlign(LEFT);
        if(showStats)
          drawStats(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
        if(showMean)
          drawMean(xmin, xmax, ymin, ymax, plotX1, plotY1, plotX2, plotY2);
          
      }
    }
  }
  
  void updateStats(){
    super.updateStats();
    //work out whiskers!
    float interquartileRange = q3-q1;
    float threeovertwoiqr = 3.0/2.0 * interquartileRange;
    whiskerTop = Float.MIN_VALUE;
    whiskerBottom = Float.MAX_VALUE;
//    /float value;
    for(int j = xmin; j <= xmax; j++) {
      //value = get(j); 
      if(j > q3){
        if((j - threeovertwoiqr) <=q3){
          //within range
          whiskerTop = max(whiskerTop, j);
        }
      }else if(j < q1){
        if((j + threeovertwoiqr)>=q1){
          whiskerBottom = min(whiskerBottom, j);
        }
      }
    }
    //println("Whiskers are " + whiskerTop + " and " + whiskerBottom);
  }
}

