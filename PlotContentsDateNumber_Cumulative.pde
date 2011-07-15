class PlotContentsDateNumber_Cumulative extends PlotContentsDateNumber {
  
  //float cumulative_total;

  PlotContentsDateNumber_Cumulative(String a) {
    super(a);
    //cumulative_total = 0.0;
  }
  
  void getDataFromThread(){
    super.getDataFromThread();
    //do a loop through to get proper ymax
    //actually put real values in!
    Map<Number, Number> temp = new HashMap<Number,Number>();
    int total = 0;
    //need to loop IN ORDER!
    for(int j = xmin; j <= xmax; j++) {
       if(values.containsKey(j)){
         total += ((Number) values.get(j)).floatValue();
         temp.put(j, total);
         //println("Adding " + j + " and " + total);
       }else{
         temp.put(j, total);
         //println("Adding " + j + " and " + total);
       }
    }
    
    for(int j = xmax; j<=endDate; j++){
      temp.put(j, total);
    }
    ymax = total;
    
    values = temp;
    //println("ymax for cumulative is " + ymax);
  }
  
   void getDataFromCache(String q){
    super.getDataFromCache(q);
    //do a loop through to get proper ymax
    //actually put real values in!
    Map<Number, Number> temp = new HashMap<Number,Number>();
    int total = 0;
    //need to loop IN ORDER!
    for(int j = xmin; j <= xmax; j++) {
       if(values.containsKey(j)){
         total += ((Number) values.get(j)).floatValue();
         temp.put(j, total);
         println("Adding " + j + " and " + total);
       }else{
         temp.put(j, total);
       }
    }
    for(int j = xmax; j<=endDate; j++){
      temp.put(j, total);
    }
    ymax = total;
    
    values = temp;
    //println("ymax for cumulative is " + ymax);
  }

}

