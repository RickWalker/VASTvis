class PlotContents_Prognosis extends PlotContentsNumberNumber {

  String prevInvQuery = "";
  String prevQuery = "";
  float highest;

  //TreeMap<Integer, Integer> invValues;
  Map<Integer, Integer> invValues;
  Map<Integer, Integer> tempValues;    
  //TreeMap<Integer, Integer> tempValues;
  String invQuery, query;

  QueryThread myQuery2;

  PlotContents_Prognosis(String a) {
    super(a);
  }

void update(String query, String xv, String yv) {
  boolean newQueryLaunched = false;
  //needsUpdate = false;
//    /String invQuery;
  //determines query string and populates the TreeMap as needed

  //always do query1 / query2 because that makes things a lot easier

  //generate query strings
  if(deathsOnly) {
    query = generateQuery(city, xv, yv); //so this is people who die
    deathsOnly = false;
    invQuery = generateQuery(city, xv, yv); //this is all people 
    deathsOnly = true; //back to original value
  }
  else {
    invQuery = generateQuery(city, xv, yv);//this is all people
    deathsOnly = true;
    query = generateQuery(city, xv, yv); //so this is people who die
    deathsOnly = false; //back to original value
  }

  //println("Deaths query is " + query);
  //println("All query is " + invQuery);

  if(!query.equals(prevQuery)){
      //now, check with cache and/or launch thread for each:
      if(queryCache.containsKey(query)) {
        getDataFromCache(query);
        tempValues = values;
      }
      else {
        if(myQuery != null) {
          //already querying
          myQuery.cancel();
        }
        myQuery = new QueryThread(parentApp, query, xv, yv);
        newQueryLaunched = true;
        this.query = query; //so hacky!
        needsUpdate = true;
        upToDate.target(20);
      }
      prevQuery = query;
  }

  if(!invQuery.equals(prevInvQuery)){
  
      if(queryCache.containsKey(invQuery)) {
        getDataFromCache(invQuery);
        invValues = values;
      }
      else {
        if(myQuery2 != null) {
          //already querying
          myQuery2.cancel();
        }
        myQuery2 = new QueryThread(parentApp, invQuery, xv, yv);
        newQueryLaunched = true;
        needsUpdate = true;
        upToDate.target(20);
      }
      prevInvQuery = invQuery;
  }

  println("new Query Launched is " + newQueryLaunched);
  
  //special case - all up to date but cached!
  if(myQuery == null && myQuery2 == null){
    println("Doing percentage treemap since no new queries " + newQueryLaunched);
      values = calculatePercentageTreeMap(invValues, tempValues);
  }

    //now handle the inv business in draw?
  }

  TreeMap calculatePercentageTreeMap(Map<Integer, Integer> addms, Map<Integer, Integer> dths) {
    TreeMap results = new TreeMap<Integer, Float>();
    //also needs to update min, max and stats?

    
    ymin = Integer.MAX_VALUE;
    ymax = Integer.MIN_VALUE;
    
    int val_addms, val_dths;
    int otherI = 0;
    highest = Float.MIN_VALUE;
    
    float temp_ymax = Float.MIN_VALUE;
    
    //one pass just to get the highest number of admissions!

    for(Integer newA: addms.keySet()){
        val_addms = (Integer)addms.get(newA);
        highest = max(highest, val_addms);
    }
    
    for(Integer newA: addms.keySet()){

        val_addms = (Integer)addms.get(newA);

       if(dths.get(newA) != null){
        val_dths = (Integer)dths.get(newA);
       }else{
         val_dths = 0;
       }
             
        Float perc_f = (float)(((float)val_dths / (float)val_addms) * 100);
        
        if(val_addms < 0.01*highest)
          perc_f = 0.0;
        
        ymin = (int) min(perc_f, ymin);
        temp_ymax = max(perc_f, temp_ymax);
        
        //print("\nAdmin : " + val_addms + ", Deaths : " + val_dths + ", Perc : " + perc_f + ", Age: " + newA);
        results.put(newA, perc_f);
    }
    
    ymax =ceil(temp_ymax); //hack!
    return results;    
  }


  String convertValueToDatabaseFormat(float v) {   
    return ""+v;
  }
  
  float convertValueFromDatabaseFormat(String s){
    return float(s);
  }
  
  float get(Number j){
    if(values.containsKey(j)){
      float a = ((Number) values.get(j)).floatValue();
      //hack!
      if(normalise) a = map(a, ymin, ymax, 0, 1.0);
      return a;
    }else{
      return 0.0;
    }
  }

  void draw(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    upToDate.update();
    if(myQuery != null){
      if(myQuery.available()){
        getDataFromThread();
        //needsUpdate = false;
        //dataChanged = true;
        //upToDate.target(255);
        //println("Got data from thread!" + myQuery.query);
        myQuery = null;
      }
    }
        
    if(myQuery2 != null){
      if(myQuery2.available()){
        getDataFromOtherThread();
       
        //println("Got data from thread!" + myQuery.query);
        myQuery2 = null;
      }
    }
    
    if(myQuery2 == null && myQuery == null){
      if(needsUpdate){
        //if we're here because something just finished:
        values = calculatePercentageTreeMap(invValues, tempValues);
         //no queries running, must be up to date!
          needsUpdate = false;
          dataChanged = true;
          println("Worked out new treemap");
          upToDate.target(255);
      }
    }
  
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

  void drawDataHighlight(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    float tx, ty;
    float value = 0;

    for(int j = xmin; j <= xmax; j++) {

      value = get(j); 

      if(value <= -1) value = 0;
      //plot it!
      tx = map(j, xmin, xmax, plotX1, plotX2);
     // if(normalise) {
       // ty = map(value, 0, 1.0, plotY2, plotY1);
      //}
      //else {
        ty = map(value, ymin, ymax, plotY2, plotY1);
     // } 
      if (dist(mouseX, mouseY, tx, ty) < 3) {
        strokeWeight(10);
        point(tx, ty);
        fill(0);
        textSize(10);
        textAlign(CENTER);
        String toShow;
        int topValue = 0, bottomValue = 0;
        if(tempValues.get(j) != null)
          topValue = (Integer) tempValues.get(j);
        
        if( invValues.get(j) != null)
          bottomValue = (Integer) invValues.get(j);
        
        if(deathsOnly){
          toShow = (nf(value,1,2) + "%\n" + topValue + " / " + bottomValue + " (" +convertForDisplay(j) + ")");
        }else{
          toShow = (nf(value,1,2) + "%\n" + bottomValue + " / " + topValue + " (" + convertForDisplay(j) + ")");
        }
        if((tx-plotX1) < textWidth(toShow))
          textAlign(LEFT);
        text(toShow, tx, ty-2*(textAscent() + textDescent()));
      }
    }
  }
  
    void getDataFromThread(){//String query, String xv, String yv) {
        //needs to do this for new thread, because need two queries not one

      //perform query
      QueryResultSet temp = myQuery.getAllResults();
      tempValues = temp.data;
      //plotStats = temp.plotStats;
      //min/max
      xmin = int(temp.xmin);
      xmax = int(temp.xmax);
      ymin = int(temp.ymin);
      ymax = int(temp.ymax);

      //stats  
      mean = temp.mean;
      median = temp.median;
      q1 = temp.q1;
      q3 = temp.q3;
      sd = temp.sd;
      skewness = temp.skewness;
      kurtosis = temp.kurtosis;
      //harder: work out whisker top and bottom!
      tenthpercentile = temp.tenthpercentile;
      ninetiethpercentile = temp.ninetiethpercentile;

      totalValues = temp.matchCount;
      ymin = 0;
      //add to cache!
      queryCache.put(temp.query, temp);
    }
  
  void getDataFromOtherThread(){//String query, String xv, String yv) {
        //needs to do this for new thread, because need two queries not one

      //perform query
      QueryResultSet temp = myQuery2.getAllResults();
      invValues = temp.data;
      //plotStats = temp.plotStats;
      //min/max
      xmin = int(temp.xmin);
      xmax = int(temp.xmax);
      ymin = int(temp.ymin);
      ymax = int(temp.ymax);

      //stats  
      mean = temp.mean;
      median = temp.median;
      q1 = temp.q1;
      q3 = temp.q3;
      sd = temp.sd;
      skewness = temp.skewness;
      kurtosis = temp.kurtosis;
      //harder: work out whisker top and bottom!
      tenthpercentile = temp.tenthpercentile;
      ninetiethpercentile = temp.ninetiethpercentile;

      totalValues = temp.matchCount;
      ymin = 0;
      //add to cache!
      queryCache.put(temp.query, temp);
    }
  }

