import com.healthmarketscience.*;

class GenericPlotNumber extends GenericPlot implements MoveableComponent {

  int selection_start, selection_end;
  boolean isDragging = false;

  //float minValue, maxValue; // these are used to form the filter

  GenericPlotNumber(PApplet parent, String xv, String yv, String xl, String yl) {
    super(parent, xv, yv, xl, yl);

    minValue = maxValue = -1; //-1 means no selection!
  }
  
  void drawFilter(){
     //draw filter!
    fill(128,128,128,128);

    if (isDragging){
        rect(selection_start, plotY1, selection_end, plotY2);
    }else if (!isDragging && minValue > -1 ) { //if not still dragging and we've got something to draw!
      rect( minValue < xmin ? plotX1:map(minValue, xmin, xmax, plotX1, plotX2), plotY1, maxValue > xmax ? plotX2:map(maxValue, xmin, xmax, plotX1, plotX2), plotY2); //eventually use min and max value, because they'll be consistent as plot size changes
      //println("Drawing filter " + minValue + " " + maxValue);
    }
  }

  void refresh() {
    super.refresh();
   
    if(filters.get(xAxis_variable)!=null) {
      //println("Need to look up new filter!");
      maxValue = contents.get(0).convertValueFromDatabaseFormat(filters.get(xAxis_variable).get(0));
      minValue = contents.get(0).convertValueFromDatabaseFormat(filters.get(xAxis_variable).get(1));
      //println("min and max are now " + minValue + ", " + maxValue);
    }else{
      minValue = maxValue = -1; //-1 means no selection!
    }
    //draw();
  }

  void mousePressed() {
    //println("Pressed!");
    if (mouseButton == RIGHT) {
      minValue = maxValue = -1; //disable filters on this window
      //need to clear the whole filter too!
      removeFilter(xAxis_variable); //calls parent object to remove from all plots
      selection_start = selection_end = -1;
    }
    else if(mouseX> plotX1 && mouseX < plotX2 && mouseY> plotY1 && mouseY<plotY2) {
      selection_start = selection_end = mouseX;
      isDragging = true;
      //minValue = map(selection_start, plotX1, plotX2, xmin, xmax);
      //maxValue = minValue;
    }
  }

  void mouseMoved() {
  }

  void mouseDragged() {
    //println("Dragged!");
    if(mouseButton == LEFT && (mouseX> plotX1 && mouseX < plotX2 && mouseY> plotY1 && mouseY<plotY2)) {
      selection_end = mouseX;
      //maxValue = map(selection_end, plotX1, plotX2, xmin, xmax);
      //redraw only the bits that need it!
      // Show the plot area as a white box  
      fill(255);
      rectMode(CORNERS);
      noStroke();
      rect(plotX1, plotY1, plotX2, plotY2);

      //draw filter!
      fill(128,128,128,128);
      rect(selection_start, plotY1, selection_end, plotY2); //eventually use min and max value, because they'll be consistent as plot size changes

      drawData();
    }
  }

  void mouseReleased() {
    //println("Released");
    if(mouseButton == LEFT && (mouseX> plotX1 && mouseX < plotX2 && mouseY> plotY1 && mouseY<plotY2)) {
      selection_end = mouseX;
      //println("Selection is " + selection_start + " to " + selection_end);
      if(selection_end>plotX1 && selection_end<plotX2 && selection_start>plotX1 && selection_end<plotX2 && selection_start != selection_end) {
        removeFilter(xAxis_variable); //calls parent object to remove from all *other* plots
        //refreshFilters();
        minValue = min(map(selection_start, plotX1, plotX2, xmin, xmax),  map(selection_end, plotX1, plotX2, xmin, xmax) );
        maxValue = max(map(selection_start, plotX1, plotX2, xmin, xmax),  map(selection_end, plotX1, plotX2, xmin, xmax) );
        refreshFilters();
        //now add this one - will get picked up on refresh 
        println("So whole filter is " + xAxis_variable + " between " +  minValue + " and " + maxValue);
      }
      //selection_end = -1;//flag for main draw to use min/max again
      isDragging = false;
    }
  }
}

