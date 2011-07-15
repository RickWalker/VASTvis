import com.healthmarketscience.*;

class GenericPlotString extends GenericPlot implements MoveableComponent {
  //like generic plot, but holds strings on the x axis, so some code needs to change!
  //in fact, interaction code needs to change - rest is same?
  
  //int selection_start, selection_end;
  boolean isDragging = false;
  
  //float minValue, maxValue; // these are used to form the filter
  Set <String> wordsToFilter;
  int maxSeries;
  Map <String, List<Float>> categorisedVersion;
  
  GenericPlotString(PApplet parent, String xv, String yv, String xl, String yl){
    super(parent, xv, yv, xl, yl);
    wordsToFilter = new HashSet<String>();
    categorisedVersion = new HashMap<String, List<Float>>();
  }
  
  void refresh(){
    if(invertSelection){
      invertSelection = false;
      //do the invert!
      //ie, add everything not in wordsToFilter
      Set <String> newWordsToFilter = new HashSet<String>();
      for(String a:symptomFilters.keySet()){
        if(!wordsToFilter.contains(a)){
          newWordsToFilter.add(a);
        }        
      }
      wordsToFilter = newWordsToFilter;
      //update filter in parent?
      ((VASTvis) parent).refreshFilters(); //such a hack
    }
    if(pandemicSymptoms){
      pandemicSymptoms = false;
      //clear all others
      wordsToFilter.clear();
      wordsToFilter.add("Abdominal Pain");
      wordsToFilter.add("Back Pain");
      wordsToFilter.add("Diarrhoea");
      wordsToFilter.add("Fever");
      wordsToFilter.add("Bleeding Nose");
      wordsToFilter.add("Vomitting");
    }
      
    
    super.refresh();
    //categorise new data!
    maxSeries = 0;
    categorisedVersion = new TreeMap<String, List<Float>>();
    PlotContentsStringInteger temp;
    for(PlotContents a: contents){
      //force a to PlotContentsStringInteger:
      temp = (PlotContentsStringInteger) a;
      for(Object bb: temp.values.keySet()){
        String b = (String) bb;
        if(categorisedVersion.get(b) != null){
          categorisedVersion.get(b).add(float((Integer) temp.values.get(b)));
          maxSeries = max(maxSeries, categorisedVersion.get(b).size());
          //categorisedVersion.put(b, categorisedVersion.get(b).add(float(temp.categorisedSymptoms.get(b))));
        }else{
          categorisedVersion.put(b, new ArrayList(Arrays.asList(new Float[]{float((Integer) temp.values.get(b))})));
          maxSeries = max(maxSeries, 1);
        }
      }
    //pull out each category
    }
   
    maxSeries ++; //for gap between bars, pretend there's one more series than there actually are
  }

  void drawData() {
    
    //thread stuff here!
    for(PlotContents a: contents){
       a.upToDate.update();
       if(a.myQuery != null){
        if(a.myQuery.available()){
          a.getDataFromThread();
          a.needsUpdate = false;
          a.upToDate.target(255);
          //a.dataChanged = true;
          refresh();
          println("Got data from thread!");
          a.myQuery = null;
        }
      }
      //if(a.needsUpdate){
      //  stroke(128, 40);
      //  fill(128, 40);
       // rect(plotX1, plotY1, plotX2, plotY2);
     // }
    }
    //println("\nDrawing PlotString!\n");
    //need to be fancier here!
    //first one determines 'order'?
    //actually, pull out all categories first, then get collection of numbers for each
 
    int categoryCount = 0;
    //int plotCount = 0;
    float barWidth = (plotX2-plotX1) * (float)(1.0f/(xmax*maxSeries));  // width of syndrome bars
    float tx, ty;
    
    //work out top five symptoms? sort map by value
    
    for(String b:categorisedVersion.keySet()){ 
      
      //show highlight for selected categories
      if(wordsToFilter.contains(b)){
        noStroke();
        fill(128,128,128,128);
        rectMode(CORNER);
        rect(map(categoryCount*maxSeries, xmin*maxSeries, xmax*maxSeries, plotX1+2, plotX2), plotY1, barWidth * maxSeries, plotY2-plotY1);
      }
      
      //for each category
      //draw label!
      if(keySymptoms.contains(b)){
        translate(map(categoryCount*maxSeries, xmin*maxSeries, xmax*maxSeries, plotX1+2, plotX2) + barWidth/2, plotY2 + 2);
        rotate(PI/2);
        fill(0);
        stroke(0);
        textSize(barWidth*maxSeries* (2/3.0));
        textAlign(LEFT, BOTTOM);
        text(b, 0, 0);
        rotate(-PI/2);
        translate(-map(categoryCount*maxSeries, xmin*maxSeries, xmax*maxSeries, plotX1+2, plotX2) - barWidth/2, -plotY2 - 2);
      }
      int plotCount = 0;
      for(float a: categorisedVersion.get(b)){
        //get colour!
        noStroke();
        rectMode(CORNER);
        color fc = contents.get(plotCount).col;
        fc = color(red(fc), green(fc), blue(fc), contents.get(plotCount).upToDate.value);
        fill(fc);    //hack this later
        tx = map(categoryCount*maxSeries + plotCount, xmin*maxSeries, xmax*maxSeries, plotX1+2, plotX2);
       
       if (showPercentages && !normalise)
          ty = map(a/float(contents.get(plotCount).totalValues) * 100, ymin, ymax, plotY2, plotY1);
        else if(normalise && showPercentages){
          //println("ymax for normalise is " + ymax);
          ty = map(map(a/float(contents.get(plotCount).totalValues) * 100, contents.get(plotCount).ymin, contents.get(plotCount).ymax, 0.0, 1.0), 0.0, 1.0, plotY2, plotY1);
        }else if(normalise){
          ty = map(map(a, contents.get(plotCount).ymin, contents.get(plotCount).ymax, 0.0, 1.0), 0.0, 1.0, plotY2, plotY1);
        }
        else
          ty = map(a, ymin, ymax, plotY2, plotY1);
        rect(tx + barWidth/2, ty, barWidth,plotY2-ty);
        if (dist(mouseX, ty, tx+barWidth, ty) < barWidth/2.0 && mouseY >= ty && mouseY <= plotY2) {
          strokeWeight(10);
          point(tx, ty);
          fill(0);
          textSize(10);
          String toShow = nf(a, 0, 2) + " (" + b + ")";
          if(showPercentages)
            toShow = nf(a/float(contents.get(plotCount).totalValues) *100,1,1) + "% (" + b + ")";
          if( (tx-plotX1) < textWidth(toShow)/2){
            textAlign(LEFT);
          }else if ( (plotX2 - tx) < textWidth(toShow)/2){
            //textAlign(RIGHT); //don't need to do this, overflow on right is fine
          }else{
            textAlign(CENTER);
          }
          text(toShow, tx, ty-8);
          textAlign(LEFT); //in case it's assumed elsewhere
        }  
        plotCount++;
      //println("plotCount is " + plotCount);
        //categoryCount++;//move after each one!
      }
      categoryCount ++;
    }
  }
  
