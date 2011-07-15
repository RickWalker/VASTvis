class GenericPlotStats extends GenericPlot{
  
  GenericPlot plotToUse; //pull stats data from this plot object to draw
  //List <DescriptiveStatistics> statsToDraw; //all data from these plots, so can draw directly  
  
  GenericPlotStats(PApplet parent, String xv, String yv, String xl, String yl){
    super(parent, xv, yv, xl, yl);
  }
  
  void setPlotToUse(MoveableComponent a){
    //how can I tell if this is the map?
    if(a.getReference()!=null){ //ARGH, hack to find out if this is a plot or not
      plotToUse = (GenericPlot) a;
      //println("Setting plot to " + ((GenericPlot) a).xAxis_variable);
      refresh();
    }
  }

  
  void refresh(){
    if(plotToUse != null){

      /*if(!plotToUse.contents.isEmpty()){
        PlotContents temptemp = plotToUse.contents.get(0);
      //use the array of DescriptiveStatistics to draw box plots
        symptomsTopTenList.setText("Mean:   " + temptemp.convertForDisplay(temptemp.mean));
        symptomsTopTenList.setText(symptomsTopTenList.text() + "\nMedian:   " + temptemp.convertForDisplay(temptemp.median));
        symptomsTopTenList.setText(symptomsTopTenList.text() + "\nSD:       " + nfp(temptemp.sd,2,2));
        symptomsTopTenList.setText(symptomsTopTenList.text() + "\nSkew:     " + nfp(temptemp.skewness,2,2));
        symptomsTopTenList.setText(symptomsTopTenList.text() + "\nKurtosis: " + nfp(temptemp.kurtosis,2,2));
        symptomsTopTenList.setText(symptomsTopTenList.text() + "\nQ1: " + temptemp.convertForDisplay(temptemp.q1));
        symptomsTopTenList.setText(symptomsTopTenList.text() + "\nQ3: " + temptemp.convertForDisplay(temptemp.q3));
      }*/
      
      xmin = ymin = Integer.MAX_VALUE;
      xmax = ymax = Integer.MIN_VALUE;
   
      xmin = 0;
      
      xmax = plotToUse.contents.size(); 
      //println("xmax is " + xmax);
    
      //loop over PlotContents
      PlotContents a;
      for(int i = 0; i< plotToUse.contents.size(); i++) {
        a = plotToUse.contents.get(i);
        //need to call update to get xmin and xmax?
        //nb x becomes Y for this plot!
        //println("Looking at " + a.city);
        //println("min of " + ymin +" and " + a.getMinX());
        ymin = min(ymin, a.getMinX());
        ymax = max(ymax, a.getMaxX());
      }
      /*if(normalise) {
        ymin = 0;
        ymax = 1;
      }*/ //don't normalise box plots!
    }
  }
  
  
  
  void drawDateYLabels() {
    //do it based on logs!
    int yLineInterval = 10;
    long multiplierToLong = 86400000;

    Calendar current = Calendar.getInstance();
    Calendar next = Calendar.getInstance();

    float monthStart, monthEnd; //centre the month in the space available
    monthStart = plotY2;
    int dayOfMonth=0;
    float y =0 ;
    strokeWeight(1);
    
    textSize(width/55);
    textAlign(RIGHT, CENTER);
    Date firstDate = new Date(ymin * multiplierToLong);
    //println("First date is " + firstDate + " and last is " + new Date(xmax * multiplierToLong));
    stroke(224);
    for (int row = ymin; row <= ymax; row++) {
      y = map(row, ymin, ymax, plotY2, plotY1);
  
      current.setTime(new Date(row * multiplierToLong));
      next.setTime(new Date(((row+1) * multiplierToLong))); //next day!
      //stupid rounding errors still - eventually fix with eg Joda
      dayOfMonth = current.get(Calendar.DAY_OF_MONTH);
      if ((dayOfMonth == 9 || dayOfMonth==19) && (dayOfMonth != next.get(Calendar.DAY_OF_MONTH))) {
        //fill(128);
        fill(0);
        text(next.get(Calendar.DAY_OF_MONTH), plotX1, y);
        stroke(224);
        line(plotX1, y, plotX2, y);
      }
  
      if(current.get(Calendar.MONTH) != next.get(Calendar.MONTH)) {
        stroke(224);
        line(plotX1, y, plotX2, y);
        //end of month mark
        monthEnd = y;
        fill(0);
        text(getMonthFromInt(current.get(Calendar.MONTH)), plotX1 - textWidth(" 31"), (monthStart + monthEnd)/2);
        stroke(0);
        line(plotX1, y, plotX1 - 2 * textWidth("31"), y);
        monthStart = y;
      }
    }
  
    //last month hack:
    if(dayOfMonth > 20) {
      monthEnd = y;
      text(getMonthFromInt(current.get(Calendar.MONTH)), plotX1 - textWidth(" 31"), (monthStart + monthEnd)/2);
    }
  }

  
  void draw(){
    if(visible){
      updateIntegrators();
      fill(255);
      rectMode(CORNERS);
      noStroke();
      rect(plotX1, plotY1, plotX2, plotY2);
      drawTitleTabs();
      
      //one box for each country
      int boxWidth = int((plotX2 - plotX1)/xmax);
      float ty, ty2, tx;
      int countryCount = 0;
      //fill(255,0,0);
      //println(ymin + " " + ymax);
  
  
      if(plotToUse != null){
        if(plotToUse.xAxis_variable.startsWith("DATE")){
          drawDateYLabels();
        }
        else{
          drawYLabels();
        }
        noFill();
        for(PlotContents a: plotToUse.contents){
          if (a.values != null){
          stroke(a.col);
          strokeWeight(2);
          //draw box
          ty = map(a.q1, ymin, ymax, plotY2, plotY1);
          ty2 = map(a.q3, ymin, ymax, plotY2, plotY1);
        
          tx = map(countryCount, xmin, xmax, plotX1, plotX2);
          //println("Drawing: " + tx + " and " + ty + " and " + ty2);
          noFill();
          rect(tx + 0.1*boxWidth, ty, tx + boxWidth - 0.1*boxWidth, ty2);
          //text alongside
          textAlign(LEFT, BOTTOM);
          stroke(a.col);
          fill(a.col);
          //println("Q3 is " + a.q3);
          //println("Deaths on q3 is " + a.get(int(a.q3)));
         //println("Deaths on median is " + a.get(a.median));
         textSize(width/(70));
          text((a.normalise(a.get(int(a.q3))) - a.normalise(a.get(int(a.median))))/(a.q3 - a.median),  tx + 0.6*boxWidth, map(a.q3, ymin, ymax, plotY2, plotY1));
          
          //draw median
          strokeWeight(1);
          ty = map(a.median, ymin, ymax, plotY2, plotY1);
          line(tx + 0.1*boxWidth, ty, tx + boxWidth  - 0.1*boxWidth, ty);
          
          //draw a cross for the mean
          ty = map(a.mean, ymin, ymax, plotY2, plotY1);
          //cross here!
          translate(boxWidth/2, 0);
          line(tx+3, ty+3, tx-3, ty-3);
          line(tx-3, ty+3, tx+3, ty-3);
          translate(-boxWidth/2, 0);
          
          //draw whiskers - up to any point within 3/2 of interquartile range of q1 or q3
          //line(tx + 0.5*boxWidth, map(a.q3, ymin, ymax, plotY2, plotY1), tx + 0.5*boxWidth,  map(a.whiskerTop, ymin, ymax, plotY2, plotY1));
          //line(tx + 0.5*boxWidth, map(a.q1, ymin, ymax, plotY2, plotY1), tx + 0.5*boxWidth,  map(a.whiskerBottom, ymin, ymax, plotY2, plotY1));
  //stroke(255,0,0);
  //strokeWeight(10);
          line(tx + 0.5*boxWidth, map(a.q1, ymin, ymax, plotY2, plotY1), tx + 0.5*boxWidth,  map(a.tenthpercentile, ymin, ymax, plotY2, plotY1));
          line(tx + 0.5*boxWidth, map(a.q3, ymin, ymax, plotY2, plotY1), tx + 0.5*boxWidth,  map(a.ninetiethpercentile, ymin, ymax, plotY2, plotY1));
          strokeWeight(5);
          point(tx + 0.5*boxWidth,  map(a.tenthpercentile, ymin, ymax, plotY2, plotY1));
          point(tx + 0.5*boxWidth,  map(a.ninetiethpercentile, ymin, ymax, plotY2, plotY1));
          //println("Percentiles are " + a.tenthpercentile + " and " + a.ninetiethpercentile);
          //go through points 
          countryCount ++;
          }
        }
      }
      drawDataHighlight();
    }
  }
  
  void drawDataHighlight(){
    int boxWidth = int((plotX2 - plotX1)/xmax);
    int countryCount = 0;
    float top, bottom, left;
    if(plotToUse == null) return;
    for(PlotContents a:  plotToUse.contents){
       bottom = map(a.q1, ymin, ymax, plotY2, plotY1);
       top = map(a.q3, ymin, ymax, plotY2, plotY1);
       left = map(countryCount, xmin, xmax, plotX1, plotX2) + 0.1*boxWidth;
      if (mouseX > left && mouseX < (left + boxWidth - 0.1*boxWidth)){
        //println("over x");
        //println(mouseY + " and " + top + " and " + bottom);
        if(mouseY> top && mouseY < bottom){
          //println("Mouseover!");
          fill(255);
          stroke(0);
          strokeWeight(2);
          //show stats in here
          String toShow = "Mean:   " + a.convertForDisplay(a.mean) + 
          "\nMedian:   " + a.convertForDisplay(a.median) + 
          "\nSD:       " + nfp(a.sd, 2, 2) + 
          "\nSkew:     " + nfp(a.skewness, 2, 2) +
          "\nKurtosis: " + nfp(a.kurtosis, 2, 2) + 
          "\nQ1: " + a.convertForDisplay(a.q1) + 
          "\nQ3: " + a.convertForDisplay(a.q3);//+
          //"\nIQR: " + nfp(a.q3 - a.q1,1,0);
          textSize(width/70);
          rectMode(CORNER);
          rect(mouseX-10, mouseY-10, textWidth(toShow)+20, 9*(textAscent() + textDescent())+20);
          textAlign(LEFT, TOP);
          fill(a.col);
          text(toShow, mouseX, mouseY);
        }else if(dist(mouseX, mouseY, left+boxWidth/2 - 0.1*boxWidth, map(a.ninetiethpercentile, ymin, ymax, plotY2, plotY1))<5.0){
          //println("over point!");
          strokeWeight(10);
          stroke(a.col);
          point(left+boxWidth/2 - 0.1*boxWidth, map(a.ninetiethpercentile, ymin, ymax, plotY2, plotY1));
          stroke(0);
          textAlign(LEFT, BOTTOM);
          text(a.convertForDisplay(a.ninetiethpercentile) + "\n" + int(a.ninetiethpercentile - a.median) + " days from median",left+boxWidth/2 - 0.1*boxWidth, map(a.ninetiethpercentile, ymin, ymax, plotY2, plotY1));
          
        }else if(dist(mouseX, mouseY, left+boxWidth/2 - 0.1*boxWidth, map(a.tenthpercentile, ymin, ymax, plotY2, plotY1))<5.0){
          strokeWeight(10);
          stroke(a.col);
          point(left+boxWidth/2 - 0.1*boxWidth, map(a.tenthpercentile, ymin, ymax, plotY2, plotY1));
          stroke(0);
          textAlign(LEFT, TOP);
          text(a.convertForDisplay(a.tenthpercentile)+ "\n" + int(a.median - a.tenthpercentile) + " days from median",left+boxWidth/2 - 0.1*boxWidth + 10 , map(a.tenthpercentile, ymin, ymax, plotY2, plotY1) + 10); 
        }
        /*}else{
          println(dist(mouseX, mouseY, left+boxWidth/2, map(a.ninetiethpercentile, ymin, ymax, plotY2, plotY1)));
        }*/
      }
      countryCount++;
    }
  }
}
