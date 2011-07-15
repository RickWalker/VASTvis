import org.apache.commons.math.*;

class PlotContentsDateNumber extends PlotContentsNumberNumber {
  
  DescriptiveStatistics stats;
  DateFormat toShow = new SimpleDateFormat("dd MMM");// yyyy");

  PlotContentsDateNumber(String a) {
    super(a);
    stats = new DescriptiveStatistics();
  }

  void update(String query, String xv, String yv) {
      super.update(query, xv, yv);
      xmin = startDate;
      xmax = endDate;
  }

  String convertValueToDatabaseFormat(float v) {
    //converts plot value into the format it came out of the database in
    long multiplierToLong = 86400000;
    Date actualDate = new Date((long) (Math.round(v+1) * multiplierToLong)); //+1 because of stupid date rounding errors - fix with Joda eventually
    return toMilli.format(actualDate);
  }
  
  float convertValueFromDatabaseFormat(String s){
    long multiplierToLong = 86400000;
    Date keyDate = new Date();
    try {
      keyDate = toMilli.parse(s);
    }
    catch (ParseException e) {
      println("Can't parse date " + s);
    }
    
    return keyDate.getTime()/multiplierToLong;
  }
  
  String convertForDisplay(float value){
    long multiplierToLong = 86400000;
    Date actualDate = new Date(int(value+1) * multiplierToLong);
    return toShow.format(actualDate);
  }
      
  void updateStats(){
    super.updateStats();
    //work out whiskers!
    float interquartileRange = q3-q1;
    float threeovertwoiqr = 3.0/2.0 * interquartileRange;
    whiskerTop = Float.MIN_VALUE;
    whiskerBottom = Float.MAX_VALUE;
    float value;
    for(int j = xmin; j <= xmax; j++) {
      value = get(j); 
      if(value > q3){
        if((value - threeovertwoiqr) <=q3){
          //within range
          whiskerTop = max(whiskerTop, value);
        }
      }else if(value < q1){
        if((value + threeovertwoiqr)>=q1){
          whiskerBottom = min(whiskerBottom,value);
        }
      }
    }
    if(whiskerTop == Float.MIN_VALUE){
      whiskerTop = q3;
    }
    if(whiskerBottom == Float.MAX_VALUE){
      whiskerBottom = q1;
    }
  }
}