  Map<String, List<String>> getFilter(){
    //gets the filter that this plot would like applied to other plots
    //by default, this is:
    Map toReturn = new HashMap<String, List<String>>();
    List tempList =  new ArrayList<String>();
    //println("Checking filter " + a.xAxis_variable + ": " + a.minValue + ", " + a.maxValue);
    for(String filterWord: wordsToFilter){
      //add all things that map to this
      List<String> wordsThisMapsTo = symptomFilters.get(filterWord);
      tempList.add(filterWord);
      //for(String actualWord: wordsThisMapsTo){
        //tempList.add(actualWord);
        //println("Adding " + actualWord + " to symptom filter");
      //}
      //tempList.add("NEXT");
    }
    if(!tempList.isEmpty())
      toReturn.put(xAxis_variable, tempList);
    return toReturn;
  }
  
  void drawXLabels() {
    //just draw some ticks
    int categoryCount = 0;
    float tx;
    stroke(128);
    strokeWeight(1);
    for(String b:categorisedVersion.keySet()){ 
      tx = map(categoryCount*maxSeries, xmin*maxSeries, xmax*maxSeries, plotX1+2, plotX2);
      line(tx, plotY2, tx, plotY2+4);
      categoryCount ++;
    }  
  }

  void mousePressed() {
    //println("Pressed!");
     if (mouseButton == RIGHT){
       //disable filters on this window
       //need to clear the whole filter too!
       wordsToFilter.clear();
       removeFilter(xAxis_variable); //calls parent object to remove from all plots
       //selection_start = selection_end = -1;
     }
     else if(mouseX> plotX1 && mouseX < plotX2 && mouseY> plotY1 && mouseY<plotY2 && mouseEvent.getClickCount() !=2){
       //are we over a bar?
       int categoryCount = 0;
     
      float barWidth = (plotX2-plotX1) * (float)(1.0f/(xmax*maxSeries));  // width of syndrome bars
      float tx, ty;
      for(String b:categorisedVersion.keySet()){
        tx = map(categoryCount*maxSeries, xmin*maxSeries, xmax*maxSeries, plotX1+2, plotX2);
        ty = mouseX;
        if (mouseX >= tx && mouseX <= (tx+barWidth*maxSeries)) {
          //do selection here!
          //((PlotContentsStringInteger) contents.get(0)).printOutAllMatches(b);
          println("Over " + b + " and clicked!");
          if(wordsToFilter.contains(b)){
            wordsToFilter.remove(b);
            println("Removed " + b);
          }else{
            wordsToFilter.add(b);
            println("Added " + b);
          }
        }
        categoryCount ++;
      }
       
       //selection_start = selection_end = mouseX;
       //isDragging = true;
       //minValue = map(selection_start, plotX1, plotX2, xmin, xmax);
       //maxValue = minValue;
     }
  }
  
  void mouseMoved(){
  }
  
  void drawAxisLabels(){
    if(showPercentages){
      yAxisLabel = yAxisLabel.replaceFirst("Number", "Percentage");
    }else{
      yAxisLabel = yAxisLabel.replaceFirst("Percentage", "Number");
    }
    super.drawAxisLabels();
  }
  
  void mouseDragged(){
   //no dragging since this is category selection
  }
  
  void mouseReleased(){
    //relevant code on Pressed, not released
  }

}
