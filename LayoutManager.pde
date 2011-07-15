class LayoutManager {
  class Position {
    int x, y, width, height;
    Position(int x, int y, int width, int height) {
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }

    String toString() {
      return x + ", " + y + " and " + width + ", " + height;
    }
  }
  int width, height;
  Stack <Position> componentPositions;
  Position large;
  Position statsPlot;
  GenericPlotStats statsPlotObject;

  LayoutManager(int w, int h) {
    componentPositions = new Stack<Position>();
    width = w;
    height = h;
    int across = 4;
    int down = 4;
    int padding = 5;
    for(int i = 1; i<down; i++) {
      componentPositions.add(new Position(padding, i*h/down + padding, w/across - 2*padding, h/down - 2*padding));
    }
    //generate 5 across positions
    for(int i = across-1; i>=0; i--) {
      componentPositions.add(new Position(i*w/across + padding, padding, w/across-2*padding, h/down - 2*padding));
    }
    large = new Position(w/across, h/down, int((across-1)/float(across) * w), int((down-2)/float(down) * h));
    statsPlot = new Position((across-2)* w/across, (down-1) * h/down,  2*w/across-2*padding, h/down - 2*padding); //no size for now!
  }

  void addComponent(GenericPlot a) {
    //hack for statsPlot:
    if(a.xAxis_variable.equals("STATS")){
      println("Adding stats!");
      a.moveTo(statsPlot.x, statsPlot.y, statsPlot.width, statsPlot.height);
      plotList.add(a);
      statsPlotObject = (GenericPlotStats) a; //hack hack hack! eventually overload method
      return;
    }
    //work out what its position should be: next item in queue!
    //only called for initial placement, so no animation
    Position toUse = componentPositions.pop();
    a.moveTo(toUse.x, toUse.y, toUse.width, toUse.height);
   // println("Setting to " + toUse);
    plotList.add(a);
  }
  
  void addMap(svgMapInterface a){
    Position toUse = componentPositions.pop();
    a.moveTo(toUse.x, toUse.y, toUse.width, toUse.height);
  }

  void doubleClick(MoveableComponent a) {
    Position toUse;// = new Position(0,0,0,0);
    if(a.getWidthTarget() == large.width) {
      //make small!
      toUse = componentPositions.pop();
    }else{
      //make large and maybe make other things small!
      //toUse = large;
      //componentPositions.add(new Position(a.x, a.y, a.width, a.height));

      for(GenericPlot b: plotList){
        if(theMap.getWidthTarget() == large.width){
          toUse = componentPositions.pop();
          theMap.moveTo(toUse.x, toUse.y, toUse.width, toUse.height);
        }
        
        if(b.getWidthTarget() == large.width) {
          //this is currently large: make it small
          toUse = componentPositions.pop();
          b.moveTo(toUse.x, toUse.y, toUse.width, toUse.height);
          break;
        }
      }
      toUse = large;
      componentPositions.push(new Position(a.getX(), a.getY(), a.getWidth(), a.getHeight()));
      //set statsPlot to use this one
      if(!a.equals(statsPlotObject) && a.getReference()!=null)
      {
        statsPlotObject.setPlotToUse(a);
        //println("Setting plot to " + ((GenericPlot) a).xAxis_variable);
      }
    }
    a.moveTo(toUse.x, toUse.y, toUse.width, toUse.height);
  }
  
  MoveableComponent getLargeComponent(){
    if(theMap.getWidthTarget() == large.width) return theMap;
    if(statsPlotObject.getWidthTarget() == large.width) return statsPlotObject;
    for(GenericPlot b: plotList){
      if(b.getWidthTarget() == large.width) return b;
    }
    return null; //only hits here if all are small
  }
  
  void hideAllButLarge(){
    println(getLargeComponent());
    for(GenericPlot a: plotList){
      if(getLargeComponent() == a || a.getWidthTarget() == width){
        //componentPositions.push(new Position(a.getX(), a.getY(), a.getWidth(), a.getHeight()));
        a.moveTo(100, 0, width, height);
      }else{
        a.visible = false;
        
        //componentPositions.push(new Position(a.getX(), a.getY(), a.getWidth(), a.getHeight()));
        //a.moveTo(-500, -500, 30, 30);
        
      }
    }
     
    /*if(getLargeComponent() == statsPlotObject){
      statsPlotObject.moveTo(10, 0, width, height);
    }else{
      statsPlotObject.visible = false;
    }*/
    
    if (getLargeComponent() == theMap){
      theMap.moveTo(10, 0, width, height);
    }else{
      theMap.visible = false;
    }    
  }
  
  void restoreAll(){
    theMap.visible = true;
    if(theMap.getWidthTarget() == width){
      theMap.moveTo(large.x, large.y, large.width, large.height);
    }
    
    statsPlotObject.visible = true;
    if(statsPlotObject.getWidthTarget() == width){
      statsPlotObject.moveTo(large.x, large.y, large.width, large.height);
    }
    
    for(GenericPlot a: plotList){
      if(a.getWidthTarget() == width){
        a.moveTo(large.x, large.y, large.width, large.height);
      }
      a.visible = true;
    }
    
  }
    
}

